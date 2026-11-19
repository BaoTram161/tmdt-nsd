class RemoveDistrictFromAddresses < ActiveRecord::Migration[8.1]
  def change
    remove_column :addresses, :district, :string
  end
end
