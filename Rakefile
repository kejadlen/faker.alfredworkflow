require "rake/testtask"

namespace :workflow do
  desc "Prepare a release, named after the directory"
  task :release, [:version] => [:vendor_check, :tag, :package] do |t, args|
  end

  task :tag, [:version] do |t, args|
    version = args[:version]

    git_status = `git status --porcelain`
    fail <<-FAIL unless git_status.empty?
Can't tag #{version}: dirty working directory.
    FAIL

    sh "git tag #{version}"
  end

  task :package do
    sh "zip -r #{__FILE__.pathmap("%-1d").pathmap("%n.alfredworkflow")} *"
    rm_rf "vendor"
  end

  # Unfortunately, this can't be done automatically due to this chruby issue:
  #   https://github.com/postmodern/chruby/issues/193
  task :vendor_check do
    puts <<-PUTS
Did you remember to vendor your dependencies?

  rm -rf vendor
  chruby-exec 2.0.0 -- bundle install --deployment --standalone

Continue? (y/[n])
    PUTS
    abort if STDIN.gets.chomp.downcase != ?y
  end
end

Rake::TestTask.new do |t|
  t.test_files = FileList["test_*.rb"]
  t.verbose = true
end

task default: :test
