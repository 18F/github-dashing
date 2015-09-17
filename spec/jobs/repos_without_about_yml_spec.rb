require 'dashing'
require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'

describe 'repos_without_about_yml' do
  before do
    ENV['ORG'] = '18F'
    stub_request(:any, /api.github.com/).to_rack(FakeGithubApi)
  end

  let(:job) do
    SCHEDULER.jobs.values.
      select { |job| job.block.to_s.include?('repos_without_about_yml') }.first
  end

  def app
    Sinatra::Application
  end

  it 'runs every 24 hours' do
    expect(job.frequency).to eq(24 * 3600)
  end

  it 'calls GithubBackend.repos_without_about_yml' do
    expect_any_instance_of(GithubBackend).to receive(:repos_without_about_yml).and_return([])

    job.trigger_block
  end

  it 'calls send_event with expected items' do
    skip 'need help testing this'
  end
end
