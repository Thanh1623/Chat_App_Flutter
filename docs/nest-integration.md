# Flutter FE ↔ Nest BE

Repo này **chỉ là frontend**. Business logic, DB, WebSocket gateway nằm ở repo Nest của bạn.

## Cấu hình

`API_BASE_URL` trỏ tới Nest (mặc định dev: `http://localhost:3000`).

```bash
flutter run --dart-define-from-file=.env.dev.json
```

- **Android emulator:** thường dùng `http://10.0.2.2:3000`
- **iOS simulator:** `http://localhost:3000` OK
- **Máy thật:** IP LAN của máy chạy Nest, ví dụ `http://192.168.1.10:3000`

Nest cần **CORS** cho web (nếu có) và cho phép origin dev.

## Hợp đồng API (mặc định trong app)

Chỉnh `lib/core/network/api_endpoints.dart` nếu Nest dùng prefix khác (`/api/v1/...`).

### POST `/auth/login`

Body:

```json
{ "email": "...", "password": "..." }
```

Response (một trong các key token):

```json
{
  "accessToken": "jwt...",
  "user": {
    "id": "uuid",
    "displayName": "Tên",
    "email": "user@company.local"
  }
}
```

App cũng chấp nhận `access_token`, `token`, và field user `name`.

### POST `/auth/logout` (optional)

App luôn xóa token local; logout BE fail vẫn coi là đăng xuất.

### GET `/conversations`

Response: mảng JSON, map theo `ConversationModel.fromJson` (`id`, `title`, `type`, `lastMessagePreview`, `updatedAt`, `unreadCount`).

### Chat / realtime

- REST tin nhắn: thêm endpoint trong `ApiEndpoints` (ví dụ `GET/POST .../messages`).
- Realtime Nest (Socket.io / ws): thêm client ở `lib/core/network/` và stream trong `features/chat/data/` — chưa scaffold sẵn.

## Luồng auth trên FE

1. Login → Nest trả JWT → lưu `flutter_secure_storage`.
2. Mọi request Dio qua `AuthInterceptor` header `Authorization: Bearer ...`.
3. Mở app → `restoreSession()` đọc token + user, GoRouter giữ đăng nhập.

## File cần sửa khi BE khác format

| File | Việc |
|------|------|
| `api_endpoints.dart` | Path Nest |
| `login_response.dart` | Parse JSON login |
| `conversation_model.dart` | Parse danh sách chat |
| `auth_remote_data_source.dart` | Body login nếu dùng `username` |
