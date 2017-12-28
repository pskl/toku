# When the origin and destination table dont have the same schema
module Toku
  class SchemaMismatchError < StandardError
  end
end