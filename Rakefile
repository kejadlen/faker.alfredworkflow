require "rake/testtask"

require "alphred/tasks"

Rake::TestTask.new do |t|
  t.test_files = FileList["test_*.rb"]
  t.verbose = true
end

task default: :test

desc "Vendor dependencies"
task :vendor do
  sh "bundle --standalone --path vendor/bundle --without development test"
end
