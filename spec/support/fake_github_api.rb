require 'sinatra/base'

class FakeGithubApi < Sinatra::Base
  get '/repos/18F/github-dashing/contents/.about.yml' do
    json_response 404, 'repo_without_about_yml.json'
  end

  get '/repos/18F/save-ferris/contents/.about.yml' do
    json_response 200, 'repo_with_about_yml.json'
  end

  get '/orgs/18F/repos' do
    json_response 200, 'org_repos.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end
end
