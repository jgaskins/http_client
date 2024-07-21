require "json"

module HTTPClient
  struct JSON(T)
    def self.from_response(response)
      T.from_json(response)
    end
  end
end
