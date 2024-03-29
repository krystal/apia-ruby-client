![Welcome](https://share.adam.ac/21/Artboard-Copy-3-NHLb3VEvKfC4DlxRQo.png)

This is a library to faciliate Ruby applications wishing to talk to generic Apia APIs.

## Getting started

```ruby
gem 'apia-client', '~> 2.0'
```

```ruby
# Create a client instance pointing to the API that you wish to connect to.
# By default, it will assume you wish to use SSL and connect on port 443.
api = ApiaClient::API.new('api.example.com')

# Load in the schema from the API if the API supports this
api.load_schema

# Create a request object for the endpoint that you wish to query. You can
# do this by finding it from the API.
request = api.create_request(:post, 'products')

# Set any arguments that you wish to include with the request
request.arguments[:name] = 'My example product'

# Execute the request and get a response back. If there is an issue,
# an exception will be raised here.
begin
  response = request.perform
  response.hash     # => The result
  response.status   # => 200
  response.headers  # => {... headers ...}
  response.request  # => The request object
rescue ApiaClient::RequestError => error
  error.status      # => 404
  error.code        # => 'invalid_route'
  error.description # => 'Description of the error'
  error.detail      # => {... additional details ...}
rescue ApiaClient::CommunicationError => error
  error.message     # => Text describing the communication error
end
```

If you prefer to make a quick API call, you can do so more quickly...

```ruby
api = ApiaClient.load('api.example.com')
api.perform(:get, 'products')
```
