require "data_mapper"
require "dm-migrations/migration_runner"

migration 2, :remove_department_from_policy do
  up do
    modify_table :policies do
      if adapter.field_exists?("policies", "department")
        drop_column :department
      end
    end
  end
end
