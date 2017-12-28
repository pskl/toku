# When a filter for one column is not specified
# This is to enforce the fact that no column treatment can be 'inferred'
module Toku
  class ColumnFilterMissingError < StandardError
  end
end