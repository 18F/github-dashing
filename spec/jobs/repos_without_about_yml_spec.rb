require 'dashing'
require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'
require 'support/job_helper'
include JobHelper

describe 'repos_without_about_yml' do
  before do
    github_test_setup
  end

  def job
    SCHEDULER.jobs.values.
      select { |job| job.block.to_s.include?('repos_without_about_yml') }.first
  end

  def app
    Sinatra::Application
  end

  it 'runs every 24 hours' do
    expect(job.schedule_info).to eq '1d'
  end

  it 'starts after 1 minute' do
    expect(job.next_time).to be_within(1.second).of(1.minute.from_now)
  end

  it 'calls GithubBackend.repos_without_about_yml' do
    expect_any_instance_of(GithubBackend).to receive(:repos_without_about_yml).and_return([])

    job.trigger_block
  end

  it 'calls send_event with expected items' do
    skip 'need help testing this'
  end
end
