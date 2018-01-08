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
        if !row_filters?(table) && @config[table.to_s]['columns'].count < source_db.from(table).columns.count
          raise Toku::ColumnFilterMissingError
        end
        row_enumerator = source_db[table].stream.lazy
        destination_db[table].truncate

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
      nil
    end

    # @param [Symbol] name
    # @param [Hash] row
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

    def source_schema_included?(source_db, destination_db)
      source_db.tables.all? do |table|
        source_db.schema(table) == destination_db.schema(table)
      end
    end

    def row_filters?(table)
      !@config[table.to_s]['rows'].nil? && @config[table.to_s]['rows'].any?
    end
  end
end
