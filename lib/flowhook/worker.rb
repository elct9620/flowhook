module Flowhook
  # The worker to sending webhook
  class Worker
    def initialize(options)
      @options = options
      @pidfile = File.expand_path('flowhook.pid')

      initialize_stream
    end

    def start
      check_pid
      daemonize if daemonize?
      write_pid
      trap_signals

      @stream.read do |event|
        # TODO: Logging response
        Thread.new { send event }
      end
    end

    def daemonize?
      @options.daemonize
    end

    def pidfile?
      !@pidfile.nil?
    end

    private

    # TODO: Refactor PID manager: https://codeincomplete.com/posts/ruby-daemons/
    def check_pid
      return unless pidfile?
      case pid_status(@pidfile)
      when :running, :not_owned
        puts "Worker is running. Check #{@pidfile}"
        exit 1
      when :dead
        File.delete(@pidfile)
      end
    end

    def write_pid
      return unless pidfile?
      File.write(@pidfile, Process.pid)
      at_exit { File.delete(@pidfile) if File.exist?(@pidfile) }
    rescue Errno::EEXIST
      check_pid
      retry
    end

    def pid_status(pidfile)
      return :exited unless File.exist?(pidfile)
      pid = File.read(pidfile).to_i
      return :dead if pid.zero?
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    def daemonize
      exit if fork
      Process.setsid
      exit if fork
      Dir.chdir '/'
    end

    def trap_signals
      trap :QUIT do
        @stream.stop!
      end

      trap :SIGINT do
        @stream.stop!
      end
    end

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
        @options.private,
        @options.flows,
        @options.events
      )
    end
  end
end
