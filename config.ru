require 'dashing'
require 'faraday'
require 'faraday/http_cache'
require 'time'
require 'yaml'
require 'time'
require 'active_support'
require 'active_support/core_ext'
require 'json'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

fail('ORG environment variable is not set!') if ENV['ORG'].nil?

# Persist on disk, don't exceed heroku memory limit
stack = Faraday::RackBuilder.new do |builder|
  store = ActiveSupport::Cache.lookup_store(:file_store, [Dir.pwd + '/tmp'])
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'
  builder.use :http_cache, store: store, logger: logger, shared_cache: false, serializer: Marshal
  builder.use Octokit::Response::RaiseError
  builder.request :retry
  builder.adapter :typhoeus

end
Octokit.middleware = stack

# Verbose logging in Octokit
Octokit.configure do |config|
  config.middleware.response :logger unless ENV['RACK_ENV'] == 'production'
  config.access_token = ENV['GITHUB_OAUTH_TOKEN']
end

Octokit.auto_paginate = true

ENV['SINCE'] ||= '12.months.ago.beginning_of_month'
ENV['SINCE'] = DateTime.iso8601(ENV['SINCE']).to_s rescue eval(ENV['SINCE']).to_s

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'
  set :environment, ENV['RACK_ENV']
  disable :protection

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
