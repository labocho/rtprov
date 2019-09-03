require "thor"
require "yaml"

module Rtprov
  class CLI < ::Thor
    desc "fetch ROUTER [FILE]", "Fetch config from router"
    def fetch(router_name, file = "/system/config")
      router = load_router(router_name)
      sftp = Sftp.new(router["host"], router["user"], router["password"])
      puts sftp.get(file)
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
