# PrxAuth

[![Gem Version](https://badge.fury.io/rb/prx_auth.svg)](http://badge.fury.io/rb/prx_auth)
[![Dependency Status](https://gemnasium.com/PRX/prx_auth.svg)](https://gemnasium.com/PRX/prx_auth)
[![Build Status](https://travis-ci.org/PRX/prx_auth.svg?branch=master)](https://travis-ci.org/PRX/prx_auth)
[![Code Climate](https://codeclimate.com/github/PRX/prx_auth/badges/gpa.svg)](https://codeclimate.com/github/PRX/prx_auth)
[![Coverage Status](https://coveralls.io/repos/PRX/prx_auth/badge.svg)](https://coveralls.io/r/PRX/prx_auth)

This gem adds middleware to a Rack application that decodes and verified a JSON Web Token (JWT) issued by PRX.org. If the JWT is invalid, the middleware will respond with a 401 Unauthorized. If the JWT was not issued by PRX (or the specified issuer), the request will continue through the middleware stack.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prx_auth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prx_auth

In a non-Rails app, add the following to the application's config.ru file:

```ruby
require 'rack/prx_auth'
use Rack::PrxAuth, cert_location: [CERT LOCATION], issuer: [ISSUER]
```
The `cert_location` and `issuer` parameters are optional. See below.

## Usage

### Utility Classes

Right now, we just have ResourceMap and ScopeList which allow you to work with scopes the way they are handled in the id.prx.org tokens. Resource wildcards and namespaces are supported. By using ResourceMap and ScopeList, you can also perform set arithmetic while handling wildcard semantics.

### Rack::PrxAuth

#### The Request

Rack::PrxAuth looks for a token in the request's HTTP_AUTHORIZATION header. It expects that the header's content will take the form of 'Bearer <your token>'. If no HTTP_AUTHORIZATION header is present, the middlware passes the request to the next middleware.

We have another application that's in charge of making the token. It's called id.prx.org. Its job is to show a form for a user to enter credentials, validate those credentials, and then generate a JWT using PRX's private key. See http://openid.net/specs/openid-connect-implicit-1_0.html to find out what information is encoded in a JWT. Basically it's a hash containing, among other things, the user's ID, the issuer of the token, and when the token expires.

#### Configuration

Rack::PrxAuth takes two optional parameters, `issuer` and `cert_location`. See Installation for how to specify them.

By default, Rack::PrxAuth will assume that you want to make sure the JWT was issued by PRX. After decoding the JWT, Rack::PrxAuth checks the `issuer` field to make sure it's id.prx.org. If you want it to check for a different issuer, pass `issuer: <your issuer>` as a parameter.

Since the JWT was created using PRX's private key, rack-prx_auth needs to fetch PRX's public key to decode it. It does this by accessing the `cert_location` (default is https://id.prx.org/api/v1/certs), generating an OpenSSL::X509::Certificate based on its contents, and determining the public key from the certificate object. Should you wish to get your public key from a different certificate, you may specify a different endpoint by passing `cert_location: <your cert location>` as a parameter. Keep in mind that unless the certificate matches the private key used to make the JWT, Rack::PrxAuth will return 401.

#### The Response

If the token isn't valid, meaning it's expired or it wasn't created using our private key, Rack::PrxAuth will return 401 Unauthorized.

If there's nothing in the HTTP_AUTHORIZATION heading, there's something but JSON::JWT can't decode it, or the issuer field doesn't specify the correct issuer, Rack::PrxAuth just punts to the next piece of middleware.

If all goes well, Rack::PrxAuth takes the decoded JWT and makes a TokenData object. Then it adds this object to the `env` with the key 'prx.auth'.

If you are using Rack::PrxAuth in a Rails app, probably use [prx_auth-rails](https://github.com/PRX/prx_auth-rails) which will automatically install the middlware and add some helpful controller methods.

## Contributing

1. Fork it ( https://github.com/PRX/prx_auth/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
