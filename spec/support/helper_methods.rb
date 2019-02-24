# frozen_string_literal: true

module Faraday
  module HelperMethods
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def features(*features)
        @features = features
      end

      def on_feature(name, &block)
        if @features.nil?
          superclass.on_feature(name, &block) if superclass.respond_to?(:on_feature)
        else
          yield if block_given? and @features.include?(name)
        end
      end

      def method_with_body?(method)
        METHODS_WITH_BODY.include?(method.to_s)
      end
    end

    def ssl_mode?
      ENV['SSL'] == 'yes'
    end

    def normalize(url)
      Faraday::Utils::URI(url)
    end

    def with_default_uri_parser(parser)
      old_parser = Faraday::Utils.default_uri_parser
      begin
        Faraday::Utils.default_uri_parser = parser
        yield
      ensure
        Faraday::Utils.default_uri_parser = old_parser
      end
    end

    def with_env(new_env)
      old_env = {}

      new_env.each do |key, value|
        old_env[key] = ENV.fetch(key, false)
        ENV[key] = value
      end

      begin
        yield
      ensure
        old_env.each do |key, value|
          if value == false
            ENV.delete key
          else
            ENV[key] = value
          end
        end
      end
    end

    def with_env_proxy_disabled
      Faraday.ignore_env_proxy = true

      begin
        yield
      ensure
        Faraday.ignore_env_proxy = false
      end
    end

    def capture_warnings
      old, $stderr = $stderr, StringIO.new
      begin
        yield
        $stderr.string
      ensure
        $stderr = old
      end
    end

    def multipart_file
      Faraday::UploadIO.new(__FILE__, 'text/x-ruby')
    end

    def method_with_body?(method)
      self.class.method_with_body?(method)
    end

    def big_string
      kb = 1024
      (32..126).map{|i| i.chr}.cycle.take(50*kb).join
    end
  end
end