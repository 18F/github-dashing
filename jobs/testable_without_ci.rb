require 'dashing'
require File.expand_path('../../lib/travis_backend', __FILE__)

# This job uses the 18F Team API to fetch all repos whose `testable`
# key is set to `true` in their .about.yml. Then, the Travis API is
# used to get each repo in that list, and if the repo doesn't have a
# build running on Travis, it gets included in the widget on the dashboard.
# The goal is to display repos that should have tests running on some CI
# server, but don't.
SCHEDULER.every '1d', first_in: '1s' do |_job|
  travis_backend = TravisBackend.new
  testable_repos = TeamApi.testable_repos

  travis_repos = testable_repos.map { |repo| travis_backend.get_repo(repo) }
  repos_without_builds = travis_repos.select { |repo| repo['last_build_id'].nil? }
  ignored_repos = ENV['TRAVIS_IGNORED_REPOS'].split(',').compact

  items = repos_without_builds.map do |repo|
    {
      'class' => 'bad',
      'label' => repo['slug'],
      'url' => "https://github.com/#{repo['slug']}"
    }
  end

  items.delete_if { |item| ignored_repos.include?(item['label']) }

  items.sort_by! { |item| [1, item['label']] }

  send_event('testable_without_ci', unordered: true, items: items)
end
