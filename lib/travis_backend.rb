require 'json'
require 'time'
require 'faraday'
require 'logger'

class TravisBackend
  attr_accessor :client, :logger, :api_base

  def initialize
    # TODO: Init HTTP client
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'
    @api_base = 'https://api.travis-ci.org/'
  end

  # Returns all repositories that have Travis builds for a given organization
  def get_enabled_repos_by_org(org)
    fetch("repos?owner_name=#{org}").reject { |repo| repo['last_build_id'].nil? }
  end

  # repo (string) Fully qualified name, incl. owner
  # Returns a single repository as a Hash
  def get_repo(repo)
    fetch("repos/#{repo}")
  end

  # Returns a Hash
  def fetch(path)
    @logger.debug format('Fetching %s%s', @api_base, path)

    conn = Faraday.new @api_base
    response = conn.get path

    # TODO: Better error handling
    response.status == 200 ? JSON.parse(response.body) : false
  end
end
