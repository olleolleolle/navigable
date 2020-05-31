# frozen-string-literal: true

module Navigable
  module Command
    EXECUTE_NOT_IMPLEMENTED_MESSAGE = 'Class must implement `execute` method.'

    def self.extended(base)
      base.class_eval do
        attr_reader :params

        def initialize(request_params = {})
          @params = request_params
        end

        def render(response_params = {})
          Response.new(response_params)
        end

        def execute
          raise NotImplementedError.new(EXECUTE_NOT_IMPLEMENTED_MESSAGE)
        end
      end
    end

    def inherited(child)
      Registrar.new(child, Navigable.app.router).register
    end

    def call(env)
      response = self.new(params(env)).public_send(:execute)
      raise InvalidResponse unless response.is_a?(Navigable::Response)
      response.to_rack_response
    end

    def params(env)
      Params.new(env).to_h
    end

    class Params
      attr_reader :env

      def initialize(env)
        @env = env
      end

      def to_h
        [form_params, body_params, url_params].reduce(&:merge)
      end

      def form_params
        @form_params ||= symbolize_keys(Rack::Request.new(env).params || {})
      end

      def body_params
        @body_params ||= symbolize_keys(env['parsed_body'] || {})
      end

      def url_params
        @url_params ||= env['router.params'] || {}
      end

      def symbolize_keys(hash)
        hash.each_with_object({}) { |(key, value), obj| obj[key.to_sym] = value }
      end
    end
  end
end
