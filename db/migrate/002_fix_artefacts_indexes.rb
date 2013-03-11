require "datainsight_recorder/migrations"

migration 2, :fix_artefacts_indexes do
  up do
    execute "alter table artefacts drop index index_artefacts_slug_format"
    create_index :artefacts, :slug, :format, unique: true, name: "unique_index_artefacts_slug_format"

    # NB: remove index info form models
  end

  down do
    execute "alter table artefacts drop index unique_index_artefacts_slug_format"
    create_index :artefacts, :slug, :format, unique: false, name: "index_artefacts_slug_format"
  end
end