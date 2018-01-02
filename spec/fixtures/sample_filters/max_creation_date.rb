module Toku
  class RowFilter
    class MaxCreationDate < ::Toku::RowFilter

      def initialize(options)
        @cutoff_date = options['cutoff_date']
      end

      def call(stream)
        stream.select do |row|
          row[:created_at] >= @cutoff_date
        end
      end
    end
  end
end