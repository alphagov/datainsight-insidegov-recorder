# Initial Migration
#
# DO NOT USE THIS AS A TEMPLATE
#
# This is the initial migration after moving away from auto_migrate. It sets
# up tables that may or may not have already been created by auto_migrate.
# Do not use this as a template for subsequent migrations.
#
require "datainsight_recorder/migrations"

migration 1, :create_initial_schema do
  up do
    if adapter.storage_exists?("migration_info")
      # reset data about old migrations
      execute "DELETE FROM migration_info"
    end

    unless adapter.storage_exists?("artefacts")
      create_table :artefacts do
        column :id, "INTEGER(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY" # Integer, serial: true
        column :collected_at, DateTime, allow_nil: false
        column :source, String, allow_nil: false
        column :format, String, allow_nil: false
        column :slug, String, length: 255, allow_nil: false
        column :title, String, length: 255, allow_nil: false
        column :url, String, length: 255, allow_nil: false
        column :organisations, DataMapper::Property::Text, allow_nil: false
        column :artefact_updated_at, DateTime, allow_nil: false
        column :disabled, DataMapper::Property::Boolean, allow_nil: false, default: false
      end
    end

    unless adapter.index_exists?("index_artefacts_slug_format", "artefacts")
      create_index :artefacts, :slug, :format, name: "index_artefacts_slug_format"
    end

    unless adapter.storage_exists?("content_engagement_visits")
      create_table :content_engagement_visits do
        column :id, "INTEGER(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY" # Integer, serial: true
        column :collected_at, DateTime, allow_nil: false
        column :source, String, allow_nil: false
        column :start_at, DateTime, allow_nil: false
        column :end_at, DateTime, allow_nil: false
        column :format, String, allow_nil: false
        column :slug, String, length: 255, allow_nil: false
        column :entries, Integer, allow_nil: false
        column :successes, Integer, allow_nil: false
      end
    end

    unless adapter.index_exists?("index_content_engagement_visits_slug_format", "content_engagement_visits")
      create_index :content_engagement_visits, :slug, :format, name: "index_content_engagement_visits_slug_format"
    end

    unless adapter.storage_exists?("format_visits")
      create_table :format_visits do
        column :id, "INTEGER(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY" # Integer, serial: true
        column :collected_at, DateTime, allow_nil: false
        column :source, String, allow_nil: false
        column :start_at, DateTime, allow_nil: false
        column :end_at, DateTime, allow_nil: false
        column :format, String, allow_nil: false
        column :entries, Integer, allow_nil: false
        column :successes, Integer, allow_nil: false
      end
    end

    unless adapter.storage_exists?("policy_entries")
      create_table :policy_entries do
        column :id, "INTEGER(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY" # Integer, serial: true
        column :collected_at, DateTime, allow_nil: false
        column :source, String, allow_nil: false
        column :start_at, DateTime, allow_nil: false
        column :end_at, DateTime, allow_nil: false
        column :entries, Integer, allow_nil: false
        column :slug, DataMapper::Property::Text, allow_nil: false
      end
    end

    unless adapter.storage_exists?("weekly_reaches")
      create_table :weekly_reaches do
        column :id, "INTEGER(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY" # Integer, serial: true
        column :collected_at, DateTime, allow_nil: false
        column :source, String, allow_nil: false
        column :start_at, DateTime, allow_nil: false
        column :end_at, DateTime, allow_nil: false
        column :metric, String, allow_nil: false
        column :value, Integer, allow_nil: false
      end
    end

  end

  down do
    drop_table :artefacts
    drop_table :content_engagement_visits
    drop_table :format_visits
    drop_table :policy_entries
    drop_table :weekly_reaches
  end
end