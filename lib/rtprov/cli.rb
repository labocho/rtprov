require "thor"
require "yaml"

module Rtprov
  class CLI < ::Thor
    desc "new REPO", "Create new rtprov repository"
    def new(name)
      Initializer.run(name)
    end

    desc "edit ROUTER", "Edit router config"
    def edit(router_name)
      Router.edit(router_name)
    end

    desc "show ROUTER", "Show router config"
    def show(router_name)
      puts Router.decrypt(router_name)
    end

    desc "get ROUTER [FILE]", "Get config from router"
    def get(router_name, file = "/system/config0")
      router = Router.load(router_name)
      sftp = Sftp.new(router.host, router.user, router.administrator_password)
      puts sftp.get(file)
    end

    desc "put ROUTER TEMPLATE [FILE]", "Put config from router"
    def put(router_name, template_name = "config0", config_number = 0)
      current_file = "/system/config#{config_number}"
      router = Router.load(router_name)

      template = Template.find(router_name, template_name)
      new_config = template.render(router.variables)

      sftp = Sftp.new(router.host, router.user, router.administrator_password)
      current_config = sftp.get(current_file)
      diff = ENV["RTPROV_DIFF"] || %w(colordiff diff).find {|cmd| system("which", cmd, out: "/dev/null", err: "/dev/null") }

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("new.conf", new_config.gsub(/^#.*$/, "").gsub(/(\r\n|\r|\n)+/, "\r\n"))
          File.write("current.conf", current_config.gsub(/^#.*$/, "").gsub(/(\r\n|\r|\n)+/, "\r\n"))
          system("#{diff} -u current.conf new.conf", out: $stdout, err: $stderr)

          loop do
            print "apply? (y/n): "
            case $stdin.gets.strip
            when "y"
              break
            when "n"
              return nil
            end
          end

          sftp.put("new.conf", current_file)
          Session.start(router) do |s|
            s.exec_with_passwords "load config #{config_number} silent no-key-generate"
          end
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
