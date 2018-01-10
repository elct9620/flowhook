require 'pp'

module Flowhook
  # The worker to sending webhook
  class Worker
    def initialize(options)
      @options = options

      initialize_stream
    end

    def start
      @stream.read do |event|
        # TODO: Logging response
        Thread.new { send event }
      end
    end

    private

    def send(event)
      use_ssl = uri.scheme == 'https'
      Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
        http.request make_request(event)
      end
    end

    def make_request(event)
      Net::HTTP::Post.new(uri).tap do |request|
        request.body = event.to_json
        request.content_type = 'application/json'
      end
    end

    def uri
      @uri ||= URI(@options.url)
    end

    def initialize_stream
      @stream = Streaming.new(
        @options.token,
        @options.flows,
        @options.events
      )
    end
  end
end
