class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address,
            presence: true,
            uniqueness: { case_sensitive: false }
end
