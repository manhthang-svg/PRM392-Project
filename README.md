lib/
│
├── app/                      # Cấu hình toàn cục của ứng dụng
│   ├── routes.dart           # Định nghĩa các tuyến đường chuyển màn hình (Routing)
│   ├── theme.dart            # Cấu hình màu sắc (Pastel Pink, White), Font chữ toàn app
│   └── app.dart              # File khởi tạo MaterialApp chính
│
├── core/                     # Nơi chứa các tài nguyên dùng chung cho toàn bộ app
│   ├── constants/            # Định nghĩa hằng số (Kích thước, chuỗi văn bản, đường dẫn API)
│   ├── network/              # Cấu hình HTTP Client (Dio/Http), WebSocket cho tính năng Chat
│   ├── utils/                # Các hàm bổ trợ (Format ngày tháng, xử lý ảnh watermark, v.v.)
│   └── widgets/              # Các UI Component dùng chung (Custom Button hồng, Text Field, Loading...)
│
├── features/                 # THƯ MỤC CHÍNH: Chia theo từng cụm tính năng trong sơ đồ Flow
│   │
│   ├── auth/                 # Cụm Đăng nhập (Splash screen, Login screen)
│   │
│   ├── newsfeed/             # Cụm Mạng xã hội (Purple Nodes: Origami newsfeed, comment)
│   │
│   ├── explore/              # Cụm Thư viện & Gấp giấy (Red Nodes: Library, Browse, Step-by-step, Save result)
│   │
│   ├── contribution/         # Cụm Creator Studio (Green Nodes: Create instruction, List, Fill info)
│   │
│   ├── chat/                 # Cụm Trò chuyện (Yellow Nodes: List conversation, Conversation details)
│   │
│   └── profile/              # Cụm Cá nhân & Thành tựu (Blue + Orange Nodes: Profile, Update, Achievements)
│
└── main.dart                 # Điểm chạy ứng dụng đầu tiên (Root entry)