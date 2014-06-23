ENV['RACK_ENV'] = 'test'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require "minitest/autorun"
require "minitest/hell"