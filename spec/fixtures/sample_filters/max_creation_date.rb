module Toku
  class RowFilter
    class MaxCreationDate < ::Toku::RowFilter
      attr_accessor :cutoff_date

      def initialize(options)
        self.cutoff_date = options['cutoff_date']
      end

      def call(stream)
        stream.select do |row|
          row[:created_at] >= self.cutoff_date
        end
      end
    end
  end
end