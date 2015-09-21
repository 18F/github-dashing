require 'faraday'
require 'json'

class CircleBackend
  def self.get_last_build_for(repo)
    fetch("project/#{ENV['ORG']}/#{repo}?circle_token=#{ENV['CIRCLE_CI_TOKEN']}")
  end

  def self.fetch(path)
    conn = Faraday.new('https://circleci.com/api/v1/')
    response = conn.get path

    response.status == 200 ? JSON.parse(response.body)[0] : []
  end
end
