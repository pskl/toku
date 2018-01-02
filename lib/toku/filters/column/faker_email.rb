module Toku
  class ColumnFilter
    class FakerEmail < Toku::ColumnFilter
      def initialize(value, options)
        @value = Faker::Internet.email
      end
    end
  end
end