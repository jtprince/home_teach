require 'home_teach/contactable'

module HomeTeach
  class Person
    include Contactable
    attr_accessor :last, :first, :sex, :birthday, :age
    def initialize(last, first, other={})
      (@last, @first) = last, first
      other.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    # just the first name and not any middle name
    def just_first
      first.split(' ')[0]
    end

    def full_name
      [first, last].join(" ")
    end

    # the full name without the middle name
    def casual_full_name
      [just_first, last].join(" ")
    end

    # returns "First Last" <email>, or nil if no email
    def email_with_name
      if email
        %Q{"#{first} #{last}" <#{email}>}
      end
    end

    # another_record takes precedence, but will not over-write data with nil
    def merge!(another_record)
      new_one = self.dup
      [:last, :first, :sex, :birthday, :age, :address, :phone, :email].each do |key|
        if new_val = another_record.send(key)
          self.send("#{key}=", new_val)
        end
      end
    end

    def eql?(other)
      (self == other) && (self.class == other.class)
    end

    def ==(other)
      first_condition = [:last, :first].all? do |key|
        self.send(key) == other.send(key)
      end
      # one is nil or both are equal
      second_condition = [:sex, :birthday, :age, :address, :phone, :email].all? do |key| 
        a = self.send(key)
        b = other.send(key)
        (a.nil? || b.nil?) || a==b
      end
      first_condition && second_condition
    end

    def <=>(other)
      cmp = ( [last, first, sex, age, birthday] <=> [other.last, other.first, other.sex, other.age, other.birthday] )
      if cmp == 0
        can_use = [:phone, :email, :address].reject {|at| self.send(at).nil? || other.send(at).nil? }
        can_use.map {|at| self.send(at) } <=> can_use.map {|at| other.send(at) }
      else
        cmp
      end
    end
  end
end

