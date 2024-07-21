require "db/pool"
require "http/client"

require "./version"

module HTTPClient
  def self.new(*args, **kwargs)
    Client.new(*args, **kwargs)
  end

  def self.new(*args, **kwargs, &block : -> HTTP::Client)
    Client.new(*args, **kwargs, &block)
  end

  class Client < HTTP::Client
    @pool : DB::Pool(HTTP::Client)
    # HTTP::Client expects these ivars to be set
    @host = ""
    @port = -1

    def self.new(url : String)
      new URI.parse url
    end

    def self.new(uri : URI)
      new { HTTP::Client.new uri }
    end

    def initialize(
      *,
      max_idle_pool_size = 6,
      max_pool_size = 0,
      &block : -> HTTP::Client
    )
      options = DB::Pool::Options.new(
        max_idle_pool_size: max_idle_pool_size,
        max_pool_size: max_pool_size,
      )

      @pool = DB::Pool(HTTP::Client).new(options, &block)
    end

    {% for method in %w[get post put patch delete head options] %}
      def {{method.id}}(*args, as type, **kwargs)
        response = super(*args, **kwargs)
        if response.success?
          type.from_response response.body
        else
          raise RequestError.new(response)
        end
      end
    {% end %}

    def exec(request : HTTP::Request)
      @pool.checkout &.exec request
    end
  end

  class Error < ::Exception
  end

  class RequestError < Error
    @status : HTTP::Status

    def self.new(response : HTTP::Client::Response)
      new response.body, response.status
    end

    def initialize(message, @status)
      super message
    end
  end
end
