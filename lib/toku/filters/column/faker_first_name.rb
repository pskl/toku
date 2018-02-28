module Toku
  class ColumnFilter
    class FakerFirstName < Toku::ColumnFilter
      def call
        Faker::Name.first_name
      end
    end
  end
end