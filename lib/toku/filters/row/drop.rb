module Toku
  class RowFilter
    class Drop < Toku::RowFilter
      def call(stream)
        stream.select { |row| false }
      end
    end
  end
end