require 'sinatra/base'
require 'support/job_helper'
include JobHelper

class FakeCircleApi < Sinatra::Base
  get '/api/v1/project/18F/github-dashing' do
    json_response 404, 'repo_without_circle_build.json'
  end

  get '/api/v1/project/18F/save-ferris' do
    json_response 200, 'repo_with_circle_build.json'
  end
end
