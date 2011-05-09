require 'andand'

class Address < Array
end

module Contactable
  attr_accessor :address, :phone, :email
end

class Person
  include Contactable
  attr_accessor :last, :first, :sex, :birthday, :age
  def initialize(last, first, other={})
    (@last, @first) = last, first
    other.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end

  def ==(other)
    if last == other.last && first == other.first
      return false if sex != other.sex
      if first
      else
        false
      end
    end
  end
end

class Household
  include Contactable
  # a list of the heads of household
  attr_accessor :heads_of_household
  # list of all individuals in the house (including heads_of_household)
  attr_accessor :individuals

  # this should always match the first heads_of_household
  attr_accessor :name

  def initialize(name, other={})
    @name = name
    other.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end
end

module Unit
  attr_accessor :name, :unit_id
  def initialize(name, unit_id)
    (@name, @unit_id) = name, unit_id
  end
end

class Ward
  include Unit
end

class Stake
  include Unit
end

class Assignment
  # Elders or something else
  attr_accessor :organization
  attr_accessor :teachers
  attr_accessor :households
  attr_accessor :month
  attr_accessor :district_supervisor

  def initialize(teachers, households, district_supervisor, organization=nil, month=nil)
    (@organization, @teachers, @households, @district_supervisor, @month) = organization, teachers, households, district_supervisor, month 
  end

  # returns assignments
  def self.create_assignments(assignments_pdf)
    (assignments, ward, assignment_type, stake, organization, district) = Parser.new.parse(assignments_pdf)
    assignments
  end

  ## updates the contact info for heads of household if they are also teachers
  ## if update_supervisor, then the supervisor is updated to the teacher
  ## individual identities are merged where possible
  #def self.update_contact_info(assignments, update_supervisor=true)
  #  
  #end
end

