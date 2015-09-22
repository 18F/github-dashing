require 'dashing'
require File.expand_path('../../lib/circle_backend', __FILE__)

# This job runs once a day to store the list of active Circle CI repos in an
# env var. That way, it can be reused by the Circle CI widget without having
# to make hundreds of API calls.
#
# The Circle CI API does not currently provide a way to get a list of just
# the active repos, so we have to use the GitHub API to get a list of all
# repos that belong to an organization, then make a separate Circle API call
# for each one (over 300 for 18F), just to determine whether Circle CI has
# builds for that repo.
SCHEDULER.every '1d', first_in: '50s' do |_job|
  org_repos = ENV['GITHUB_ORG_REPOS'].split(',')

  circle_builds = org_repos.flat_map { |repo| CircleBackend.get_last_build_for(repo) }.compact

  active_circle_repos = circle_builds.map { |build| build['reponame'] }

  ENV['ACTIVE_CIRCLE_REPOS'] = active_circle_repos.join(',')
end
