require 'simplecov-lcov'


SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.lcov_file_name = 'lcov.info'
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter,
                                                                SimpleCov::Formatter::LcovFormatter])

SimpleCov.start do
  root __dir__
  merge_timeout 300
end
