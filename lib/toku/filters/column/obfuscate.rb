module Toku
  class ColumnFilter
    class Obfuscate < Toku::ColumnFilter
      def initialize(value, options)
        @value =  SecureRandom.hex(10)
      end
    end
  end
end