require 'bundler'
require 'rake'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end
