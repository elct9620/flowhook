module Flowhook
  # rubocop:disable Metrics/LineLength
  # The option parser
  class Options < OptionParser
    attr_reader :options

    def initialize
      super

      prepare_options
      setup_options
    end

    def parse!(args = ARGV)
      super
      options
    end

    private

    def setup_options
      %w[url path token flows events daemonize help version].each do |option|
        send("setup_#{option}_option")
      end
    end

    def setup_url_option
      on('-u', '--url URL', String, 'The webhook url to send event') do |url|
        options.url = url
      end
    end

    def setup_path_option
      on('-p', '--path PATH', String, 'The path saving pid and logs') do |path|
        options.path = path
      end
    end

    def setup_token_option
      on('-t', '--token TOKEN', String, 'The personal token to access messages') do |token|
        options.token = token
      end
    end

    def setup_flows_option
      on('-F', '--flows FLOW1, FLOW2', Array, 'The flows wants to straming') do |flows|
        options.flows = flows
      end
    end

    def setup_events_option
      on('-E', '--events EVENT1, EVENT2', Array, 'The events want to straming') do |events|
        options.events = events
      end
    end

    def setup_daemonize_option
      on('-d', '--[no-]daemonize', 'Daemonize the process') do |daemonize|
        options.daemonize = daemonize
      end
    end

    def setup_help_option
      on_tail('-h', '--help', 'Show this message') do
        puts self
        exit
      end
    end

    def setup_version_option
      on_tail('--version', 'Show version') do
        puts VERSION
        exit
      end
    end

    def prepare_options
      @options = OpenStruct.new
      options.path = Dir.pwd
      options.url = nil
      options.token = nil
      options.flows = []
      options.events = []
      options.daemonize = false
    end
  end
end
# rubocop:enable Metrics/LineLength
