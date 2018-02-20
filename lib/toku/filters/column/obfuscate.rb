module Toku
  class ColumnFilter
    class Obfuscate < Toku::ColumnFilter
      def initialize(value, options)
        @value = "XXXXXXXXX"
      end
    end
  end
end