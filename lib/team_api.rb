class TeamApi
  def self.testable_repos
    projects = JSON.parse(Faraday.get('https://team-api.18f.gov/public/api/projects/').body)

    projects['results'].select { |p| p['testable'] && p['status'] != 'deprecated' }.
      map { |p| p['github'].first }
  end
end
