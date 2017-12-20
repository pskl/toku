class Column
  # @param options [Hash{Symbol => Object}] arguments passed to the filter
  def initialize(**options)

  end


  # Takes as input a {LazyEnumerator} of the rows, returns another {LazyEnumerator} applying some filter
  # @param input [String, Number, nil] value assigned to the field in the column
  # @return [String, Number, nil] value of the field after passing through the filter
  def call(input)
    input
  end
end