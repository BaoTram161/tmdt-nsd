class CreateCommunes < ActiveRecord::Migration[8.1]
  def change
    create_table :communes do |t|
      t.references :province, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :administrative_level
      t.string :decree

      t.timestamps
    end

    add_index :communes, :code, unique: true
  end
end
