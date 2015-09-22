require 'github_backend'
require 'webmock/rspec'
require 'support/fake_github_api'
require 'support/job_helper'
include JobHelper

describe GithubBackend do
  before do
    github_test_setup
  end

  describe '.repos_without_about_yml' do
    it 'only returns repos that are missing .about.yml' do
      expect(GithubBackend.new.repos_without_about_yml).to eq ['18F/github-dashing']
    end
  end
end
