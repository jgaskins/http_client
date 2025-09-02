require "./spec_helper"

require "wait_group"
require "http/server"

server = HTTP::Server.new do |context|
  request = context.request
  response = context.response

  case {request.method, request.path}
  when {"GET", "/foo"}
    response << "foo"
  when {"POST", "/foo"}
    response.status = :created
    response << "Nice"
  when {"GET", "/sleep"}
    duration = request.query_params["duration_sec"].to_i.seconds
    sleep duration
  else
    response.status = :not_found
    response << "Unexpected request: #{request.method} #{request.resource}"
  end
end
spawn server.listen 12345

describe HTTPClient do
  http = HTTPClient.new(URI.parse("http://localhost:12345"))

  it "works like a regular HTTP::Client" do
    resp = http.get("/foo")
    resp.should have_status :ok
    resp.should have_body "foo"

    resp = http.post("/foo", body: "asdf")
    resp.should have_status :created
    resp.should have_body "Nice"
  end

  it "allows sending many simultaneous requests" do
    responses = [] of HTTP::Client::Response

    WaitGroup.wait do |wg|
      100.times do
        wg.spawn { responses << http.get "/foo" }
      end
    end

    responses.map(&.body).should eq %w[foo] * 100
  end

  it "raises HTTPClient::Error if the connection pool times out" do
    limited_client = HTTPClient.new(URI.parse("http://localhost:12345?max_pool_size=2&checkout_timeout=0.01"))

    # Send enough long-running requests to fill the connection pool
    2.times do
      spawn { limited_client.get "/sleep?duration_sec=1" }
    end
    # Pause to let those requests begin
    Fiber.yield

    expect_raises HTTPClient::Error do
      limited_client.get "/"
    end
  end
end

def have_status(status : HTTP::Status)
  HaveStatus.new status
end

record HaveStatus, status : HTTP::Status do
  def match(response : HTTP::Client::Response)
    response.status == status
  end

  def failure_message(response : HTTP::Client::Response)
    "Expected response to have #{status}, got #{response.status}"
  end
end

def have_body(body : String)
  HaveBody.new body
end

record HaveBody, body : String do
  def match(response : HTTP::Client::Response)
    response.body.includes? body
  end

  def failure_message(response : HTTP::Client::Response)
    "Expected #{body.inspect} in HTTP response body: #{response.body}"
  end
end
