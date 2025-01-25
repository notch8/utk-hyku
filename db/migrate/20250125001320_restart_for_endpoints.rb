class RestartForEndpoints < ActiveRecord::Migration[5.2]
  def change
    add_column :endpoints, :restart_command, :text
    add_column :endpoints, :last_restart, :datetime, default: Time.now
  end
end
