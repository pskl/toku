require 'yaml'
# Run only in a Rails environment
# Run this task to generate a base config file for your Rails application
# after run it's up to you to whitelist specific arguments in the list
namespace :toku do
  desc 'Generate base config file from your base database schema in Rails'
  task genesis_rails: :environment do
    path =  Rails.root.join('tmp').join('config.yml')
    File.open(path, 'w') do |f|
      hash = {}
      ActiveRecord::Base.connection.tables.each do |table|
        hash[table] = { 'columns' => {}, 'rows' => [] }
        ActiveRecord::Base.connection.columns(table).map(&:name).each do |column|
          if column.ends_with?("_at") || column.ends_with?("id") || column == 'id'
            hash[table]['columns'][column] = ['none']
          else
            hash[table]['columns'][column] = ['obfuscate']
          end
        end
      end
      f.write(hash.to_yaml)
    end
    puts "Pickup your config file in #{path}"
  end
end