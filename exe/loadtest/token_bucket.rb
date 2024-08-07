require 'net/http'
require 'uri'
require 'concurrent'

uri = URI.parse("http://localhost:9998") # Update with your Rack app URL and port
num_requests = 1000 # Number of total requests
concurrency = 50    # Number of concurrent threads

def send_request(uri)
  Net::HTTP.get_response(uri)
end

# Execute the load test
start_time = Time.now
responses = Concurrent::Array.new

Concurrent::FixedThreadPool.new(concurrency).tap do |pool|
  num_requests.times do
    pool.post do
      response = send_request(uri)
      responses << response.code
    end
  end
end.shutdown

end_time = Time.now
elapsed_time = end_time - start_time

puts "Total time: #{elapsed_time} seconds"
puts "Responses breakdown:"
puts responses.group_by { |code| code }.map { |code, arr| "#{code}: #{arr.size}" }

