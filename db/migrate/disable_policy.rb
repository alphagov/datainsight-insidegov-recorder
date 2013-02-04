require "data_mapper"
require "dm-migrations/migration_runner"

migration 4, :disable_policy do
  up do
    modify_table :policies do
      unless adapter.field_exists?("policies", "disabled")
        add_column :disabled, "boolean", allow_nil: false
      end
    end
  end

  down do
    modify_table :policies do
      drop_column :disabled
    end
  end
end
