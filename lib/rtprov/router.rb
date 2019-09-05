require "tmpdir"
require "shellwords"

module Rtprov
  class Router
    ATTRIBUTES = %w(host user password administrator_password anonymous_password variables).map(&:freeze).freeze

    attr_reader :name, *ATTRIBUTES

    def self.edit(name)
      encrypted_file = "routers/#{name}.yml.enc"
      decrypted = if File.exist?(encrypted_file)
        Encryption.decrypt(File.read(encrypted_file))
      else
        <<~YAML
          host: 127.0.0.1
          user: admin
          password: opensesame
          administrator_password: opensesame
          anonymous_password: anonymous_password
          variables: {}
        YAML
      end

      Dir.mktmpdir do |dir|
        temp = "#{dir}/#{name}.yml"
        File.write(temp, decrypted)

        if system("#{editor} #{temp.shellescape}", out: $stdout, err: $stderr)
          encrypted = Encryption.encrypt(File.read(temp))
          File.write(encrypted_file, encrypted)
          warn "Saved to #{encrypted_file}"
        else
          warn "Not saved"
        end
      end
    end

    def self.editor
      return ENV["RTPROV_EDITOR"] if ENV["RTPROV_EDITOR"]

      # rubocop: disable Lint/HandleExceptions
      begin
        o, _e, s = Open3.capture3("git config core.editor")
        return o.strip if s.success?
      rescue Errno::ENOENT
      end
      # rubocop: enable Lint/HandleExceptions

      ENV["EDITOR"]
    end

    def self.decrypt(name)
      Encryption.decrypt(File.read("routers/#{name}.yml.enc"))
    end

    def self.names
      Dir["routers/*.yml.enc"].map {|path|
        File.basename(path).gsub(/\.yml\.enc\z/, "")
      }.sort
    end

    def self.load(name)
      new(name, YAML.safe_load(decrypt(name)))
    end

    def initialize(name, attributes)
      @name = name

      attributes.each do |k, v|
        ATTRIBUTES.include?(k) || raise("Unknown attribute found `#{k}`")
        instance_variable_set "@#{k}", v
      end
    end
  end
end
