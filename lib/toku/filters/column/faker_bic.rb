module Toku
  class ColumnFilter
    class FakerBic < Toku::ColumnFilter
      def call
        Faker::Bank.swift_bic
      end
    end
  end
end