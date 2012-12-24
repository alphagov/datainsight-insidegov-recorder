require "data_mapper"
require "dm-migrations/migration_runner"

migration 1, :update_policy_model do
  up do
    modify_table :policies do
      change_column :department, "TEXT", allow_nil: false
      add_column :organisations, "TEXT", allow_nil: false
      add_column :policy_updated_at, DateTime, allow_nil: false
    end
  end
end
