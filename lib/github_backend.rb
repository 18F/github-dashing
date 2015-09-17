require 'time'
require 'octokit'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require_relative 'event'
require_relative 'event_collection'

class GithubBackend
  attr_accessor :logger

  def initialize(_args = {})
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'
  end

  def repos_without_about_yml
    repos = get_repos
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

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # Returns EventCollection
  def issue_count_by_status(opts = {})
    events = GithubDashing::EventCollection.new

    get_repos(opts).each do |repo|
      begin
        issues = Octokit.issues(repo, since: opts.fetch(:since), state: 'all')

        # Filter to issues in the specified timeframe
        issues.select! do|issue|
          date_at = (issue.state == 'open') ? 'created_at' : 'closed_at'
          issue[date_at].to_datetime > opts.fetch(:since).to_datetime
        end

        # Reject all opened issues which are in fact pull requests.
        # They shouldn't count against this negative value.
        issues.reject! do|issue|
          issue.pull_request.html_url if issue.pull_request && issue.state == 'open'
        end

        issues.each do |issue|
          state_desc = (issue.state == 'open') ? 'opened' : 'closed'
          events << GithubDashing::Event.new(type: "issue_count_#{state_desc}",
                                             datetime: datetime_for_issue(issue),
                                             key: issue.state.dup,
                                             value: 1)
        end
      rescue Octokit::Error => exception
        logger.debug("Octokit exception: #{exception}")
      end
    end

    events
  end

  def datetime_for_issue(issue)
    return issue.created_at.to_datetime if issue.state == 'open'
    issue.closed_at.to_datetime
  end

  # TODO: Break up by actual status, currently not looking at closed_at date
  #
  # Returns EventCollection
  def pull_count_by_status(opts = {})
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        pulls = Octokit.pulls(repo, state: 'all', since: opts.fetch(:since))
        pulls.select! { |pull| pull.created_at.to_datetime > opts.fetch(:since).to_datetime }
        pulls.each do |pull|
          state_desc = (pull.state == 'open') ? 'opened' : 'closed'
          events << GithubDashing::Event.new(type: "pull_count_#{state_desc}",
                                             datetime: pull.created_at.to_datetime,
                                             key: pull.state.dup,
                                             value: 1)
        end
      rescue Octokit::Error => exception
        logger.debug("Octokit exception: #{exception}")
      end
    end

    events
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def get_repos(opts = {})
    repos = []
    repos = repos.concat(opts.fetch(:repos, []))

    repos.concat(Octokit.org_repos(ENV['ORG']).map(&:full_name))
  rescue Octokit::Error => exception
    logger.debug("Octokit exception: #{exception}")
  end
end
