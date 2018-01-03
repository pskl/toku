require 'yaml'

namespace :toku
  desc 'Generate base config file from your base database schema in Rails'
  task :genesis_rails
    File.open(Rails.root.join('tmp').join('config.yml'), 'w') do |f|
      hash = {}
      ActiveRecord::Base.connection.tables.each do |table|
        hash[table] = { 'columns' => {}, 'rows' => [nil] }
        ActiveRecord::Base.connection.columns(table).map(&:name).each do |column|
          hash[table]['columns'][column] = ['drop']
        end
      end
      f.write hash.to_yaml
    end
  end
end