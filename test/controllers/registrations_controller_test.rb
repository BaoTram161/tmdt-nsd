require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # HIỂN THỊ FORM

  test "hiển thị form đăng ký" do
    get new_registration_path

    assert_response :success
  end

  # ĐĂNG KÝ TÀI KHOẢN

  test "đăng ký tài khoản thành công" do
    assert_difference("User.count", 1) do
      post registration_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }
    end

    assert_redirected_to root_path
    assert User.exists?(email_address: "newuser@example.com")
  end

  test "không đăng ký khi email bị bỏ trống" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email_address: "",
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "không đăng ký khi mật khẩu xác nhận không khớp" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "Password123!",
          password_confirmation: "Different123!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "không đăng ký khi email đã tồn tại" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email_address: users(:one).email_address,
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