class Assignment::Parser
  StartRange = Struct.new(:teachers, :households, :given, :sex, :birth, :age) 
  Unit_re = %r{([\w\s]+) \((\d+\))}
  Assignment_type_re = %r{(.*) Assignments}

  # returns [assignments, ward, assignment_type, stake, organization,
  # district]
  def parse(pdf_file, month=nil)
    @month = month
    text_file = convert_to_text(pdf_file)
    File.open(text_file) do |io|
      (ward, assignment_type) = parse_ward_and_assignment_type(io.gets)
      stake = Stake.new(*(io.gets.chomp.match(Unit_re)[1,2]))
      (organization, district) = io.gets.match(/Organization: (.*?) \/ District: (.*)/)[1,2]
      assignments = parse_assignments(io)
      [assignments, ward, assignment_type, stake, organization, district]
    end
  end

  # returns assignments or returns nil if none (indicating end of file) should
  # be at the beginning of the assignment
  def parse_assignments(io)
    @supervisor_triple_to_person = Hash.new {|h,k| h[k] = Person.new(k[0], k[1], :phone => k[2]) }
    assignments = []
    while assignment = parse_assignment(io)
      assignments << assignment
    end
    assignments
  end

  # returns a StartIndex struct giving a range for that field based on the
  # header position
  def get_ranges_from_header_line(line)
    line.chomp!
    indices = %w(Teachers Households Given Sex Birth Age).map {|key| line.index(key) }
    ranges = [[0, indices[1]-16], 
      [indices[1]-15, indices[2]-6], 
      [indices[2]-5, indices[3]-2], 
      [indices[3], indices[3]+4], 
      [indices[3]+5, indices[5]-1], 
      [indices[5], line.size]].map {|pair| Range.new(*pair) }
    StartRange.new(*ranges)
  end

  # returns lines with teachers and households, chomped and removes trailing
  # lines with no data.  households is an array of arrays
  def split_teachers_and_households(io, ranges)
    teacher_lines = [] ; household_ars = []
    while line = io.gets 
      break if ((line =~ /For Church Use Only/) || (line !~ /\w/))
      teacher_lines << line[ranges.teachers]
      household_ars << [:households, :given, :sex, :birth, :age].map {|k| line[ranges[k]].andand.chomp }
    end
    # trim the teacher lines for white space at the end
    tlr = teacher_lines.reverse
    found_data = false
    tlr.select! do |line|
      if !found_data && line =~ /\w/
        found_data = true
      end
      found_data
    end
    tlr.map!(&:chomp)
    [tlr.reverse, household_ars]
  end

  # returns [last, first, phone, email, address_lines]
  def parse_person_and_contact(lines)
    (last, first) = lines.shift.split(', ')
    found_phone_number = false
    (phone_etc, address) = lines.partition do |line| 
      if !found_phone_number && line !~ /[^\d \-]/
        found_phone_number = true
      end
      found_phone_number
    end
    (email_addresses, phone_nums) = phone_etc.partition do |line|
      line.include?('@')
    end
    #if last == 'Hedengren'
    #  puts "CHECKING: EMAIL: #{email_addresses.first} PHONE: #{phone_nums.first}, LAST: #{last}, ADDRESS: #{address.inspect}"
    #end

    [last, first, phone_nums.first, email_addresses.first, address]
  end

  # takes lines that only include the portion with teachers information
  # returns an array of teachers
  def parse_teacher_lines(teacher_lines)
    tlines = []
    teacher_lines.each do |line|
      if line[0,1] != ' '
        tlines << [line.strip]
      else
        tlines.last << line.strip
      end
    end
    tlines.map do |lines|
      (last, first, phone, email, address) = parse_person_and_contact(lines)
      Person.new(last, first, :phone => phone, :email => email, :address => Address.new( address ))
    end
  end

  # returns Household objects
  def parse_household_lines(household_ars)
    # split data into different households
    hars= []
    start_index = household_ars.first.first.index(/[^ ]/)
    household_ars.each do |array|
      if array.first && (array.first[start_index,1] =~ /\w/)
        hars << [array]
      else
        hars.last << array
      end
    end
    households = hars.map do |ar| 
      hlines = ar.map(&:shift).compact.map(&:strip)
      (household_name, _, phone, email, address) = parse_person_and_contact(hlines)
      Household.new(household_name, :phone => phone, :email => email, :address => Address.new(address))
    end
    head_of_house_index = hars.first.first.index(/[^ ]/)
    hars.map! do |indiv_data_ars|
      individual_rows = []
      indiv_data_ars.each do |ar|
        next unless ar.compact.size > 0
        if ar[1] =~ /\w/  # a person has a sex
          individual_rows << ar
        else
          individual_rows[-1][0] << " #{ar[0].strip}"
        end
      end
      individual_rows
    end

    households.zip(hars) do |household, individual_rows|
      heads_of_household = []
      hofhouse_i = individual_rows.first.first.index(/[^ ]/)
      household.individuals = individual_rows.map do |ar|
        is_head_of_household = (ar[0][hofhouse_i,1] != ' ')
        names = 
          if ar[0].include?(',')
            ar[0].split(', ')
          else
            [household.name, ar[0]]
          end
        names.map! {|name| name.strip.gsub(/\s+/,' ') }
        (last, first) = names
        ar.map! {|v| v.strip if v }
        #puts "LAST: #{last} FIRST: #{first} HOH: #{is_head_of_household}"
        # Date.strptime(ar[2], "%2d %3m %4y")
        person = Person.new(last, first, :sex => ar[1], :birthday => ar[2], :age => (ar[3] && ar[3].to_i))
        heads_of_household << person
        person
      end
      household.heads_of_household = heads_of_household
    end
    households
  end

  # returns a teaching assignment if one exists
  def parse_assignment(io)
    is_an_assignment = false
    while line = io.gets
      # the leading space is important because it distinguishes from
      # ^Organization line
      if line =~ / Organization/
        is_an_assignment = true
        break
      end
    end
    if is_an_assignment
      (org, sv) = parse_organization_and_supervisor(line)
      ranges = get_ranges_from_header_line(io.gets)
      (teacher_lines, household_ars) = split_teachers_and_households(io, ranges)
      teachers = parse_teacher_lines(teacher_lines)
      households = parse_household_lines(household_ars)
      key = [:last, :first, :phone].map {|k| sv.send(k) }
      Assignment.new(teachers, households, @supervisor_triple_to_person[key], org, @month )
    end
  end

  def parse_organization_and_supervisor(line)
    (org, supervisor) = line.split('District').map(&:strip).map {|v| v.split(': ',2).last }
    (name, phone) = supervisor.split(' (')
    (last, first) = name.split(', ')
    phone &&= phone.chomp[0...-1]
    [org, Person.new(last, first, :phone => phone)]
  end

  def parse_ward_and_assignment_type(line)
    (ward_text, assignment_text) = line.split(' - ')
    if md = ward_text.match(Unit_re)
      ward = Ward.new(md[1], md[2])
    else
      raise 'bad parse of ward line'
    end
    assignment_type = assignment_text.match(Assignment_type_re)[1]
    [ward, assignment_type]
  end

  def convert_to_text(pdf)
    text_file = pdf.sub(/\.pdf$/i, '.txt')
    system "pdftotext", "-layout", pdf
    unless File.exist?(text_file)
      raise 'Error converting pdf to text!  [You may not have pdftotext installed missing write access]'
    end
    text_file
  end

end

