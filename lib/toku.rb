require "toku/version"
require "uri"
require 'sequel'
require 'csv'
require 'concurrent'

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
      faker_email: Toku::ColumnFilter::FakerEmail,
      obfuscate: Toku::ColumnFilter::Obfuscate,
      nullify: Toku::ColumnFilter::Nullify
    }

    # A few default row filters mappings
    ROW_FILTER_MAP = {
      drop: Toku::RowFilter::Drop
    }

    THREADPOOL_SIZE = (Concurrent.processor_count * 2).freeze

    SCHEMA_DUMP_PATH = "tmp/toku_source_schema_dump.sql"

    # @param [String] config_file_path path of config file
    def initialize(config_file_path, column_filters = {}, row_filters = {})
      @config = YAML.load(ERB.new(File.read(config_file_path)).result)
      @threadpool = Concurrent::FixedThreadPool.new(THREADPOOL_SIZE)
      self.column_filters = column_filters.merge(COLUMN_FILTER_MAP)
      self.row_filters = row_filters.merge(ROW_FILTER_MAP)
      Sequel::Database.extension(:pg_streaming)
    end

    # @param uri_db_source [String] uri_db_source URI of the DB to be anonimized
    # @param uri_db_destination [String] URI of the destination DB
    # @return [void]
    def run(uri_db_source, uri_db_destination)
      begin_time_stamp = Time.now
      @global_count = 0
      source_db = Sequel.connect(uri_db_source)
      dump_schema(uri_db_source)
      parsed_destination_uri = URI(uri_db_destination)
      destination_db_name = parsed_destination_uri.path.tr("/", "")
      destination_connection =
        Sequel.connect("postgres://#{parsed_destination_uri.user}:#{parsed_destination_uri.password}@#{parsed_destination_uri.host}:#{parsed_destination_uri.port || 5432}/template1")
      destination_connection.run("DROP DATABASE IF EXISTS #{destination_db_name}")
      destination_connection.run("CREATE DATABASE #{destination_db_name}")
      destination_connection.disconnect
      destination_db = Sequel.connect(uri_db_destination)
      destination_db.run(File.read(SCHEMA_DUMP_PATH))
      destination_pool = Sequel::ThreadedConnectionPool.new(destination_db)
      source_pool = Sequel::ThreadedConnectionPool.new(source_db)

      source_db.tables.each do |t|
        if !row_filters?(t) && @config[t.to_s]['columns'].count < source_db.from(t).columns.count
          raise Toku::ColumnFilterMissingError
        end
        @threadpool.post do
          destination_pool.hold do |destination_connection|
            source_pool.hold do |source_connection|
              process_table(t, source_connection.instance_variable_get(:@db), destination_connection.instance_variable_get(:@db))
            end
          end
        end
      end

      @threadpool.shutdown
      @threadpool.wait_for_termination
      source_db.disconnect
      destination_db.disconnect
      FileUtils.rm(SCHEMA_DUMP_PATH)
      puts "Toku: copied #{@global_count} elements in total and that took #{(Time.now - begin_time_stamp).round(2)} seconds with #{THREADPOOL_SIZE} green threads"
      nil
    end

    # @param name [Symbol]
    # @param row [Hash]
    # @return [String]
    def transform(row, table_name)
      row.map do |row_key, row_value|
        @config[table_name.to_s]['columns'][row_key.to_s].inject(row_value) do |result, filter|
          if filter.is_a? Hash
            filter_class(column_filters, filter.keys.first.to_sym).new(
              result,
              filter.values.first
            ).call
          elsif filter.is_a? String
            filter_class(column_filters, filter.to_sym).new(result, {}).call
          end
        end
      end.to_csv
    end

    def process_table(table, source_connection, destination_connection)
      row_enumerator = source_connection[table].stream.lazy
      @config[table.to_s]['rows'].each do |f|
        row_filter = if f.is_a? String
          self.row_filters[f.to_sym].new({})
        elsif f.is_a? Hash
          self.row_filters[f.keys.first.to_sym].new(f.values.first)
        end
        row_enumerator = row_filter.call(row_enumerator)
      end

      destination_connection.run("ALTER TABLE #{table} DISABLE TRIGGER ALL;")
      destination_connection.copy_into(table, data: row_enumerator.map { |row| transform(row, table) }, format: :csv)
      destination_connection.run("ALTER TABLE #{table} ENABLE TRIGGER ALL;")
      count = destination_connection[table].count
      @global_count += count
      puts "Toku: copied #{count} objects into #{table} #{count != 0 ? ':)' : ':|'}"
    end

    # @param uri [String]
    # @return [void]
    def dump_schema(uri)
      FileUtils::mkdir_p 'tmp'
      host = URI(uri).host
      password = URI(uri).password || ENV["PGPASSWORD"]
      user = URI(uri).user
      password = URI(uri).password
      port = URI(uri).port || 5432
      db_name = URI(uri).path.tr("/", "")
      raise "pg_dump schema dump failed" unless system(
        "PGPASSWORD=#{password} pg_dump -s -h #{host} -p #{port} -U #{user}  #{db_name} > #{SCHEMA_DUMP_PATH}"
      )
    end

    def filter_class(type, symbol)
      raise "Please provide a filter for #{symbol}" if type[symbol].nil?
      type[symbol]
    end

    # Are there row filters specified for this table?
    # @param table [Symbol]
    # @return [Boolean]
    def row_filters?(table)
      !@config[table.to_s]['rows'].nil? && @config[table.to_s]['rows'].any?
    end
  end
end
