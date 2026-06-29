# Library và lưu trữ ảnh bằng Cloudinary

## Kiến trúc

Flutter không giữ `CLOUDINARY_API_SECRET` và không upload trực tiếp bằng secret.
Ứng dụng gửi ảnh cùng JWT đến Spring Boot; backend kiểm tra file, ký request và
upload ảnh lên Cloudinary. Database chỉ lưu HTTPS URL và metadata của tutorial.

```text
Flutter chọn ảnh
    ↓ multipart + JWT
POST /api/media/images
    ↓ signed upload
Cloudinary
    ↓ secure_url
Flutter gửi nội dung tutorial + các secure_url
    ↓
POST /api/tutorials
    ↓
MySQL tutorials / tutorial_steps / tutorial_materials
```

## Cấu hình Cloudinary

Tạo Cloudinary account, lấy Cloud name, API key và API secret trong dashboard,
sau đó đặt biến môi trường trước khi chạy backend:

```powershell
$env:CLOUDINARY_CLOUD_NAME="your-cloud-name"
$env:CLOUDINARY_API_KEY="your-api-key"
$env:CLOUDINARY_API_SECRET="your-api-secret"
$env:CLOUDINARY_FOLDER="origami/tutorials"

cd spring-security
.\mvnw.cmd spring-boot:run
```

Không commit API secret vào `application-local.yml`. Nếu secret từng bị đưa lên
Git, cần rotate credential trong Cloudinary dashboard.

## Upload ảnh

```http
POST /api/media/images
Authorization: Bearer <access-token>
Content-Type: multipart/form-data
```

Form field bắt buộc:

- `file`: một ảnh không rỗng.
- Dung lượng tối đa mặc định: 10 MB.
- MIME type phải bắt đầu bằng `image/`.

Response:

```json
{
  "success": true,
  "data": {
    "secureUrl": "https://res.cloudinary.com/.../image/upload/...jpg",
    "publicId": "origami/tutorials/...",
    "width": 1200,
    "height": 1200,
    "format": "jpg",
    "bytes": 245120
  }
}
```

## Tạo tutorial

```http
POST /api/tutorials
Authorization: Bearer <access-token>
Content-Type: application/json
```

```json
{
  "title": "Traditional Paper Crane",
  "description": "A beginner-friendly traditional crane.",
  "categorySlug": "birds",
  "difficulty": "EASY",
  "estimatedMinutes": 15,
  "thumbnailUrl": "https://res.cloudinary.com/.../step-1.jpg",
  "draft": false,
  "materials": ["15cm square paper"],
  "steps": [
    {
      "description": "Fold the paper diagonally.",
      "mediaUrl": "https://res.cloudinary.com/.../step-1.jpg"
    }
  ]
}
```

- `draft: true`: lưu với trạng thái `DRAFT`; các trường chưa hoàn thiện được
  phép để trống.
- `draft: false`: yêu cầu category, mô tả, độ khó, thời gian, vật liệu và ít
  nhất một bước; tutorial được chuyển sang `PROCESSING` để chờ duyệt.
- Chỉ tutorial `APPROVED` xuất hiện trong Library.

## Duyệt tutorial

Tài khoản có authority `ADMIN` hoặc `MANAGER` duyệt submission qua:

```http
PATCH /api/tutorials/{id}/review
Authorization: Bearer <admin-or-manager-access-token>
Content-Type: application/json
```

```json
{
  "status": "APPROVED",
  "note": "Images and instructions are clear."
}
```

`status` chỉ nhận `APPROVED` hoặc `REJECTED`, và tutorial phải đang ở trạng
thái `PROCESSING`. Mỗi lần duyệt được ghi vào `tutorial_status_history`.

## Đọc Library

```http
GET /api/tutorials
GET /api/tutorials/{id}
```

API danh sách hỗ trợ query parameters:

- `query`: tìm trong title và description.
- `category`: category slug, ví dụ `birds`.
- `difficulty`: `EASY`, `MEDIUM` hoặc `HARD`.
- `minMinutes`, `maxMinutes`: lọc thời lượng.

API chi tiết trả về mô tả, creator, vật liệu và danh sách bước đã sắp xếp. Flutter
dùng chính ảnh Cloudinary của từng bước trên màn hình Step by Step.

## Mã lỗi chính

| Code | Ý nghĩa |
| --- | --- |
| `MEDIA_001` | Backend chưa có Cloudinary credential |
| `MEDIA_002` | File rỗng hoặc không phải ảnh |
| `MEDIA_003` | Ảnh vượt quá dung lượng cho phép |
| `MEDIA_004` | Cloudinary upload thất bại |
| `TUTORIAL_001` | Không tìm thấy tutorial approved |
| `TUTORIAL_002` | Category không tồn tại |
| `TUTORIAL_003` | Tutorial chưa đủ dữ liệu để submit |
| `TUTORIAL_004` | Trạng thái hiện tại không cho phép duyệt |
