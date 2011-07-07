require 'home_teach/contactable'

module HomeTeach
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
end

