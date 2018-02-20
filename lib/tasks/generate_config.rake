require 'yaml'
# Run only in a Rails environment

namespace :toku do
  desc 'Generate base config file from your base database schema in Rails'
  task genesis_rails: :environment do
    File.open(Rails.root.join('tmp').join('config.yml'), 'w') do |f|
      hash = {}
      ActiveRecord::Base.connection.tables.each do |table|
        hash[table] = { 'columns' => {}, 'rows' => ['drop'] }
        ActiveRecord::Base.connection.columns(table).map(&:name).each do |column|
          hash[table]['columns'][column] = ['obfuscate']
        end
      end
      f.write(hash.to_yaml)
    end
  end
end