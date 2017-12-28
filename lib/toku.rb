require "toku/version"
Dir[File.dirname(__FILE__) + "/toku/**/*.rb"].each { |file| require file }

module Toku
  class Anonymizer

    attr_accessor :column_filters
    attr_accessor :row_filters

    # A few default filters mappings
    COLUMN_FILTER_MAP = {
      none: Toku::ColumnFilter::Passthrough,
      faker_last_name: Toku::ColumnFilter::FakerLastName,
      faker_first_name: Toku::ColumnFilter::FakerFirstName,
      faker_email: Toku::ColumnFilter::FakerEmail
    }

    ROW_FILTER_MAP = {
      drop: Toku::RowFilter::Drop
    }

    # @param [String] config_file_path path of config file
    def initialize(config_file_path, column_filters = {}, row_filters = {})
      @config = YAML.load(File.read(config_file_path))
      self.column_filters = column_filters.merge(COLUMN_FILTER_MAP)
      self.row_filters = row_filters.merge(ROW_FILTER_MAP)
    end

    # @param [String] uri_db_source URI of the DB to be anonimized
    # @param [String] uri_db_destination URI of the destination DB
    def run(uri_db_source, uri_db_destination)
      source_db = Sequel.connect(uri_db_source)
      destination_db = Sequel.connect(uri_db_destination)

      raise Toku::SchemaMismatchError unless source_schema_included?(source_db, destination_db)

      source_db.extension(:pg_streaming)

      source_db.tables.each do |table|
        if @config[table.to_s]['columns'].count < source_db.from(table).columns.count
          raise Toku::ColumnFilterMissingError
        end

        row_enumerator = source_db[table].stream.to_enum

        @config[table.to_s]['rows'].each do |f|
          row_filter = self.row_filters[f.keys.first.to_sym]
          if f.is_a? String
            options = nil
          elsif f.is_a? Hash
            options = f.values.first
          end

          row_enumerator = row_filter.new(options).call(row_enumerator)
        end

        row_enumerator = row_enumerator.map { |row| transform(row, table) }
        destination_db.copy_into(table, data: row_enumerator, format: :csv)
      end
    end

    # @return [String]
    def transform(row, name)
      row.map do |k, v|
        self.column_filters[@config[name.to_s]['columns'][k.to_s].first.to_sym].new.call(v)
      end.join(',')
    end

    def source_schema_included?(source_db, destination_db)
      source_db.tables.all? do |table|
        source_db.schema(table) == destination_db.schema(table)
      end
    end
  end
end
