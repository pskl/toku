module Toku
  class ColumnFilter
    # @param options [Hash{Symbol => Object}] arguments passed to the filter
    def initialize(value, options)
      @value = value
    end

    def call
      @value
    end
  end
end