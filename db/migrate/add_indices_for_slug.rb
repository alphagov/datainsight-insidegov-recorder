require "data_mapper"
require "dm-migrations/migration_runner"

migration 5, :add_indices_for_slug do
  up do
    modify_table :content_engagement_visits do
      change_column :slug, String, length: 255
    end
    create_index :artefacts, :slug, :format
    create_index :content_engagement_visits, :slug, :format
  end

  down do
    execute "alter table artefacts drop index index_artefacts_slug_format"
    execute "alter table content_engagement_visits drop index index_content_engagement_visits_slug_format"
    modify_table :content_engagement_visits do
      change_column :slug, 'text'
    end
  end
end

