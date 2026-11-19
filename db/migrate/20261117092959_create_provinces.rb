class CreateProvinces < ActiveRecord::Migration[8.1]
  def change
    create_table :provinces do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :administrative_level
      t.string :decree

      t.timestamps
    end

    add_index :provinces, :code, unique: true
  end
end
