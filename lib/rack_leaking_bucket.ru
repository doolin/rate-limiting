# frozen_string_literal: true

require 'rack'
require 'json'
require 'base64'
require 'redis'
# require 'rspec/autorun' if ENV['RACK_TEST']
require_relative 'leaking_bucket'

# Show a dumb way to implement basic auth in a rack application
class DemoApp
  def call(env)
    response_body = {
      'salutations' => 'Hello!',
      'foo' => 'bar'
    }.to_json
    [200, { 'Content-Type' => 'application/json' }, [response_body]]
  end
end

# TODO: create an actual testing framework for these examples.
# Google search on "testing rackup file" returned
# http://testing-for-beginners.rubymonstas.org/rack_test/rack.html
#
# The challenge here is having both the convenience of specs written
# into the class file, and being able to run the class from elsehwere
# without the specs being invoked.

app = Rack::Builder.new do
  use LeakingBucket, bucket_size: 1, leak_rate: 1, redis_key:
  run DemoApp.new
end

run app
