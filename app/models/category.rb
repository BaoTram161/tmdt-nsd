class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true

  has_many :children,
           class_name: "Category",
           foreign_key: :parent_id,
           dependent: :restrict_with_error

  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  scope :roots, -> { where(parent_id: nil) }

  # Lấy ID của danh mục hiện tại và các danh mục con
  def self_and_children_ids
    [id] + children.pluck(:id)
  end
end
