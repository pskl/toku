# Toku

[![Gem Version](https://badge.fury.io/rb/toku.svg)](https://rubygems.org/gems/toku)
[![Build Status](https://travis-ci.org/LIQIDTechnology/toku.svg?branch=master)](https://travis-ci.org/LIQIDTechnology/toku)
[![Coverage Status](https://coveralls.io/repos/github/LIQIDTechnology/toku/badge.svg?branch=master)](https://coveralls.io/github/LIQIDTechnology/toku?branch=master)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/gems/toku/)
[![Documentation coverage](https://inch-ci.org/github/LIQIDTechnology/toku.svg?branch=master)](https://inch-ci.org/github/LIQIDTechnology/toku)

Toku (which comes from 'Tokumei' 匿名 in Japanese) is a gem originally designed to anonymize a database in order to feed a another database with same columns but with filtered row contents.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'toku'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install toku

## Usage

```ruby
Toku::Anonymizer.new(<path_to_config_file>).run(source_db, destination_db)
```

Users can define custom filters by implementing a `Toku::ColumnFilter` subclass like so:

```ruby
module Toku
  class NewFilter < Toku::ColumnFilter
    def initialize(value, options)
    end

    def call(_)
      _
    end
  end
end
```

Which can be then referenced in the config file using the key of the mapping hash.

## Config file specification

Config file must look like this and specifiy for each column of each table a filter to limit any potential leak of sensitive data.

```yaml
table_a:
  columns:
    id:
      - none
    first_name:
      - faker_first_name:
          parameter1: 'something'
          parameter2: 'something_else'
    last_name:
      - faker_last_name
    email:
      - faker_email
    created_at:
      - none
  rows:
    - max_creation_date:
       cutoff_date: 2017-01-15
table_b:
  rows:
    - drop
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/toku. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

