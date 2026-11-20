require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "hiển thị hồ sơ cá nhân" do
    get profile_url

    assert_response :success
    assert_includes response.body, @user.email_address
  end

  test "cập nhật hồ sơ thành công" do
    patch profile_url, params: {
      user: {
        full_name: "Nguyễn Văn A",
        phone: "0901234567",
        email_address: "updated@example.com"
      }
    }

    assert_redirected_to profile_url

    @user.reload
    assert_equal "Nguyễn Văn A", @user.full_name
    assert_equal "0901234567", @user.phone
    assert_equal "updated@example.com", @user.email_address
  end

  # KIỂM TRA CẬP NHẬT

  test "không cập nhật khi email đã được tài khoản khác sử dụng" do
    patch profile_url, params: {
      user: {
        email_address: users(:two).email_address
      }
    }

    assert_response :unprocessable_entity

    @user.reload
    assert_not_equal users(:two).email_address, @user.email_address
  end

  test "hiển thị lỗi khi email không hợp lệ" do
    original_email = @user.email_address

    patch profile_url, params: {
      user: {
        email_address: "email-khong-hop-le"
      }
    }

    assert_response :unprocessable_entity

    @user.reload
    assert_equal original_email, @user.email_address
  end

  test "cập nhật hồ sơ không làm thay đổi mật khẩu" do
    original_password_digest = @user.password_digest

    patch profile_url, params: {
      user: {
        full_name: "Nguyễn Văn B",
        phone: "0912345678"
      }
    }

    assert_redirected_to profile_url
    assert_equal original_password_digest, @user.reload.password_digest
  end
end
