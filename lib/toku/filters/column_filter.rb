module Toku
  class ColumnFilter
    # @param value [Object] initial value for the column
    # @param options [Hash{String => Object}] arguments passed to the filter
    def initialize(value, options)
      @value = value
    end

    def call
      @value
    end
  end
end