module Toku
  class ColumnFilter
    class Passthrough < Toku::ColumnFilter
      def call(_)
        _.to_s
      end
    end
  end
end