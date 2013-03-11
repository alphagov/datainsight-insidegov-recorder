require 'rubygems'
require_relative 'lib/model/artefact'

unless [ENV["RACK_ENV"], ENV["RAILS_ENV"]].include? "production"
  require 'rspec/core/rake_task'
  require 'ci/reporter/rake/rspec'

  RSpec::Core::RakeTask.new do |task|
    task.pattern = 'spec/**/*_spec.rb'
    task.rspec_opts = ["--format documentation"]
  end
end

task :init_data_mapper do
  DataInsight::Recorder::DataMapperConfig.configure
end

namespace :db do
  desc "Disable policy by slug"
  task :disable_policy, [:slug] => :init_data_mapper do |t, args|
    policy = Artefact.first(slug: args[:slug], format: "policy")
    fail("No policy with slug: #{args[:slug]}") if policy.nil?
    policy.update(disabled: true)
  end
end

require "datainsight_recorder/rake_tasks"
