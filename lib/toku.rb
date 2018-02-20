require "toku/version"
require "uri"

Dir[File.dirname(__FILE__) + "/toku/**/*.rb"].each { |file| require file }

module Toku
  class Anonymizer
    attr_accessor :column_filters
    attr_accessor :row_filters

    # A few default column filters mappings
    COLUMN_FILTER_MAP = {
      none: Toku::ColumnFilter::Passthrough,
      faker_last_name: Toku::ColumnFilter::FakerLastName,
      faker_first_name: Toku::ColumnFilter::FakerFirstName,
      faker_email: Toku::ColumnFilter::FakerEmail
    }

    # A few default row filters mappings
    ROW_FILTER_MAP = {
      drop: Toku::RowFilter::Drop
    }

    SCHEMA_DUMP_PATH = "/tmp/toku_source_schema_dump.sql"

    # @param [String] config_file_path path of config file
    def initialize(config_file_path, column_filters = {}, row_filters = {})
      @config = YAML.load(File.read(config_file_path))
      self.column_filters = column_filters.merge(COLUMN_FILTER_MAP)
      self.row_filters = row_filters.merge(ROW_FILTER_MAP)
      Sequel::Database.extension(:pg_streaming)
    end

    # @param uri_db_source [String] uri_db_source URI of the DB to be anonimized
    # @param uri_db_destination [String] URI of the destination DB
    # @return [void]
    def run(uri_db_source, uri_db_destination)
      source_db = Sequel.connect(uri_db_source)
      dump_schema(URI(uri_db_source).path.tr("/", ""))
      parsed_destination_uri = URI(uri_db_destination)
      destination_db_name = parsed_destination_uri.path.tr("/", "")
      destination_host =
        Sequel.connect("postgres://#{parsed_destination_uri.user}:#{parsed_destination_uri.password}@#{parsed_destination_uri.host}:#{parsed_destination_uri.port}/template1")
      destination_host.run("DROP DATABASE IF EXISTS #{destination_db_name}")
      destination_host.run("CREATE DATABASE #{destination_db_name}")
      destination_db = Sequel.connect(uri_db_destination)
      destination_db.run(File.read(SCHEMA_DUMP_PATH))

      raise Toku::SchemaMismatchError unless source_schema_included?(source_db, destination_db)

      source_db.tables.each do |table|
        if !row_filters?(table) && @config[table.to_s]['columns'].count < source_db.from(table).columns.count
          raise Toku::ColumnFilterMissingError
        end
        row_enumerator = source_db[table].stream.lazy

        @config[table.to_s]['rows'].each do |f|
          if f.is_a? String
            row_filter = self.row_filters[f.to_sym].new({})
          elsif f.is_a? Hash
            row_filter = self.row_filters[f.keys.first.to_sym].new(f.values.first)
          end

          row_enumerator = row_filter.call(row_enumerator)
        end

        row_enumerator = row_enumerator.map { |row| transform(row, table) }
        destination_db.copy_into(table, data: row_enumerator, format: :csv)
        count = destination_db[table].count
        puts "Toku: copied #{count} objects into #{table} #{count != 0 ? ':)' : ':|'}"
      end

      source_db.disconnect
      destination_db.disconnect
      FileUtils.rm(SCHEMA_DUMP_PATH)
      nil
    end

    # @param name [Symbol]
    # @param row [Hash]
    # @return [String]
    def transform(row, name)
      row.map do |k, v|
        filter_params = @config[name.to_s]['columns'][k.to_s].first
        if filter_params.is_a? Hash
          column_filter = self.column_filters[filter_params.keys.first.to_sym].new(
            v,
            filter_params.values.first
          )
        elsif filter_params.is_a? String
          column_filter = self.column_filters[filter_params.to_sym].new(v, {})
        end
        column_filter.call
      end.join(",") + "\n"
    end

    # Is the source database schema a subset of the destination database schema?
    # @param source_db [String] URI of source database
    # @param destination_db [String] URI of destination database
    # @return [Boolean]
    def source_schema_included?(source_db, destination_db)
      source_db.tables.all? do |table|
        source_db.schema(table) == destination_db.schema(table)
      end
    end

    def dump_schema(db_name)
      raise "Dump failed" unless system("pg_dump", "-s", "-x", "-O", "-f", SCHEMA_DUMP_PATH, "#{db_name}")
    end

    # Are there row filters specified for this table?
    # @param table [Symbol]
    # @return [Boolean]
    def row_filters?(table)
      !@config[table.to_s]['rows'].nil? && @config[table.to_s]['rows'].any?
    end
  end
end
