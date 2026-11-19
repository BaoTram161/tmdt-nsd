class Commune < ApplicationRecord
  belongs_to :province

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
