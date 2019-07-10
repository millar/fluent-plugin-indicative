require 'bundler/setup'
require 'test/unit'

require 'webmock/test_unit'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'fluent/test'
require 'fluent/test/driver/output'

require 'fluent/plugin/out_indicative'
