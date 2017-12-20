# Toku

Toku (which comes from 'Tokumei' in Japanese) is a gem originally designed to anonymize a production database in order to feed a staging database with similar properties.

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

`Toku::Anonymizer.new(<path_to_config_file>).run(source_db, destination_db)`

## Config file specification

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/toku. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

