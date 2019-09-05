require "expect"
require "pty"
require "shellwords"

module Rtprov
  class Session
    attr_reader :router, :reader, :writer, :prompt_prefix, :prompt_pattern

    def self.start(router, &block)
      cmd = [
        "ssh",
        "#{router.user}@#{router.host}",
      ].shelljoin

      PTY.getpty(cmd) do |r, w, _pid|
        w.sync = true

        r.expect(/password/)
        w.puts router.password
        prompt_prefix = r.expect(/^(.*)> /)[1]

        session = new(router, r, w, prompt_prefix, ">")
        session.exec("console character en.ascii")
        session.exec("console lines infinity") # disable pager
        session.exec("console columns 200")

        session.as_administrator(&block)

        w.puts "exit"
      end
    end

    def initialize(router, reader, writer, prompt_prefix, prompt_suffix)
      @router = router
      @reader = reader
      @writer = writer
      @prompt_prefix = prompt_prefix.dup.freeze
      @prompt_pattern = Regexp.compile("^" + Regexp.escape(prompt_prefix) + "[a-z1-9]*" + prompt_suffix + " ").freeze
    end

    def exec(cmd)
      writer.puts cmd
      out, * = reader.expect(prompt_pattern)

      unless out
        raise "Command `#{cmd}` timed out"
      end

      out.each_line.to_a[1..-2].join # remove first line like '> cmd' and last line line '> '
    end

    def exec_with_passwords(cmd)
      writer.puts cmd

      reader.expect(/^Login Password: /)
      writer.puts router.anonymous_password

      reader.expect(/^Administrator Password: /)
      writer.puts router.administrator_password

      writer.puts "console prompt '#{prompt_prefix}'" # load config may change prompt prefix
      out, * = reader.expect(prompt_pattern)

      unless out
        raise "Command `#{cmd}` timed out"
      end

      out.each_line.to_a[1..-2].join # remove first line like '> cmd' and last line line '> '
    end

    def as_administrator(&block)
      writer.puts "administrator"
      reader.expect(/Password: /)
      writer.puts router.administrator_password
      reader.expect(/^.*# /)

      begin
        # set new prompt because default administrator prompt "# " matches config file comment etc.
        session = self.class.new(router, reader, writer, "RTPROV", "#")
        session.exec "console prompt RTPROV"
        block.call(session)
      ensure
        writer.puts "console prompt '#{prompt_prefix}'"
        reader.expect(/^.*# /)
      end

      writer.puts "exit"
      reader.expect "Save new configuration ? (Y/N)"
      writer.puts "Y"
      reader.expect(prompt_pattern)
    end
  end
end
