# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_25_162436) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "label", null: false
    t.string "recipient_name", null: false
    t.string "phone", null: false
    t.string "province", null: false
    t.string "ward", null: false
    t.string "street_address", null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "communes", force: :cascade do |t|
    t.bigint "province_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.string "administrative_level"
    t.string "decree"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_communes_on_code", unique: true
    t.index ["province_id"], name: "index_communes_on_province_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.string "product_name", null: false
    t.string "product_image"
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.decimal "total_price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "order_number", null: false
    t.string "recipient_name", null: false
    t.string "phone", null: false
    t.string "province", null: false
    t.string "ward", null: false
    t.string "street_address", null: false
    t.string "status", default: "pending", null: false
    t.string "payment_method", default: "cod", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "shipping_fee", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_status", default: "unpaid", null: false
    t.string "promotion_code"
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "vnpay_transaction_no"
    t.datetime "paid_at"
    t.datetime "payment_expires_at"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.index ["vnpay_transaction_no"], name: "index_orders_on_vnpay_transaction_no", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.string "image_url"
    t.string "origin"
    t.string "packaging"
    t.integer "stock"
    t.boolean "featured"
    t.boolean "active"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "original_price", precision: 12
    t.integer "sold_count", default: 0, null: false
    t.string "brand"
    t.index ["brand"], name: "index_products_on_brand"
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "promotion_codes", force: :cascade do |t|
    t.string "code", null: false
    t.string "discount_type", null: false
    t.decimal "discount_value", precision: 12, scale: 2, null: false
    t.decimal "minimum_order_value", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "maximum_discount", precision: 12, scale: 2
    t.integer "usage_limit"
    t.integer "per_user_limit"
    t.integer "used_count", default: 0, null: false
    t.datetime "starts_at"
    t.datetime "expires_at"
    t.boolean "active", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_promotion_codes_on_code", unique: true
  end

  create_table "provinces", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "administrative_level"
    t.string "decree"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_provinces_on_code", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.integer "rating", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["user_id", "product_id"], name: "index_reviews_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_between_1_and_5"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "phone"
    t.boolean "is_admin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "communes", "provinces"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products", on_delete: :nullify
  add_foreign_key "orders", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "sessions", "users"
end
