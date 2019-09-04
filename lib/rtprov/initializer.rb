require "fileutils"
require "open3"
require "shellwords"

module Rtprov
  class Initializer
    include FileUtils::Verbose

    attr_reader :name

    def self.run(name)
      new(name).run
    end

    def initialize(name)
      @name = name.dup.freeze
    end

    def run
      raise "Already exists #{name} directory" if File.exist?(name)

      mkdir name
      Dir.chdir(name) do
        mkdir "routers"
        touch "routers/.keep"

        mkdir "templates"
        touch "templates/.keep"

        puts "Create encryption_key"
        key = Encryption.generate_key
        File.write("encryption_key", key)

        exec "bundle init"
        exec "bundle add rtprov -v #{VERSION}"
        exec "bundle binstubs rtprov"

        puts "Create .gitignore"
        gitignore = <<~EOS
          /encryption_key
        EOS

        exec "git init"
        exec "git add ."
      end

      puts <<~EOS

        ============================================================
        !!! Please remember `encryption_key`. Git ignores it. !!!
        ============================================================

        And do below.
        1. cd #{name}
        2. bin/rtprov edit YOUR_ROUTER_NAME
        3. bin/rtprov get YOUR_ROUTER_NAME > tempaltes/config.erb
        4. Extract credentials in templates/config.erb
      EOS
    end

    private
    def exec(cmd, *args)
      puts "#{cmd} #{args.shelljoin}"

      o, e, s = Open3.capture3(cmd, *args)

      unless s.success?
        warn e
        raise "`#{cmd} #{args.shelljoin}` failed"
      end

      o
    end
  end
end
