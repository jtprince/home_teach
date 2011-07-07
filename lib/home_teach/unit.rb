
module HomeTeach
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
end

