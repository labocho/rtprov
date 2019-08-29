require "rtprov/version"

module Rtprov
  class Error < StandardError; end

  require_relative "rtprov/cli"
  require_relative "rtprov/session"
end
