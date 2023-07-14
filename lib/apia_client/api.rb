# frozen_string_literal: true

require 'net/http'
require 'json'
require 'apia_schema_parser'
require 'apia_client/errors/request_error'
require 'apia_client/errors/connection_error'
require 'apia_client/errors/schema_not_loaded_error'
require 'apia_client/errors/timeout_error'
require 'apia_client/response'
require 'apia_client/request_proxy'

module ApiaClient
  class API

    attr_reader :host
    attr_reader :headers

    def initialize(host, **options)
      @host = host
      @headers = options[:headers] || {}
      @options = options
    end

    def ssl?
      @options[:ssl].nil? || @options[:ssl] == true
    end

    def port
      @options[:port] || (ssl? ? 443 : 80)
    end

    def namespace
      (@options[:namespace] || '').sub(/\A\/*/, '').sub(/\/*\z/, '')
    end

    def schema
      @schema ||= load_schema
    end

    def schema?
      !!@schema
    end

    def load_schema
      response = request(Get.new('schema'))
      ApiaSchemaParser::Schema.new(response.hash)
    end

    def request(request)
      status, headers, body = make_http_request(request) do |req|
        request.add_arguments_to_request(req)
      end
      Response.new(self, request, body, headers, status)
    end

    def perform(*args)
      request = create_request(*args)
      return if request.nil?

      yield request if block_given?
      request.perform
    end

    def create_request(method, path)
      unless schema?
        raise SchemaNotLoadedError, 'No schema has been loaded for this API instance'
      end

      route = schema.api.route_set.routes.find do |r|
        r.request_method == method.to_s.upcase &&
          r.path == path
      end

      return if route.nil?

      RequestProxy.new(self, route)
    end

    private

    def create_http(**options)
      http = Net::HTTP.new(host, port)
      http.use_ssl = ssl?
      http.read_timeout = options[:http_read_timeout] || @options[:http_read_timeout] || 60
      http.open_timeout = options[:http_open_timeout] || @options[:http_open_timeout] || 10
      http
    end

    def make_http_request(request)
      http_request = request.class.method.new("/#{namespace}/#{request.path_for_net_http}")
      @headers.each do |key, value|
        http_request[key] = value
      end
      yield http_request if block_given?
      response = make_request_with_error_handling(http_request, request)
      handle_response(response)
    end

    def make_request_with_error_handling(http_request, request)
      http = create_http(
        http_read_timeout: request.http_read_timeout,
        http_open_timeout: request.http_open_timeout
      )
      http.request(http_request)
    rescue Timeout::Error => e
      raise ApiaClient::TimeoutError, e.message
    rescue StandardError => e
      raise ConnectionError, e.message
    end

    def handle_response(response)
      if response['content-type'] =~ /application\/json/
        body = JSON.parse(response.body)
      else
        body = response.body
      end

      status_code = response.code.to_i
      if status_code >= 200 && status_code < 300
        return [status_code, response.to_hash, body]
      end

      raise RequestError.new(self, status_code, body)
    end

    class << self

      def load(*args, **options)
        new(*args, **options)
      end

    end

  end
end
