require 'dashing'
require File.expand_path('../../lib/circle_backend', __FILE__)

def class_from(build_status)
  build_status == true ? 'bad' : 'good'
end

def priority_for(item)
  item['class'] == 'bad' ? 1 : 2
end

SCHEDULER.every '5m', first_in: '5m' do |_job|
  org = ENV['ORG']
  active_circle_repos = ENV['ACTIVE_CIRCLE_REPOS'].split(',')
  circle_builds = active_circle_repos.map { |repo| CircleBackend.get_last_build_for(repo) }

  items = circle_builds.map do |repo|
    {
      'class' => class_from(repo['failed']),
      'label' => "#{org}/#{repo['reponame']}",
      'url' => repo['build_url']
    }
  end

  items.sort_by! { |item| [priority_for(item), item['label']] }

  send_event('circle', unordered: true, items: items)
end
