require "datainsight_recorder/migrations"

migration 3, :add_index_artefacts_collected_at do
  up do
    create_index :artefacts, :collected_at, name: "index_artefacts_collected_at"
  end

  down do
    adapter.drop_index "artefacts", "index_artefacts_collected_at"
  end
end
