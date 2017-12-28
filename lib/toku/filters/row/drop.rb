module Toku
  class RowFilter
    class Drop < Toku::RowFilter
      def call(stream)
        stream.each { |row| nil }
      end
    end
  end
end