require "datainsight_recorder/migrations"

migration 2, :fix_artefacts_indexes do
  up do
    adapter.drop_index "artefacts", "index_artefacts_slug_format"
    create_index :artefacts, :slug, :format, unique: true, name: "unique_index_artefacts_slug_format"

    # NB: remove index info form models
  end

  down do
    adapter.drop_index "artefacts", "unique_index_artefacts_slug_format"
    create_index :artefacts, :slug, :format, unique: false, name: "index_artefacts_slug_format"
  end
end