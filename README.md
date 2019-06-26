# NCMCAuthorities

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ncmc_authorities`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ncmc_authorities'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ncmc_authorities

## Usage

See `lib/ncmc_authorities/demo.rb`.

For corporate/meeting name matching, a local instance of solr listening on port 9983 is expected, and the solr instance is expected to have `corporate` and `meeting` collections already present.

There's
a vagrant box that includes solr, but it's not set to automatically start solr or create those collections. The following is sufficient:
```bash
solr start
solr create_core -c corporate
solr create_core -c meeting
```

(You'd then run these scripts on the host machine, where port 9983 will forward to solr at vagrant guest's port 8983.)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ncmc_authorities.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
