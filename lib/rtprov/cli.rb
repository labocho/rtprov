require "thor"
require "yaml"

module Rtprov
  class CLI < ::Thor
    desc "fetch ROUTER", "Fetch config from router"
    def fetch(router_name)
      router = load_router(router_name)
      Session.start(router["user"], router["host"], router["password"]) do |sh|
        puts sh.exec("show config")
      end
    end

    desc "ssh ROUTER", "exec ssh to router"
    def ssh(router_name)
      router = load_router(router_name)
      warn "Password: #{router["password"]}"
      exec "ssh", "#{router["user"]}@#{router["host"]}"
    end

    private
    def load_router(name)
      YAML.load_file("routers/#{name}.yml")
    end
  end
end
