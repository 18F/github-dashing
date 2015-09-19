unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)

  task test: :spec
  task default: :spec
end
