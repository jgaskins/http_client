require "http/server"
require "http_client"
require "http_client/json"
require "wait_group"

Log.setup :trace

port = 12345

spawn do
  server = HTTP::Server.new do |context|
    sleep 1.second
    {
      method: context.request.method,
      path:   context.request.resource,
    }.to_json context.response
  end
  server.listen port
end
Fiber.yield # give the server a chance to start

http = HTTPClient.new("http://localhost:#{port}")

WaitGroup.wait do |wg|
  wg.spawn { pp http.get "/foo" }
  wg.spawn { pp http.get "/foo", as: HTTPClient::JSON(Response) }
end
puts "Done"
pp http

struct Response
  include JSON::Serializable

  getter method : String
  getter path : String
end

# Monkeypatch a couple methods onto WaitGroup to make it a little easier to work with
class WaitGroup
  def self.wait
    instance = new
    yield instance
    instance.wait
  end

  def spawn(&block)
    id = "WaitGroup##{object_id}"
    add

    ::spawn do
      Log.for(id).trace { "starting" }
      block.call
    ensure
      done
      Log.for(id).trace { "done" }
    end
  end
end
