module Toku
  class ColumnFilter
    class FakerEmail < Toku::ColumnFilter
      def call(_)
        Faker::Internet.email
      end
    end
  end
end