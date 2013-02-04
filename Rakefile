require 'rubygems'
require_relative 'lib/model/policy'

unless [ENV["RACK_ENV"], ENV["RAILS_ENV"]].include? "production"
  require 'rspec/core/rake_task'
  require 'ci/reporter/rake/rspec'

  RSpec::Core::RakeTask.new do |task|
    task.pattern = 'spec/**/*_spec.rb'
    task.rspec_opts = ["--format documentation"]
  end
end

require_relative "lib/datamapper_config"

task :init_data_mapper do
  DataMapperConfig.configure
end

namespace :db do
  namespace :migrate do
    desc "Run all pending migrations, or up to specified migration"
    task :up, [:version] => :load_migrations do |t, args|
      if version = args[:version] || ENV['VERSION']
        migrate_up!(version)
      else
        migrate_up!
      end
    end

    desc "Roll back all migrations, or down to specified migration"
    task :down, [:version] => :load_migrations do |t, args|
      if version = args[:version] || ENV['VERSION']
        migrate_down!(version)
      else
        migrate_down!
      end
    end
  end
  task :migrate => "migrate:up"

  task :load_migrations => :init_data_mapper do
    require 'dm-migrations/migration_runner'
    FileList['db/migrate/*.rb'].each do |migration|
      load migration
    end
  end

  desc "Disable policy by slug"
  task :disable_policy, [:slug] => :init_data_mapper do |t, args|
    policy = Policy.first(slug: args[:slug])
    fail("No policy with slug: #{args[:slug]}") if policy.nil?
    policy.update(disabled: true)
  end
end

