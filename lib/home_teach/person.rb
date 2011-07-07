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
    def merge(another_record)
      new_one = self.dup
      [:last, :first, :sex, :birthday, :age, :address, :phone, :email].each do |key|
        if new_val = another_record.send(key)
          #### HERER

        end
      end
    end

    def ==(other)
      if last == other.last && first == other.first
        return false if sex != other.sex
        if phone.andand == other.phone || email.andand == other.email || address.andand == other.address
          true
        else
          false
        end
      end
    end
  end
end

