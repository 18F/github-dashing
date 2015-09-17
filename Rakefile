require 'bundler'
Bundler::GemHelper.install_tasks

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)

  task test: :spec
  task default: :spec
end
