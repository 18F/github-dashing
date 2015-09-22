require 'dashing'

# This job runs once a day to store the list of all GitHub repos for an org
# in an env var. That way, it can be reused by other widgets without having
# to make more API calls.
SCHEDULER.every '1d', first_in: '1s' do |_job|
  org = ENV['ORG']
  org_repos = Octokit.org_repos(org).map(&:name)

  ENV['GITHUB_ORG_REPOS'] = org_repos.join(',')
end
