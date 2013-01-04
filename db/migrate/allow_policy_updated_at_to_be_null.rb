require "data_mapper"
require "dm-migrations/migration_runner"

migration 3, :allow_policy_updated_at_to_be_null do
  up do
    modify_table :policies do
      change_column :policy_updated_at, DateTime, allow_nil: true
    end
  end
end

