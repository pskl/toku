module Toku
  class ColumnFilter
    class Obfuscate < Toku::ColumnFilter
      def call
        SecureRandom.hex(10)
      end
    end
  end
end