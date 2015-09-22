require 'dashing'
require File.expand_path('../../lib/github_backend', __FILE__)

# This job uses the GitHub API to fetch all repos that do not have an
# `.about.yml` file so we can track adoption.
SCHEDULER.every '1d', first_in: '1m' do |_job|
  github_backend = GithubBackend.new

  repos_without_about_yml = github_backend.repos_without_about_yml

  items = repos_without_about_yml.sort.map do |repo|
    {
      'class' => 'bad',
      'label' => repo,
      'url' => "https://github.com/#{repo}"
    }
  end

  send_event('repos_without_about_yml', unordered: true, items: items)

  total_org_repos = ENV['GITHUB_ORG_REPOS'].split(',').size.to_f
  repos_without_about = repos_without_about_yml.size.to_f
  percentage_adoption = (1 - repos_without_about / total_org_repos) * 100

  send_event('about_percentage', value: percentage_adoption.round(2))
end
