require 'time'
require 'octokit'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require_relative 'event'
require_relative 'event_collection'

class GithubBackend
  attr_accessor :logger, :start_date, :repos

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'
    @start_date = ENV['SINCE']
    @repos = Octokit.org_repos(ENV['ORG']).map(&:full_name)
  end

  def repos_without_about_yml
    missing_repos = []

    repos.each do |repo|
      begin
        Octokit.contents(repo, path: '.about.yml')
      rescue Octokit::NotFound
        missing_repos << repo
      end
    end

    missing_repos
  end

  # rubocop:disable Metrics/MethodLength
  # Returns EventCollection
  def issue_count_by_status
    events = GithubDashing::EventCollection.new

    repos.each do |repo|
      begin
        issues = Octokit.issues(repo, since: start_date, state: 'all')

        next if issues.empty?

        issues.each do |issue|
          issue_type = issue.respond_to?(:pull_request) ? 'pull_request' : 'issue'
          events << GithubDashing::Event.new(type: issue_type,
                                             datetime: datetime_for_issue(issue),
                                             key: issue.state,
                                             value: 1)
        end
      rescue Octokit::Error => exception
        logger.debug("Octokit exception: #{exception}")
      end
    end

    events
  end
  # rubocop:enable Metrics/MethodLength

  def datetime_for_issue(issue)
    return issue.created_at.to_datetime if issue.state == 'open'
    issue.closed_at.to_datetime
  end
end
