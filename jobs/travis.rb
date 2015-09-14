require 'dashing'
require File.expand_path('../../lib/travis_backend', __FILE__)

def class_from(build_status)
  (build_status.nil? || build_status == 1) ? 'bad' : 'good'
end

SCHEDULER.every '2m', first_in: '1s' do |_job|
  travis_backend = TravisBackend.new
  enabled_repos = []
  ignored_repos = ENV['TRAVIS_IGNORED_REPOS'].split(',').compact

  ENV['ORGS'].split(',').each do |org|
    enabled_repos = travis_backend.get_enabled_repos_by_org(org)
  end

  items = enabled_repos.map do |repo|
    {
      'class' => class_from(repo['last_build_status']),
      'label' => repo['slug'],
      'title' => repo['last_build_finished_at'],
      'url' => "https://travis-ci.org/#{repo['slug']}/builds/#{repo['last_build_id']}"
    }
  end

  items.delete_if { |item| ignored_repos.include?(item['label']) }

  # Sort by name, then by status
  items.sort_by! do |item|
    if item['class'] == 'bad'
      [1, item['label']]
    elsif item['class'] == 'good'
      [2, item['label']]
    else
      [3, item['label']]
    end
  end

  send_event('travis', unordered: true, items: items)
end
