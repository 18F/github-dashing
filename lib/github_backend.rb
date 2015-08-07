require 'time'
require 'octokit'
require 'ostruct'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'raven'
require_relative 'event'
require_relative 'event_collection'

class GithubBackend
  attr_accessor :logger

  def initialize(_args = {})
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'
  end

  # Returns EventCollection
  def contributor_stats_by_author(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      # Can't limit timeframe
      begin
        stats = request('contributors_stats', [repo]) || []
        next unless stats.is_a?(Array)
        stats.each do |stat|
          stat.weeks.each do |week|
            next unless stat.author
            events << GithubDashing::Event.new(type: 'commits_additions',
                                               key: stat.author.login.dup,
                                               datetime: Time.at(week.w).to_datetime,
                                               value: week.a) if week.a > 0
            events << GithubDashing::Event.new(type: 'commits_deletions',
                                               key: stat.author.login.dup,
                                               datetime: Time.at(week.w).to_datetime,
                                               value: week.d) if week.d > 0
            events << GithubDashing::Event.new(type: 'commits',
                                               key: stat.author.login.dup,
                                               datetime: Time.at(week.w).to_datetime,
                                               value: week.c) if week.c > 0
          end
        end
      rescue Octokit::Error => exception
        Raven.capture_exception(exception)
      end
    end

    events
  end

  # Returns EventCollection
  def issue_comment_count_by_author(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        request('issues_comments', [repo, { since: opts.since }]).each do |issue|
          next unless issue.user
          events << GithubDashing::Event.new(type: 'issues_comments',
                                             key: issue.user.login.dup,
                                             datetime: issue.created_at.to_datetime)
        end
      rescue Octokit::Error => exception
        Raven.capture_exception(exception)
      end
    end

    events
  end

  # Returns EventCollection
  def pull_count_by_author(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        request('pulls', [repo, { state: 'all', since: opts.since }]).each do |pull|
          state_desc = (pull.state == 'open') ? 'opened' : 'closed'
          next unless pull.user
          events << GithubDashing::Event.new(type: "pulls_#{state_desc}",
                                             key: pull.user.login.dup,
                                             datetime: pull.created_at.to_datetime)
        end
      rescue Octokit::Error => exception
        Raven.capture_exception(exception)
      end
    end

    events
  end

  # Returns EventCollection
  def pull_comment_count_by_author(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        request('pulls_comments', [repo, { since: opts.since }]).each do |comment|
          next unless comment.user
          events << GithubDashing::Event.new(type: 'pulls_comments',
                                             key: comment.user.login.dup,
                                             datetime: comment.created_at.to_datetime)
        end
      rescue Octokit::Error => exception
        Raven.capture_exception(exception)
      end
    end

    events
  end

  # Returns EventCollection
  def issue_count_by_author(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        issues = request('issues', [repo, { since: opts.since, state: 'all' }])
        issues.each do |issue|
          next unless issue.user

          # TODO: Attribute to closer, not to issue author
          # state_desc = (issue.state == 'open') ? 'opened' : 'closed'

          events << GithubDashing::Event.new(
            # type: "issues_#{state_desc}",
            type: 'issues_opened',
            key: issue.user.login.dup,
            datetime: issue.created_at.to_datetime)
        end
      rescue Octokit::Error => exception
        Raven.capture_exception(exception)
      end
    end

    events
  end

  # Returns EventCollection
  def issue_count_by_status(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        issues = request('issues', [repo, { since: opts.since, state: 'all' }])

        # Filter to issues in the specified timeframe
        issues.select! do|issue|
          date_at = (issue.state == 'open') ? 'created_at' : 'closed_at'
          issue[date_at].to_datetime > opts.since.to_datetime
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
        Raven.capture_exception(exception)
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
  def pull_count_by_status(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    events = GithubDashing::EventCollection.new
    get_repos(opts).each do |repo|
      begin
        pulls = request('pulls', [repo, { state: 'all', since: opts.since }])
        pulls.select! { |pull| pull.created_at.to_datetime > opts.since.to_datetime }
        pulls.each do |pull|
          state_desc = (pull.state == 'open') ? 'opened' : 'closed'
          events << GithubDashing::Event.new(type: "pull_count_#{state_desc}",
                                             datetime: pull.created_at.to_datetime,
                                             key: pull.state.dup,
                                             value: 1)
        end
      rescue Octokit::Error => exception
        Raven.capture_exception(exception)
      end
    end

    events
  end

  def user(name)
    request('user', [name])
  end

  def repo_stats(_opts)
    # TODO
  end

  def organization_member?(org, user)
    request('organization_member?', [org, user])
  end

  def get_repos(opts)
    opts = OpenStruct.new(opts) unless opts.is_a? OpenStruct
    repos = []
    repos = repos.concat(opts.repos) unless opts.repos.nil?
    unless opts.orgs.nil?
      opts.orgs.each do |org|
        begin
          repos = repos.concat(request('org_repos', [org, { type: 'owner' }]).
                  map { |repo| repo.full_name.dup })
        rescue Octokit::Error => exception
          Raven.capture_exception(exception)
        end
      end
    end

    repos
  end

  # Use a new client for each request, to avoid excessive memory leaks
  # caused by Sawyer middleware (3MB JSON turns into >150MB memory usage)
  def request(method, args)
    client = Octokit::Client.new(
      login: ENV['GITHUB_LOGIN'],
      access_token: ENV['GITHUB_OAUTH_TOKEN']
    )
    result = client.send(method, *args) do|request|
      request.options.timeout = 60
      request.options.open_timeout = 60
    end
    client = nil # rubocop:disable Lint/UselessAssignment
    GC.start
    Octokit.reset!

    result
  end
end
