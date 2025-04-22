class CreateUriCaches < ActiveRecord::Migration[5.2]
  def change
    create_table :uri_caches do |t|
      t.text :uri
      t.text :value

      t.timestamps
    end

    add_index :uri_caches, :uri, unique: true
  end
end
