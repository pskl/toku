module Toku
  class ColumnFilter
    class Nullify < Toku::ColumnFilter
      def initialize(value, options)
        @value =  nil
      end
    end
  end
end