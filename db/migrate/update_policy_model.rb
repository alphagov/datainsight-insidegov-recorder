require "data_mapper"
require "dm-migrations/migration_runner"

migration 1, :update_policy_model do
  up do
    modify_table :policies do
      change_column :department, "TEXT", allow_nil: false

      unless adapter.field_exists?("policies", "organisations")
        add_column :organisations, "TEXT", allow_nil: false
      end

      unless adapter.field_exists?("policies", "policy_updated_at")
        add_column :policy_updated_at, DateTime, allow_nil: false
      end
    end
  end
end
