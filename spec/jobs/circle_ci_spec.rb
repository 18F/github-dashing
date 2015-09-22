require 'dashing'
require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'
require 'support/job_helper'
include JobHelper

describe 'Circle CI job' do
  before do
    circle_test_setup
  end

  def job
    job_matching('circle_ci')
  end

  it 'runs every 5 minutes' do
    expect(job.schedule_info).to eq '5m'
  end

  it 'starts after 5 minutes' do
    expect(job.next_time).to be_within(1.second).of(5.minutes.from_now)
  end

  it 'calls CircleBackend.get_last_build_for' do
    expect(CircleBackend).
      to receive(:get_last_build_for).with('save-ferris').and_return({})

    job.trigger_block
  end
end
