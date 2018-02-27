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

RSpec.configure do |config|
  config.before(:suite) do
    system("dropdb postgres --if-exists")
    system("dropdb destination --if-exists")
    system("createdb origin")
    system("createdb postgres")
    system("createdb destination")
    system("createuser pskl -s")
  end
end