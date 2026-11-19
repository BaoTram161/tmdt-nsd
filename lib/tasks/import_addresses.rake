namespace :addresses do
  desc "Import Vietnamese provinces and communes from JSON files"
  task import: :environment do
    require "json"

    provinces_file = Rails.root.join("tmp/address_data/provinces.json")
    communes_file = Rails.root.join("tmp/address_data/communes.json")

    unless File.exist?(provinces_file) && File.exist?(communes_file)
      abort "Không tìm thấy file JSON trong tmp/address_data."
    end

    provinces_data = JSON.parse(File.read(provinces_file))
    communes_data = JSON.parse(File.read(communes_file))

    province_rows = provinces_data.fetch("provinces").map do |item|
      {
        code: item.fetch("code"),
        name: item.fetch("name"),
        administrative_level: item["administrativeLevel"],
        decree: item["decree"],
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    ActiveRecord::Base.transaction do
      Province.upsert_all(
        province_rows,
        unique_by: :index_provinces_on_code
      )

      province_ids = Province.pluck(:code, :id).to_h

      commune_rows = communes_data.fetch("communes").map do |item|
        province_id = province_ids[item.fetch("provinceCode")]

        unless province_id
          raise "Không tìm thấy tỉnh có mã #{item['provinceCode']}"
        end

        {
          province_id: province_id,
          code: item.fetch("code"),
          name: item.fetch("name"),
          administrative_level: item["administrativeLevel"],
          decree: item["decree"],
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      commune_rows.each_slice(1000) do |batch|
        Commune.upsert_all(
          batch,
          unique_by: :index_communes_on_code
        )
      end
    end

    puts "Đã nhập #{Province.count} tỉnh/thành phố."
    puts "Đã nhập #{Commune.count} phường/xã."
    puts "Hoàn tất nhập dữ liệu địa lý Việt Nam."
  end
end
