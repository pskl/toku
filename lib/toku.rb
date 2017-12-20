require "toku/version"

Dir[File.dirname(__FILE__) + '/toku/filters/*.rb'].each { |file| require file }

module Toku
  class Anonymizer

    # @param [String] config_file_path path of config file
    def initialize(config_file_path)
      config = YAML.load(config_file_path)
    end

    # @param [String] uri_db_source URI of the DB to be anonimized
    # @param [String] uri_db_destination URI of the destination DB
    def run(uri_db_source, uri_db_destination)
      raise 'please upgrade to PostgreSQL 9.2 and later versions' if PSequel::Postgres.supports_streaming?
      source_db = Sequel.connect(uri_db_source)
      destination_db = Sequel.connect(uri_db_destination)

      source_db.tables.each do |table|
        Sequel::Postgres::Database.copy_into(destination_table, data: data(table))
      end
    end

    # @param [] table
    # @return Enumerator
    def data(table)
      binding.pry
      table.stream.each do |row|
      end
    end
  end
end
