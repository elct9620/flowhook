require 'optparse'
require 'ostruct'

require 'flowhook/version'

# Flowdock Streaming to Webhook
module Flowhook
  autoload :Streaming, 'flowhook/streaming'
  autoload :Worker, 'flowhook/worker'
  autoload :Options, 'flowhook/options'

  def self.start
    options = Options.new.parse!
    Worker.new(options).start
  end
end
