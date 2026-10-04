# chat_app

Frontend Flutter cho app chat nội bộ — **backend Nest ở repo riêng**. Feature-first + Riverpod + GoRouter + Dio.

## Chạy

```bash
flutter pub get
flutter run --dart-define-from-file=.env.dev.json
```

## Nest BE

Xem [docs/nest-integration.md](docs/nest-integration.md) (URL, JSON login, danh sách hội thoại).

## Cấu trúc

Xem [docs/architecture.md](docs/architecture.md).

## Dự án Flutter mới từ template này

Copy folder `lib/app`, `lib/core`, `docs/architecture.md`, `.env.dev.json`, dependencies trong `pubspec.yaml`, rồi thêm `features/` theo nhu cầu.
