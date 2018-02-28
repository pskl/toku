module Toku
  class ColumnFilter
    class FakerEmail < Toku::ColumnFilter
      def call
        Faker::Internet.email
      end
    end
  end
end