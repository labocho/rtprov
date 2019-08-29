require "thor"
require "yaml"

module Rtprov
  class CLI < ::Thor
    desc "fetch ROUTER", "Fetch config from router"
    def fetch(router)
      router = YAML.load_file("routers/#{router}.yml")

      Session.start(router["user"], router["host"], router["password"]) do |sh|
        puts sh.exec("show config")
      end
    end
  end
end
