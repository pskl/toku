module Toku
  class ColumnFilter
    # @param options [Hash{Symbol => Object}] arguments passed to the filter
    def initialize(**options)
    end

    def call(input)
      input
    end
  end
end