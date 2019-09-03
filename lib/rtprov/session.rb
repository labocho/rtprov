require "expect"
require "pty"
require "shellwords"

module Rtprov
  class Session
    PROMPT = /^> /.freeze

    attr_reader :reader, :writer

    def self.start(user, host, password, &block)
      cmd = [
        "ssh",
        "#{user}@#{host}",
      ].shelljoin

      PTY.getpty(cmd) do |r, w, _pid|
        w.sync = true

        r.expect(/password/)
        w.puts password
        r.expect(/^> /)

        session = new(r, w)
        session.exec("console lines infinity") # disable pager
        session.exec("console columns 200")

        block.call(session)

        w.puts "exit"
      end
    end

    def initialize(reader, writer)
      @reader = reader
      @writer = writer
    end

    def exec(cmd)
      writer.puts cmd
      out, * = reader.expect(PROMPT)

      unless out
        raise "Command `#{cmd}` timed out"
      end

      out.each_line.to_a[1..-2].join # 最初の '> cmd' と最後の '> ' を削除
    end
  end
end
