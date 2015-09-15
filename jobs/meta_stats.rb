require 'json'
require 'time'
require 'dashing'
require File.expand_path('../../lib/helper', __FILE__)

SCHEDULER.every '1h', first_in: '1s' do |_job|
  backend = GithubBackend.new
  repos = backend.get_repos(
    orgs: (ENV['ORGS'].split(',')),
    repos: (ENV.fetch('REPOS', '').split(',')),
    since: ENV['SINCE']
  )

  # TODO: Move out of widget once I've figured out Sinatra/Batman interaction
  send_event('meta_stats',
             repo_count: repos.length,
             repo_titles: repos.join(', '),
             # :event_count=>stats_raw.data.rows.inject(0) {|c,row|c += row['f'][1]['v'].to_i},
             since: Time.parse(ENV['SINCE']).strftime('%F')
            )
end
