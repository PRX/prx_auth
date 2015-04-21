require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rack/prx_auth'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'minitest/stub_any_instance'
require 'lumberjack' rescue nil
