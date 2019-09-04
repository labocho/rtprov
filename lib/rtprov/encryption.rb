require "reversible_cryptography"

module Rtprov
  class Encryption
    KEY_FILE = "encryption_key".freeze

    attr_reader :key

    def self.load_key
      ENV["ENCRYPTION_KEY"] || (File.exist?(KEY_FILE) && File.read(KEY_FILE).strip) || raise("ENCRYPTION_KEY env or encryption_key file not found")
    end

    def self.encrypt(plain, key = load_key)
      new(key).encrypt(plain)
    end

    def self.decrypt(encrypted, key = load_key)
      new(key).decrypt(encrypted)
    end

    def self.decrypt_recursive(encrypted, key = load_key)
      new(key).decrypt_recursive(encrypted)
    end

    def self.generate
      SecureRandom.base64(512)
    end

    def initialize(key)
      @key = key.dup.freeze
    end

    def encrypt(plain)
      ReversibleCryptography::Message.encrypt(plain, key)
    end

    def decrypt(encrypted)
      ReversibleCryptography::Message.decrypt(encrypted, key)
    end

    def decrypt_recursive(obj)
      case obj
      when Array
        obj.map {|e| decrypt_recursive(e) }
      when Hash
        return decrypt(obj.values.first) if obj.keys.map(&:to_s) == %w(_encrypted)

        obj.each_with_object({}) do |(k, v), h|
          h[k] = decrypt_recursive(v)
        end
      else
        obj
      end
    end
  end
end
