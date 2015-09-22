require 'dashing'
require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'
require 'support/job_helper'
include JobHelper

describe 'Active Circle CI Repos' do
  before do
    active_circle_test_setup
  end

  def job
    circle_repos_job
  end

  it 'runs every 24 hours' do
    expect(job.schedule_info).to eq '1d'
  end

  it 'starts after 50 seconds' do
    expect(job.next_time).to be_within(1.second).of(50.seconds.from_now)
  end

  it 'calls CircleBackend.get_last_build_for' do
    expect(CircleBackend).
      to receive(:get_last_build_for).ordered.with('github-dashing').and_return({})

    expect(CircleBackend).
      to receive(:get_last_build_for).ordered.with('save-ferris').and_return({})

    job.trigger_block
  end

  it 'sets ACTIVE_CIRCLE_REPOS env var to active repos only' do
    job.trigger_block

    expect(ENV['ACTIVE_CIRCLE_REPOS']).to eq 'save-ferris'
  end
end
