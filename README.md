# `HTTPClient`

A HTTP client that transparently pools connections. You can use it anywhere you would use an [`HTTP::Client`](https://crystal-lang.org/api/1.13.1/HTTP/Client.html) because it *is* an `HTTP::Client`.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     http_client:
       github: jgaskins/http_client
   ```

2. Run `shards install`

## Usage

```crystal
require "http_client"

http = HTTPClient.new(URI.parse("https://api.example.com"))

http.get "/"
# => #<HTTP::Client::Response:...>
```

### OAuth

Using a pooled HTTP client allows you to use a single `OAuth2::Client` instance for your entire app.

```crystal
require "oauth2"
require "http_client"

EXAMPLE_OAUTH2 = OAuth2::Client.new(
  host: "api.example.com",
  client_id: ENV["OAUTH2_CLIENT_ID"],
  client_secret: ENV["OAUTH2_CLIENT_SECRET"],
  redirect_uri: ENV["OAUTH2_REDIRECT_URI"],
)
EXAMPLE_OAUTH2.http_client = HTTPClient.new("https://api.example.com")
```

## Contributing

1. Fork it (<https://github.com/jgaskins/http_client/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
