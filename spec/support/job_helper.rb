module JobHelper
  def job_matching(name)
    SCHEDULER.jobs.values.detect { |job| job.block.to_s.include?(name) }
  end

  def github_orgs_job
    job_matching('github_org_repos')
  end

  def circle_repos_job
    job_matching('active_circle_repos')
  end

  def github_test_setup
    stub_request(:any, /api.github.com/).to_rack(FakeGithubApi)
    github_orgs_job.trigger_block
  end

  def circle_test_setup
    active_circle_test_setup
    circle_repos_job.trigger_block
  end

  def active_circle_test_setup
    stub_request(:any, /circleci.com/).to_rack(FakeCircleApi)
    github_test_setup
  end

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end
end
