require_relative 'lib/udise_school_report_reader/version'

Gem::Specification.new do |spec|
  spec.name          = "udise_school_report_reader"
  spec.version       = UdiseSchoolReportReader::VERSION
  spec.authors       = ["Syed Fazil Basheer"]
  spec.email         = ["fazil@fazn.co"]

  spec.summary       = "A Ruby gem to parse and extract data from UDISE school reports"
  spec.description   = "This gem provides functionality to read and parse UDISE school reports, extracting various data points including teacher information, room details, location data, and more."
  spec.homepage      = "https://github.com/UDISE-Plus/udise-school-report-reader"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/UDISE-Plus/udise-school-report-reader"
  spec.metadata["changelog_uri"] = "https://github.com/UDISE-Plus/udise-school-report-reader/blob/master/CHANGELOG.md"

  spec.files = Dir.glob("{lib,test}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end 