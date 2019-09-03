require "open3"
require "tmpdir"

module Rtprov
  class Sftp
    attr_reader :host, :user, :password

    def initialize(host, user, password)
      @host = host.dup.freeze
      @user = user.dup.freeze
      @password = password.dup.freeze
    end

    def get(src)
      Dir.mktmpdir do |dir|
        dest = File.join(dir, File.basename(src))
        run "get #{src} -o #{dest}"
        File.read(dest)
      end
    end

    def put(src, dest)
      run "put #{src} -o #{dest}"
    end

    private
    def run(command)
      # use lftp (instead of sftp) to specify user and password by arguments
      o, e, s = Open3.capture3("lftp", "-u", "#{user},#{password}", "sftp://#{host}", stdin_data: command)
      unless s.success?
        raise "SFTP command `#{command}` failed on #{host} by #{user}: #{e}"
      end
      o
    end
  end
end
