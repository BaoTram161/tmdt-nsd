class MakeAddressDistrictOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :addresses, :district, true
  end
end