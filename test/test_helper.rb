require "coveralls"
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "prx_auth"
require "rack/prx_auth"
require "pry"
require "pry-byebug"

require "minitest/autorun"
require "minitest/spec"
require "minitest/pride"
