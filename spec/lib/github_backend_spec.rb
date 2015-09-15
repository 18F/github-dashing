require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'

describe GithubBackend do
  before do
    ENV['ORG'] = '18F'
    stub_request(:any, /api.github.com/).to_rack(FakeGithubApi)
  end

  describe '.repos_without_about_yml' do
    it 'only returns repos that are missing .about.yml' do
      expect(GithubBackend.new.repos_without_about_yml).to eq ['18F/github-dashing']
    end
  end
end
