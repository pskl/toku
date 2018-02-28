module Toku
  class ColumnFilter
    class Nullify < Toku::ColumnFilter
      def call
        nil
      end
    end
  end
end