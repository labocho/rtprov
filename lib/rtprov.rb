require "rtprov/version"

module Rtprov
  class Error < StandardError; end

  require_relative "rtprov/cli"
  require_relative "rtprov/session"
  require_relative "rtprov/sftp"
end
