class Province < ApplicationRecord
  has_many :communes, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
