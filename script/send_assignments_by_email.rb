#!/usr/bin/env ruby

require 'trollop'
require 'home_teaching_assignments'

class String
  def pluralize
    if self[-1,1] == 's'
      self
    else
      self + "s"
    end
  end
end

# returns the last name of the family if >= 3 folks, or the names of both
# people if 2, and just the 1 if one
def family_appelation(household)
  case hs=household.individuals.size
  when 1
    ind=household.individuals.first
    "#{ind.just_first} #{ind.last}"
  when 2
    if household.individuals.map(&:last).uniq.size == 1
      household.individuals.map {|ind| ind.just_first }.join(" and ") + ' ' + household.individuals.first.last
    else
      household.individuals.map(&:casual_full_name).join(" and ")
    end
  else # 3 or more
    "the #{household.name.pluralize}"
  end
end

class Array
  def list
    case self.size
    when 1
      self.first
    when 2
      self.join(" and ")
    else
      "#{self[0..-2].join(", ")}, and #{self[-1]}"
    end
  end
end

def household_lines(household)
  h = household
  lines = [] 
  lines << h.name
  lines.push(*h.address)
  lines << h.phone
  lines << h.email
  lines << ''
  lines.compact
  ind_lines = h.individuals.map do |ind|
    individual_lines(ind, h.heads_of_household.include?(ind))
  end
  ind_lines.each do |lns|
    lines.push(*lns)
  end
  lines.compact
end

def teacher_lines(teacher)
  t = teacher
  lines = []
  lines << t.full_name
  lines.push(*t.address)
  lines << t.phone
  lines << t.email
  lines.compact
end

def individual_lines(person, head_of_household=false)
  name_line = [person.first, person.last].join(' ')
  if head_of_household
    name_line << " (head of household)"
  end
  [name_line, [person.sex, person.birthday, person.age ? "#{person.age} yrs old" : nil].compact.join(', ') ]
end

def text_body(teacher, companion, households, month)
delimit = "-"*40
%Q{Hi #{teacher.just_first},

I hope things are going well for you.  We apologize for getting your assignment to you late this month.  Expect your assignment the first day of the month in the future.  

You have been assigned to home teach #{households.map {|hh| family_appelation(hh) }.list} for #{month}.  Your companion is #{companion.casual_full_name}. Please contact a member of the EQ presidency with any questions.

Companion contact info:
#{delimit}
#{teacher_lines(companion).join("\n")}

Contact information for your families:
#{households.map {|hh| delimit + "\n" + household_lines(hh).join("\n")}.join("\n") }
#{delimit}

Thanks,
John Prince

cell: 801-636-4847
jtprince@gmail.com

}
end



parser = Trollop::Parser.new do
  banner "usage: #{File.basename(__FILE__)} <file>.pdf"
  opt :email_list, "override emails with returnandreport Home Teacher List (the table copy and pasted into a file)", :type => :string
end

opt = parser.parse(ARGV)

if ARGV.size == 0
  parser.educate && exit
end

pdf = ARGV.shift

if opt[:email_list]
  lines = IO.readlines(opt[:email_list])
  lines.shift if lines.first =~ /Home Teacher/
  home_teachers_from_email_list = lines.map do |line|
    pieces = line.split("\t")
    name = pieces.shift
    (last, first) = name.split(", ")
    email = pieces.shift
    Person.new(last, first, :email => email)
  end
  casual_full_name_to_email = {}
  home_teachers_from_email_list.each do |teacher|
    casual_full_name_to_email[teacher.casual_full_name] = teacher.email
  end
end

assignments = Assignment.create_assignments(pdf)
if home_teachers_from_email_list
  assignments.each do |assignment|
    assignment.teachers.each do |teacher|
      if (email = casual_full_name_to_email[teacher.casual_full_name]) && email != '' && !email.nil?
        teacher.email = email
      end
    end
  end
end
assignments.group_by(&:district_supervisor).each do |supervisor, assignments|
  supervisor
  assignments.each do |asgn|
    teachers = asgn.teachers
    teachers.each do |teacher|
      companion = teachers.dup.delete(teacher) && teachers.first
      puts "*******************************************************************"
      puts teacher.email_with_name
      puts "*******************************************************************"
      puts text_body(teacher, companion, asgn.households, Time.now.strftime("%B"))
    end
  end
end
