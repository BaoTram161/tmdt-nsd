class Address < ApplicationRecord
  belongs_to :user

  validates :label, :recipient_name, :phone,
            :province, :ward, :street_address,
            presence: true

  before_save :unset_other_default_addresses, if: :is_default?

  private

  def unset_other_default_addresses
    user.addresses
        .where.not(id: id)
        .update_all(is_default: false)
  end
end