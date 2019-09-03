require "erb"

module Rtprov
  class Template
    class RenderingContext
      def initialize(local_vars)
        local_vars.transform_values! {|v| hash_with_accessor(v) }
        local_vars.each do |k, v|
          binding.local_variable_set(k.to_sym, v)
        end
      end

      def binding
        @binding ||= super
      end

      private
      # define key name method for hash recursively
      def hash_with_accessor(obj)
        case obj
        when Array
          obj.map {|e| hash_with_accessor(e) }
        when Hash
          obj.each_with_object({}) do |(k, v), h|
            h[k] = hash_with_accessor(v)
            h.singleton_class.define_method k do
              fetch(k)
            end
          end
        else
          obj
        end
      end
    end

    def self.find(router, name)
      candidates = [
        "templates/#{router}/#{name}.erb",
        "templates/#{name}.erb",
      ]

      candidates.find do |candidate|
        return new(File.read(candidate)) if File.exist?(candidate)
      end

      raise "Template `#{name}` not found in #{candidates.inspect}"
    end

    def initialize(source)
      @erb = ERB.new(source, trim_mode: "-")
    end

    def render(variables)
      context = RenderingContext.new(variables)
      @erb.result(context.binding)
    end
  end
end
