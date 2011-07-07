require 'andand'
require 'set'

require 'home_teach/assignment/parser'

module HomeTeach
  class Assignment
    # Elders or something else
    attr_accessor :organization
    attr_accessor :teachers
    attr_accessor :households
    attr_accessor :month
    attr_accessor :district_supervisor
    # the actual text of the assignment (fixed width font formatted)
    attr_accessor :text

    def initialize(teachers, households, district_supervisor, text, organization=nil, month=nil)
      (@organization, @teachers, @households, @district_supervisor, @month, @text) = organization, teachers, households, district_supervisor, month, text 
    end

    # merges supervisors, teachers and heads of household.  Takes the individual data
    # over household data.  Uses names and address for merging, so fathers and
    # sons in the same house and with the same name may get clobbered.
    # Supervisor merged by phone number.
    def self.merge!(assignments)
      teachers = assignments.map {|assignment| assignment.teachers }.flatten(1)
      heads_of_household = assignments.map do |assignment| 
        assignment.households.map do |household| 
          household.heads_of_household.each do |head|
            [:address, :phone, :email].each {|key| head.send("#{key}=", household.send(key)) }
          end
          household.heads_of_household
        end
      end.flatten(2)
      adults = teachers + heads_of_household
      by_email = adults.group_by {|p| [p.first, p.last, p.email] }
      by_address = adults.group_by {|p| [p.first, p.last, p.address] }
      by_phone = adults.group_by {|p| [p.first, p.last, p.phone] }
    end

    # ########################################## ==> This is not yet working
    # properly!!!!
    def self.remove_duplicates!(assignments)
      teacher_sets = Set.new
      assignments.select do |assgn|
        if teacher_sets.include?( Set.new(assgn.teachers) )
          false
        else
          teacher_sets << Set.new(assgn.teachers)
          true
        end
      end
    end

    # returns assignments.  Takes an assignments pdf file, or the file created
    # with pdftotext.
    #
    #     :merge => true|false  will merge data and people into single people
    #     :remove_duplicates => true|false  removes duplicate entries
    def self.create(assignments_file, opts={})
      opts = {:merge => true, :remove_duplicates => true }.merge(opts)
      (assignments, ward, assignment_type, stake, organization, district) = Parser.new.parse(assignments_file)
      self.remove_duplicates!(assignments)
      if opts[:merge]
        self.merge!(assignments) 
      end
      assignments
    end

    ## updates the contact info for heads of household if they are also teachers
    ## if update_supervisor, then the supervisor is updated to the teacher
    ## individual identities are merged where possible
    #def self.update_contact_info(assignments, update_supervisor=true)
    #  
    #end
  end

end

