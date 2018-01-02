module Toku
  class ColumnFilter
    class FakerLastName < Toku::ColumnFilter
      def initialize(value, options)
        @value = Faker::Name.last_name
      end
    end
  end
end