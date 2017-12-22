require "toku/version"

['filters', 'errors'].each do |s|
  Dir[File.dirname(__FILE__) + "/toku/#{s}/*.rb"].each { |file| require file }
end

module Toku
  class Anonymizer

    attr_accessor :column_filters
    attr_accessor :row_filters

    # A few default filters mappings
    FILTER_MAP = {
      none: Toku::ColumnFilter::Passthrough,
      faker_last_name: Toku::ColumnFilter::FakerLastName,
      faker_first_name: Toku::ColumnFilter::FakerFirstName,
      faker_email: Toku::ColumnFilter::FakerEmail
    }

    # @param [String] config_file_path path of config file
    def initialize(config_file_path, filters = {})
      @config = YAML.load(File.read(config_file_path))
      self.column_filters = filters.merge(FILTER_MAP)
    end

    # @param [String] uri_db_source URI of the DB to be anonimized
    # @param [String] uri_db_destination URI of the destination DB
    def run(uri_db_source, uri_db_destination)
      source_db = Sequel.connect(uri_db_source)
      destination_db = Sequel.connect(uri_db_destination)

      source_db.extension(:pg_streaming)
      source_db.tables.each do |table|
        if @config[table.to_s]['columns'].count < source_db.from(table).columns.count
          raise Toku::FilterMissingError
        end

        source_db[table].stream.each do |row|
          destination_db.copy_into(table, data: transform(row, table), format: :csv)
        end
      end
    end

    # @return [String]
    def transform(row, name)
      row.map do |k, v|
        self.column_filters[@config[name.to_s]['columns'][k.to_s].first.to_sym].new.call(v)
      end.join(',')
    end
  end
end
