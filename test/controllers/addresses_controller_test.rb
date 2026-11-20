require "test_helper"

class AddressesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "hiển thị danh sách địa chỉ" do
    create_address

    get addresses_url

    assert_response :success
    assert_includes response.body, "Nguyễn Văn A"
  end

  test "hiển thị form thêm địa chỉ" do
    get new_address_url

    assert_response :success
  end

  test "thêm địa chỉ thành công và tự đặt mặc định" do
    @user.addresses.destroy_all

    assert_difference("@user.addresses.count", 1) do
      post addresses_url, params: { address: address_params }
    end

    assert_redirected_to addresses_url

    address = @user.addresses.order(:id).last
    assert address.is_default?
  end

  test "cập nhật địa chỉ thành công" do
    address = create_address

    patch address_url(address), params: {
      address: { recipient_name: "Trần Văn B" }
    }

    assert_redirected_to addresses_url
    assert_equal "Trần Văn B", address.reload.recipient_name
  end

  test "xóa địa chỉ thành công" do
    address = create_address

    assert_difference("@user.addresses.count", -1) do
      delete address_url(address)
    end

    assert_redirected_to addresses_url
  end

  test "xóa địa chỉ mặc định thì chọn địa chỉ khác làm mặc định" do
    first = create_address
    second = create_address(recipient_name: "Người nhận thứ hai")

    first.update!(is_default: true)
    second.update!(is_default: false)

    delete address_url(first)

    assert second.reload.is_default?
  end

  test "không thể truy cập địa chỉ của người dùng khác" do
    other_address = users(:two).addresses.create!(address_params)

    get edit_address_url(other_address)

    assert_response :not_found
  end

  private

  def address_params
    {
      label: "Nhà riêng",
      recipient_name: "Nguyễn Văn A",
      phone: "0901234567",
      province: "TP. Hồ Chí Minh",
      ward: "Phường 1",
      street_address: "123 Đường kiểm thử"
    }
  end

  def create_address(attributes = {})
    @user.addresses.create!(address_params.merge(attributes))
  end

  # KIỂM TRA DỮ LIỆU ĐỊA CHỈ

  test "không thêm địa chỉ khi thiếu thông tin bắt buộc" do
    assert_no_difference("@user.addresses.count") do
      post addresses_url, params: {
        address: address_params.merge(recipient_name: "")
      }
    end

    assert_response :unprocessable_entity
  end

  test "không cập nhật địa chỉ khi dữ liệu không hợp lệ" do
    address = create_address

    patch address_url(address), params: {
      address: { recipient_name: "" }
    }

    assert_response :unprocessable_entity
    assert_equal "Nguyễn Văn A", address.reload.recipient_name
  end

  # KIỂM TRA QUYỀN TRUY CẬP

  test "không thể cập nhật địa chỉ của người dùng khác" do
    other_address = users(:two).addresses.create!(address_params)

    patch address_url(other_address), params: {
      address: { recipient_name: "Tên bị thay đổi" }
    }

    assert_response :not_found
    assert_equal "Nguyễn Văn A", other_address.reload.recipient_name
  end

  test "không thể xóa địa chỉ của người dùng khác" do
    other_address = users(:two).addresses.create!(address_params)

    assert_no_difference("Address.count") do
      delete address_url(other_address)
    end

    assert_response :not_found
  end
end
