module Rtprov
  class Router
    ATTRIBUTES = %w(host user password variables).map(&:freeze).freeze

    attr_reader :name, *ATTRIBUTES

    def self.load(name)
      new(name, YAML.load_file("routers/#{name}.yml"))
    end

    def initialize(name, attributes)
      @name = name
      Encryption.decrypt_recursive(attributes).each do |k, v|
        ATTRIBUTES.include?(k) || raise("Unknown attribute found `#{k}`")
        instance_variable_set "@#{k}", v
      end
    end
  end
end
