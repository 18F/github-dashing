require 'dashing'
require File.expand_path('../../lib/travis_backend', __FILE__)

SCHEDULER.every '1d', first_in: '1s' do |_job|
  travis_backend = TravisBackend.new
  github_backend = GithubBackend.new

  testable_repos = github_backend.testable_repos

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

  send_event('testable', unordered: true, items: items)
end
