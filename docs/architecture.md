# Kiến trúc `chat_app`

**Frontend Flutter only** — backend Nest ở repo riêng. Xem [nest-integration.md](nest-integration.md).

## Luồng khởi động

`main.dart` → `bootstrap()` (binding, env, bắt lỗi) → `ProviderScope` → `App` → `GoRouter`.

## Thư mục

| Path | Vai trò |
|------|---------|
| `lib/app/` | Shell app: theme, router, bootstrap — **không** business logic |
| `lib/core/` | Config, Dio + JWT, session storage, error — **không** import `features/` |
| `lib/features/<tên>/` | UI + gọi Nest qua `data/datasources` |

## Feature nội bộ

- **domain**: entity + interface repository (contract phía FE).
- **data**: `*_remote_data_source.dart` (Dio) → repository impl.
- **presentation**: UI + Riverpod.

Feature **không** import presentation của feature khác; điều hướng qua `go_router`.

## Thêm feature mới

1. Tạo `domain` + `data/datasources` + `presentation`.
2. Thêm path Nest vào `core/network/api_endpoints.dart`.
3. Đăng ký route trong `app_router.dart`.

## Chạy

```bash
flutter run --dart-define-from-file=.env.dev.json
```
