module ApplicationHelper
  def shop_info
    {
      name: "BLACK GINSENG",
      slogan: "Từ Magasam Wisconsin - Hoa Kỳ",
      hotline: "0902 663 336",
      email: "lechef@vevco.vn",
      address: "288/17 Nguyễn Thượng Hiền, TP. Hồ Chí Minh",
      hours: "Liên hệ để biết giờ phục vụ"
    }
  end

  def hotline_tel
    "tel:#{shop_info[:hotline].delete(' ')}"
  end

  def format_vnd(amount)
    number_to_currency(
      amount,
      unit: "đ",
      format: "%n%u",
      precision: 0,
      delimiter: "."
    )
  end

  def nav_categories
    @nav_categories ||= Category.roots.includes(:children).order(:id)
  end

  def nav_link_class(active = false)
    base = "block whitespace-nowrap px-4 py-3 border-b-[3px] transition"

    if active
      "#{base} bg-nsd-dark text-nsd-yellow border-nsd-yellow"
    else
      "#{base} border-transparent hover:bg-nsd-dark"
    end
  end
end
