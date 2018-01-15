module Flowhook
  # The streaming client for Flowdock API
  class Streaming
    STREAMING_URL = 'https://stream.flowdock.com/flows'.freeze

    def initialize(token, use_private = false, flows = [], events = [])
      @token = token
      @flows = flows
      @private = use_private ? 1 : 0
      @events = events
      @queue = Queue.new
      @thread = nil
      @stop = false
    end

    def stop?
      @stop == true
    end

    def stop!
      @stop = true
    end

    def read(&_block)
      ensure_connection
      until stop?
        yield @queue.pop(true) until @queue.empty?
        # NOOP
      end
    end

    private

    def ensure_connection
      return if @thread
      @thread ||= Thread.new { streaming }
    end

    def queue(chunk)
      chunk.chomp!
      return if chunk.empty?
      event = JSON.parse(chunk)
      @queue.push event if @events.empty? || @events.include?(event['event'])
    end

    def streaming
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request request do |response|
          response.read_body do |chunk|
            queue chunk
          end
        end
      end
    end

    def request
      @request ||= Net::HTTP::Get.new(uri).tap do |request|
        request.basic_auth @token, nil
      end
    end

    def uri
      @uri ||= URI("#{STREAMING_URL}?filter=#{@flows.join(',')}").tap do |uri|
        uri.query += 'active=true' # TODO: Add options  can change state
        uri.query += '&user=1' if @private
      end
    end
  end
end
