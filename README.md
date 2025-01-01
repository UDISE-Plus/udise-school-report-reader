# UDISE School Report Reader

A Ruby gem for parsing and extracting data from UDISE (Unified District Information System for Education) school reports.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'udise_school_report_reader'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install udise_school_report_reader

## Usage

```ruby
require 'udise_school_report_reader'

# Initialize the parser with a PDF file
parser = UdiseSchoolReportReader::SchoolReportParser.new('path/to/report.pdf')

## Features

- Parse UDISE school reports in PDF format

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UDISE-Plus/udise-school-report-reader.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt). 