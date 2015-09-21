require 'circle_backend'
require 'webmock/rspec'
require 'support/fake_circle_api'
require 'support/job_helper'
include JobHelper

describe CircleBackend do
  before do
    stub_request(:any, /circleci.com/).to_rack(FakeCircleApi)
  end

  describe '.get_last_build_for' do
    context 'the repo has a build on Circle CI' do
      it 'only returns the last build' do
        expect(CircleBackend.get_last_build_for('save-ferris')).
          to eq JSON.parse(contents_for('repo_with_circle_build.json'))[0]
      end
    end

    context 'the repo does not have a build on Circle CI' do
      it 'returns an empty array' do
        expect(CircleBackend.get_last_build_for('github-dashing')).to eq []
      end
    end
  end

  def contents_for(file_name)
    File.read("spec/support/fixtures/#{file_name}", mode: 'rb')
  end
end
