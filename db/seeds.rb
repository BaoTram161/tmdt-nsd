# Thương hiệu sản phẩm thực tế: Le Chef
# Thương hiệu cửa hàng: GINSVITAL

root_category = Category.find_or_create_by!(name: "Nhân sâm đen") do |category|
  category.description = "Các sản phẩm nhân sâm đen Le Chef."
end

pure_category = Category.find_or_create_by!(name: "Nguyên chất") do |category|
  category.parent = root_category
  category.description = "Nhân sâm đen nguyên chất."
end

sweet_category = Category.find_or_create_by!(name: "Ngọt tự nhiên") do |category|
  category.parent = root_category
  category.description = "Nhân sâm đen sử dụng chất làm ngọt tự nhiên."
end

products = [
  [ "Le Chef Nhân Sâm Đen | Set 3 Hũ (3 x 50G) Nguyên Chất", 4500000, pure_category, "Set 3 hũ x 50g" ],
  [ "Le Chef Nhân Sâm Đen | Set 3 Hũ (3 x 50G) Ngọt Tự Nhiên", 4500000, sweet_category, "Set 3 hũ x 50g" ],

  [ "Le Chef Nhân Sâm Đen | Set 3 Hũ (3 x 25G) Nguyên Chất", 2400000, pure_category, "Set 3 hũ x 25g" ],
  [ "Le Chef Nhân Sâm Đen | Set 3 Hũ (3 x 25G) Ngọt tự nhiên", 2400000, sweet_category, "Set 3 hũ x 25g" ],

  [ "Le Chef Nhân Sâm Đen | Set 3 Hũ (3 x 10G) Nguyên Chất", 1150000, pure_category, "Set 3 hũ x 10g" ],
  [ "Le Chef Nhân Sâm Đen | Set 3 Hũ (3 x 10G) Ngọt tự nhiên", 1150000, sweet_category, "Set 3 hũ x 10g" ],

  [ "Le Chef Nhân Sâm Đen | Hũ (100G) Nguyên Chất", 2600000, pure_category, "Hũ 100g" ],
  [ "Le Chef Nhân Sâm Đen | Hũ (50G) Nguyên Chất", 1500000, pure_category, "Hũ 50g" ],
  [ "Le Chef Nhân Sâm Đen | Hũ (25G) Nguyên Chất", 800000, pure_category, "Hũ 25g" ],
  [ "Le Chef Nhân Sâm Đen | Hũ (10G) Nguyên Chất", 350000, pure_category, "Hũ 10g" ],

  [ "Le Chef Nhân Sâm Đen | Hũ (100G) Ngọt Tự Nhiên", 2600000, sweet_category, "Hũ 100g" ],
  [ "Le Chef Nhân Sâm Đen | Hũ (50G) Ngọt Tự Nhiên", 1500000, sweet_category, "Hũ 50g" ],
  [ "Le Chef Nhân Sâm Đen | Hũ (25G) Ngọt Tự Nhiên", 800000, sweet_category, "Hũ 25g" ],
  [ "Le Chef Nhân Sâm Đen | Hũ (10G) Ngọt Tự Nhiên", 350000, sweet_category, "Hũ 10g" ]
]

products.each_with_index do |(name, price, category, packaging), index|
  product = Product.find_or_initialize_by(name: name)

  product.assign_attributes(
    category: category,
    price: price,
    original_price: nil,
    brand: "Le Chef",
    packaging: packaging,
    description: name,
    image_url: nil,
    stock: 0,
    sold_count: 0,
    featured: index < 5,
    active: true
  )

  product.save!
end

puts "Đã cập nhật #{Category.count} danh mục."
puts "Đã cập nhật #{Product.count} sản phẩm."
