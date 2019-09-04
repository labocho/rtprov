require "thor"
require "yaml"

module Rtprov
  class CLI < ::Thor
    desc "edit ROUTER", "Edit router config"
    def edit(router_name)
      Router.edit(router_name)
    end

    desc "get ROUTER [FILE]", "Get config from router"
    def get(router_name, file = "/system/config")
      router = Router.load(router_name)
      sftp = Sftp.new(router.host, router.user, router.password)
      puts sftp.get(file)
    end

    desc "put ROUTER TEMPLATE [FILE]", "Put config from router"
    def put(router_name, template_name = "config", file = "/system/config")
      router = Router.load(router_name)

      template = Template.find(router_name, template_name)
      new_config = template.render(router.variables)

      sftp = Sftp.new(router.host, router.user, router.password)
      current_config = sftp.get(file)

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("new.conf", new_config)
          File.write("current.conf", current_config)
          system("colordiff", "-u", "current.conf", "new.conf", out: $stdout, err: $stderr)
          warn "TODO: put, load config and confirm"
        end
      end
    end

    desc "ls", "List routers"
    def ls
      Router.names.each do |name|
        puts name
      end
    end

    desc "ssh ROUTER", "exec ssh to router"
    def ssh(router_name)
      router = Router.load(router_name)
      warn "Password: #{router.password}"
      exec "ssh", "#{router.user}@#{router.host}"
    end
  end
end
