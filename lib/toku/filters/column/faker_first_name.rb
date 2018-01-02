module Toku
  class ColumnFilter
    class FakerFirstName < Toku::ColumnFilter
      def initialize(value, options)
        @value = Faker::Name.first_name
      end
    end
  end
end