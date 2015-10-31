require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*test.rb'
end

require "rubocop/rake_task"
RuboCop::RakeTask.new(:analyze)

task checks: [:test, :analyze]
task default: :checks
