$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "toku"
require 'pry'
require 'pg_tester'
require 'sequel'
require 'faker'

Dir[File.dirname(__FILE__) + "/fixtures/sample_filters/**/*.rb"].each { |file| require file }

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
    data_dir: '/tmp/' + name
  })
end