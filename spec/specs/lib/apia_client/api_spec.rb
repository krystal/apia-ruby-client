# frozen_string_literal: true

require 'spec_helper'

describe ApiaClient::API do
  subject(:api) { described_class.new('api.example.com', namespace: 'v1') }

  context '.load' do
    it 'loads the schema' do
      api = described_class.load('api.example.com', namespace: 'v1')
      expect(api.schema?).to be true
      expect(api.schema).to be_a ApiaSchemaParser::Schema
    end
  end

  context '#ssl?' do
    it 'is true by default' do
      expect(api.ssl?).to be true
    end

    it 'is true if set as such' do
      api = described_class.new('api.example.com', ssl: true)
      expect(api.ssl?).to be true
    end

    it 'is false if set as such' do
      api = described_class.new('api.example.com', ssl: false)
      expect(api.ssl?).to be false
    end
  end

  context '#port' do
    it 'is 80 if no port is selected and SSL is false' do
      api = described_class.new('api.example.com', ssl: false)
      expect(api.port).to eq 80
    end

    it 'is 443 if no port is selected and SSL is true' do
      api = described_class.new('api.example.com', ssl: true)
      expect(api.port).to eq 443
    end

    it 'is whatever is configured in the options' do
      api = described_class.new('api.example.com', port: 8080)
      expect(api.port).to eq 8080
    end
  end

  context '#namespace' do
    it 'is blank if not specified' do
      api = described_class.new('api.example.com', namespace: nil)
      expect(api.namespace).to eq ''
    end

    it 'is whatever is specified in options' do
      api = described_class.new('api.example.com', namespace: 'core/v1')
      expect(api.namespace).to eq 'core/v1'
    end

    it 'does not contain leading slashes' do
      api =  described_class.new('api.example.com', namespace: '/core/v1')
      expect(api.namespace).to eq 'core/v1'
    end

    it 'does not contain trailing slashes' do
      api =  described_class.new('api.example.com', namespace: 'core/v1/')
      expect(api.namespace).to eq 'core/v1'
    end
  end

  context '#load_schema' do
    it 'loads the schema' do
      expect(api.load_schema).to be true
      expect(api.schema).to be_a ApiaSchemaParser::Schema
    end

    it 'marks the schema as loaded' do
      expect(api.load_schema).to be true
      expect(api.schema?).to be true
    end

    it 'raises a connection error if there is a connection error' do
      stub_request(:any, /api.example.com/).to_raise Errno::ECONNREFUSED
      expect { api.load_schema }.to raise_error ApiaClient::ConnectionError
    end

    it 'raise a connection error if there is a timeout' do
      stub_request(:any, /api.example.com/).to_timeout
      expect { api.load_schema }.to raise_error ApiaClient::ConnectionError
    end
  end

  context '#request' do
    it 'returns a response object' do
      request = ApiaClient::Get.new('products')
      expect(api.request(request)).to be_a ApiaClient::Response
    end

    it 'sends arguments for GET requests' do
      request = ApiaClient::Get.new('products/:id')
      request.arguments[:id] = 'macbook'

      response = api.request(request)
      expect(response).to be_a ApiaClient::Response
      expect(response.hash['product']).to eq 'macbook'
    end

    it 'sends arguments for POST requests' do
      request = ApiaClient::Post.new('products')
      request.arguments[:name] = 'sonos'
      response = api.request(request)
      expect(response).to be_a ApiaClient::Response
      expect(response.hash['name']).to eq 'sonos'
    end

    it 'raises an error if theres an error' do
      request = ApiaClient::Get.new('missing-route')
      expect { api.request(request) }.to raise_error ApiaClient::RequestError do |e|
        expect(e.status).to eq 404
        expect(e.code).to eq 'route_not_found'
        expect(e.description).to eq "No route matches 'missing-route' for GET"
      end
    end

    it 'raises a connection error' do
      request = ApiaClient::Get.new('products')
      stub_request(:any, /api.example.com/).to_raise Errno::ECONNREFUSED
      expect { api.request(request) }.to raise_error ApiaClient::ConnectionError
    end
  end

  context '#create_request' do
    it 'raises an error if the schema has not been loaded' do
      expect { api.create_request(:get, 'products') }.to raise_error ApiaClient::SchemaNotLoadedError
    end

    it 'returns an appropriate request instance' do
      api.load_schema
      request = api.create_request(:get, 'products')
      expect(request).to be_a ApiaClient::RequestProxy
      expect(request.request).to be_a ApiaClient::Get
      expect(request.request.path).to eq 'products'
    end

    it 'returns nil if no request matches anything in the schema' do
      api.load_schema
      expect(api.create_request(:get, 'widgets')).to be_nil
    end
  end

  context '#perform' do
    it 'performs a given request' do
      api.load_schema
      response = api.perform(:get, 'products')
      expect(response.hash['products']).to be_a Array
    end

    it 'performs a request executing a block before hand' do
      api.load_schema
      response = api.perform(:get, 'products/:id') do |req|
        req.arguments[:id] = 'airpods'
      end
      expect(response.hash['product']).to eq 'airpods'
    end
  end
end
