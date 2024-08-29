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
      options = DB::Pool::Options.from_http_params(uri.query_params)
      new(options) { HTTP::Client.new uri }
    end

    def self.new(
      *,
      max_idle_pool_size = 6,
      max_pool_size = 0,
      checkout_timeout : Time::Span = 5.seconds,
      &block : -> HTTP::Client
    )
      options = DB::Pool::Options.new(
        max_idle_pool_size: max_idle_pool_size,
        max_pool_size: max_pool_size,
        # I don't like that DB::Pool::Options takes durations as scalars.
        checkout_timeout: checkout_timeout.total_seconds,
      )

      new options, &block
    end

    # :nodoc:
    def initialize(options : DB::Pool::Options, &block : -> HTTP::Client)
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
      @before_request.try &.each &.call(request)
      @pool.checkout &.exec request
    rescue ex : DB::Error
      raise Error.new(ex.message, cause: ex)
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
