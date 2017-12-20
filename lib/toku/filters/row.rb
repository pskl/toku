class Row
  # @paramoptions [Hash{Symbol => Object}] arguments passed to the filter
  def initialize(**options)
  end

  # Takes as input a {LazyEnumerator} of the rows, returns another {LazyEnumerator} applying some filter
  # @paramlazy_enumerator [LazyEnumerator] source stream
  # @return [LazyEnumerator] destination stream
  def call(lazy_enumerator)
    lazy_enumerator
  end
end