require "data_mapper"
require "dm-migrations/migration_runner"

migration 1, :remove_department_from_policy do
  up do
    modify_table :policies do
      drop_column :department
    end
  end
end
