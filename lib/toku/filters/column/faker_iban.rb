module Toku
  class ColumnFilter
    class FakerIban < Toku::ColumnFilter
      def call
        Faker::Bank.iban(@options['country_code'])
      end
    end
  end
end