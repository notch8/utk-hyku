class RemoveRestartCommandFromEndpoints < ActiveRecord::Migration[5.2]
  def change
    remove_column :endpoints, :restart_command, :string
  end
end
