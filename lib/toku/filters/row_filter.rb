module Toku
  class RowFilter
    # @param options [Hash{String => Object}] arguments passed to the filter
    def initialize(options)
    end

    # @param [LazyEnumerator] stream
    # @return [LazyEnumerator] stream
    def call(_)
      _
    end
  end
end