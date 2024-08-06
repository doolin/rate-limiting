#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'base64'

# Client class for sending a basic auth request
# It doesn't need to actually do anything other
# than send the request.
class FixedWindowCounter
  def initialize
    @uri = URI('http://localhost:9997')
    @http = Net::HTTP.new(@uri.host, @uri.port)
  end

  def basic_auth_header
    { 'Authorization: Basic' => Base64.strict_encode64('username1:password') }
  end

  def get_request
    request = Net::HTTP::Get.new(@uri)
    # request.add_field('Authorization', "Basic #{Base64.strict_encode64('username1:password')}")
    response = @http.request(request)

    puts response.body
  end
end

client = FixedWindowCounter.new
client.get_request
