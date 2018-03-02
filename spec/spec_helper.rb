$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'pry'
require 'concurrent'
require 'toku'
require 'sequel'
require 'faker'
require 'objspace'
require 'coveralls'

Coveralls.wear!

PG_PORT=5432

Dir[File.dirname(__FILE__) + "/fixtures/**/*.rb"].each { |file| require file }

def setup_test_records(size)
  table_a_1 = origin_connection.from(:table_a)
  table_b_1 = origin_connection.from(:table_b)
  [table_a_1, table_b_1].each do |t|
    t.truncate if t.to_a.any?
  end
  table_a_1.insert(
    first_name: 'Paskal',
    last_name: 'Kamovich',
    email: 'paskal.kamovich@gmail.ru',
    created_at: Date.parse('2017-01-20')
  )
  table_a_1.insert(
    first_name: 'Paulo',
    last_name: 'Bedo',
    email: 'paulo@bedo.lol',
    created_at: Date.parse('2017-01-03')
  )
  table_b_1.insert(
    something: 'lol',
    something_else: 'lol_else'
  )
  table_a_1.import(
    [
      :created_at,
      :first_name,
      :last_name,
      :email
    ],
    [
      [
        Date.parse('2017-01-31'),
        'Anon',
        'Anon',
        'assange@nicaragua.fr'
      ]
    ] * size
  )
  origin_connection.disconnect
end

RSpec.configure do |config|
  config.before(:suite) do
    system("dropdb postgres --if-exists")
    system("dropdb destination --if-exists")
    system("dropdb origin --if-exists")
    system("createdb origin")
    system("createdb postgres")
    system("createdb destination")
    system("createuser pskl -s")
  end
end