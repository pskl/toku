$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'pry'
require 'concurrent'
require 'toku'
require 'pg_tester'
require 'sequel'
require 'faker'
require 'objspace'
require 'coveralls'

Coveralls.wear!

PG_PORT=5432

Dir[File.dirname(__FILE__) + "/fixtures/**/*.rb"].each { |file| require file }

def sequel_connection(psql)
  Sequel.postgres(
    psql.db,
    user: psql.user,
    host: psql.host,
    port: psql.port
  )
end

def pg_db(name)
  PgTester.new({
    host: 'localhost',
    database: name,
    user: name,
    db_name: name,
    role: name,
    user_name: name,
    port: PG_PORT,
    data_dir: '/tmp/' + name
  })
end

RSpec.configure do |config|
  config.before(:suite) do
    system("dropdb origin")
    system("dropdb destination")
  end
end