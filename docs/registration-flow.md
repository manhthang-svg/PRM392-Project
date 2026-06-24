# Luồng đăng ký tài khoản bằng email và OTP

## Tổng quan

Luồng đăng ký chỉ tạo tài khoản sau khi người dùng xác minh đúng mã OTP gửi
đến email. Khi tạo tài khoản thành công, ứng dụng tự động đăng nhập, lưu JWT và
điều hướng người dùng đến Newsfeed.

```text
Nhập thông tin
    ↓
Yêu cầu gửi OTP
    ↓
Nhận OTP qua email
    ↓
Xác minh OTP
    ↓
Tạo tài khoản với role USER
    ↓
Tự động đăng nhập
    ↓
Lưu access token + refresh token
    ↓
Đi đến Newsfeed
```

## Bước 1: Nhập thông tin đăng ký

Người dùng nhập các trường sau trên màn hình đăng ký:

- Họ tên hiển thị (`displayName`).
- Username công khai (`handle`).
- Email dùng để đăng nhập.
- Mật khẩu và xác nhận mật khẩu.

Flutter kiểm tra dữ liệu bắt buộc, định dạng email, định dạng handle, độ dài mật
khẩu và việc hai mật khẩu có khớp nhau hay không trước khi gọi backend.

## Bước 2: Yêu cầu gửi OTP

Flutter gọi API:

```http
POST /api/auth/register/request-otp
Content-Type: application/json
```

```json
{
  "email": "paper@example.com"
}
```

Backend thực hiện:

1. Chuẩn hóa email về chữ thường và loại bỏ khoảng trắng thừa.
2. Kiểm tra email chưa được đăng ký.
3. Kiểm tra thời gian chờ trước khi cho phép gửi lại OTP.
4. Sinh mã OTP gồm sáu chữ số.
5. Lưu HMAC-SHA256 của OTP vào `registration_otps`, không lưu OTP gốc.
6. Gửi OTP đến email thông qua SMTP.

Response thành công chứa thời gian hiệu lực và thời gian được phép gửi lại:

```json
{
  "email": "paper@example.com",
  "expiresIn": 300,
  "resendIn": 60
}
```

OTP hết hạn sau 5 phút, chỉ được gửi lại sau 60 giây và bị khóa sau 5 lần nhập
sai.

## Bước 3: Xác minh OTP

Sau khi người dùng nhập OTP, Flutter gọi:

```http
POST /api/auth/register/verify
Content-Type: application/json
```

```json
{
  "email": "paper@example.com",
  "otp": "123456",
  "displayName": "Paper Artist",
  "handle": "paperartist",
  "password": "password123"
}
```

Backend kiểm tra:

- OTP tồn tại và chưa hết hạn.
- OTP nhận được khớp với HMAC đã lưu.
- Số lần nhập sai chưa vượt quá giới hạn.
- Email chưa được sử dụng.
- Handle chưa được sử dụng.
- Role `USER` tồn tại trong cơ sở dữ liệu.

Nếu tất cả điều kiện hợp lệ, backend mã hóa mật khẩu bằng BCrypt, tạo tài khoản
với role `USER` và xóa OTP. Việc tạo user và xóa OTP được thực hiện trong cùng
một transaction.

## Bước 4: Tự động đăng nhập

Sau khi API xác minh OTP thành công, `AuthSession` tự gọi API đăng nhập bằng
email và mật khẩu vừa đăng ký:

```http
POST /api/auth/login
```

Backend trả về:

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "4fe1...",
  "tokenType": "Bearer",
  "expiresIn": 900
}
```

Flutter lưu access token và refresh token bằng `flutter_secure_storage`, cập
nhật trạng thái đăng nhập và chuyển đến Newsfeed. Mật khẩu và OTP không được lưu
trên thiết bị.

## Gửi lại OTP

Nút gửi lại OTP chỉ được bật khi bộ đếm `resendIn` về 0. Khi người dùng yêu cầu
gửi lại, OTP cũ được thay thế bằng OTP mới và thời gian hết hạn được tính lại.

## Các lỗi chính

| Trường hợp | Kết quả |
| --- | --- |
| Email đã tồn tại | Từ chối gửi OTP hoặc tạo tài khoản |
| Handle đã tồn tại | Không tạo tài khoản |
| OTP sai | Tăng số lần nhập sai |
| OTP hết hạn | Yêu cầu người dùng gửi mã mới |
| Nhập sai quá 5 lần | Khóa OTP hiện tại |
| Gửi lại quá sớm | Yêu cầu chờ hết thời gian `resendIn` |
| SMTP chưa cấu hình | Trả về `503 MAIL_001` |
| SMTP gửi thất bại | Không giữ lại OTP chưa được gửi |

## Cấu hình SMTP

Thông tin SMTP phải được truyền qua biến môi trường, không ghi mật khẩu ứng dụng
trực tiếp vào source code:

```powershell
$env:MAIL_HOST="smtp.gmail.com"
$env:MAIL_PORT="587"
$env:MAIL_USERNAME="your-account@gmail.com"
$env:MAIL_PASSWORD="your-new-app-password"
$env:MAIL_FROM="your-account@gmail.com"
$env:OTP_PEPPER="a-long-random-server-secret"
```

Với Gmail, tài khoản phải bật xác minh hai bước và sử dụng App Password. Sau khi
thiết lập biến môi trường, khởi động lại backend để cấu hình có hiệu lực.

## Các thành phần liên quan

- Flutter UI: `lib/features/auth/screens/signup_screen.dart`.
- Flutter API: `lib/core/auth/auth_api.dart`.
- Quản lý phiên: `lib/core/auth/auth_session.dart`.
- Backend controller: `AuthController`.
- Backend service: `RegistrationServiceImpl`.
- Gửi email: `SmtpRegistrationMailService`.
- Migration: `V9__create_registration_otp_table.sql`.

