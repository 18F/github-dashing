require 'dashing'
require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'
require 'support/job_helper'
include JobHelper

describe 'GitHub Org Repos' do
  before do
    stub_request(:any, /api.github.com/).to_rack(FakeGithubApi)
  end

  def job
    SCHEDULER.jobs.values.
      select { |job| job.block.to_s.include?('github_org_repos') }.first
  end

  it 'runs every 24 hours' do
    expect(job.schedule_info).to eq '1d'
  end

  it 'starts after 50 seconds' do
    expect(job.next_time).to be_within(1.second).of(1.second.from_now)
  end

  it 'calls Octokit.org_repos' do
    expect(Octokit).to receive(:org_repos).with('18F').and_return([])

    job.trigger_block
  end

  it 'sets GITHUB_ORG_REPOS env var to all org repos' do
    job.trigger_block

    expect(ENV['GITHUB_ORG_REPOS']).to eq 'github-dashing,save-ferris'
  end
end
