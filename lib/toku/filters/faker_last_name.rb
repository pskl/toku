module Toku
  class ColumnFilter
    class FakerLastName < Toku::ColumnFilter
      def call(_)
        Faker::Name.last_name
      end
    end
  end
end