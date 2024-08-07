#!/usr/bin/env ruby

# Designing a simple load test for a rate limiter on a Rack
# application running in a Docker container can provide insights
# into several aspects of performance. Below is a guide on how
# to design this test and the key performance aspects to explore.

# == 1. Setup for Load Testing

# === Rack Application
#
# Assume the Rack application implements the rate limiter using a
# single key (no filtering by username, IP address, etc.).

# === Docker Setup
#
# Ensure the Rack application is running inside a Docker container
# and is accessible via a specific port.

# === Test Client
#
# The client will be a Ruby script that simulates multiple requests
# to the Rack application.
#
# == 3. Aspects of Performance to Explore
#
# === Rate Limiting Behavior
#
# * Request Success vs. Failure: Track the proportion of successful
#   (e.g., HTTP 200) vs. rate-limited (e.g., HTTP 429) responses.
#   This helps to determine whether the rate limiter is enforcing
#   the intended limits.

# === Latency
# * Request Latency: Measure the time it takes for each request to
#   receive a response.
#   Latency can indicate how the rate limiter and the underlying
#   system handle traffic under load.
# * Impact of Rejected Requests: Observe if there’s a difference in
#   latency between successful requests and those that are rate-limited.

# === Throughput
# * Requests Per Second: Calculate the overall throughput of the system
#   (number of requests processed per second).
#   This metric helps to understand how well the rate limiter and
#   application scale under load.

# === Concurrency and Scalability
# * Concurrency Impact: Test different levels of concurrency to see
#   how the system scales.
#   For instance, increase the number of concurrent threads to simulate
#   higher load and observe the system's behavior.
# * Bottlenecks: Identify if there are any bottlenecks, such as increased
#   latency or higher rate of rejected requests as concurrency increases.

# === Resource Utilization
# * CPU and Memory Usage: Monitor CPU and memory usage on the Docker
#   container running the Rack application.
#   Increased load might cause higher resource consumption, and it’s
#   important to see if the rate limiter is efficient in managing resources.
# * Docker Container Limits: Explore how the application behaves when Docker
#   resource limits (e.g., CPU or memory limits) are hit.
#   This can help you understand the resilience of the rate limiter.

# === Resilience and Stability
#
# * Stability Under Sustained Load: Test the system under sustained
#   load over a longer period to ensure that the rate limiter maintains
#   consistent performance without degrading over time.
# * Recovery from High Load: Observe how the system recovers once the
#   high load subsides.
# * Does the rate limiter reset correctly, or does it continue to limit
#   requests unnecessarily?

# === Error Handling
# * Handling of Edge Cases: Test how the system behaves when the
#   rate limiter is overwhelmed or when the application experiences
#   unexpected spikes in traffic.
#   Are errors gracefully handled, and is the system able to recover?

# === Impact on Application Performance
# * Application Responsiveness: Assess whether the rate limiter
#   negatively impacts the responsiveness of other parts of the application.
#   For instance, does applying the rate limit cause delays in other
#   unrelated requests?

# == 4. Running the Test

# * Execute the Ruby Script: Run the load test script
#   and observe the output.
# * Monitor Docker and Application: Use Docker tools (e.g., docker stats)
#   and application logs to monitor performance metrics in real-time.

# == 5. Analyzing Results
#
# * Breakdown of Responses: Analyze the breakdown of HTTP response codes
#   to determine the effectiveness of the rate limiter.
# * Latency and Throughput: Review latency and throughput metrics to
#   understand the impact of load on system performance.
# * Resource Usage: Assess resource utilization to identify potential
#   inefficiencies or areas for optimization.

# == Summary
#
# This simple load test design allows you to explore several key performance
# aspects of a rate limiter in a Rack application running inside a Docker container.
# By examining rate limiting behavior, latency, throughput, scalability,
# resource utilization, and resilience, you can gain insights into how well the
# rate limiter performs under different conditions.

require 'net/http'
require 'uri'
require 'concurrent'

uri = URI.parse('http://localhost:9998') # Update with your Rack app URL and port
num_requests = 1000 # Number of total requests
concurrency = 50    # Number of concurrent threads

def send_request(uri)
  Net::HTTP.get_response(uri)
end

# Create a thread pool with a fixed number of threads
pool = Concurrent::FixedThreadPool.new(concurrency)
responses = Concurrent::Array.new

# Execute the load test
start_time = Time.now

num_requests.times do
  pool.post do
    response = send_request(uri)
    responses << response.code
  end
end

# Shutdown the pool and wait for all tasks to finish
pool.shutdown
pool.wait_for_termination
end_time = Time.now
elapsed_time = end_time - start_time

puts "Total time: #{elapsed_time} seconds"
puts 'Responses breakdown:'
puts(responses.group_by { |code| code }.map { |code, arr| "#{code}: #{arr.size}" })
