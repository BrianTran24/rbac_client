# Flutter TODO + Contact Demo

Demo theo 3 phần rõ ràng:

1. Repository -> RepositoryImpl (+ GuardedRepository)
2. Cubit (state management)
3. UI

## Cấu trúc

- `lib/features/todo/domain/*`: abstraction cho TODO
- `lib/features/todo/data/*`: in-memory impl + RBAC guard cho TODO
- `lib/features/todo/presentation/*`: `TodoCubit` + `TodoPage`
- `lib/features/contact/domain/*`: abstraction cho Contact
- `lib/features/contact/data/*`: in-memory impl + RBAC guard cho Contact
- `lib/features/contact/presentation/*`: `ContactCubit` + `ContactPage`
- `lib/core/auth.dart`: session store + resolver + role controller
- `lib/core/permissions.dart`: `PermissionKey` enum và role mapping

## Role

- `viewer`: chỉ đọc TODO + Contact
- `editor`: đọc/ghi toàn bộ

Trong UI có dropdown đổi role để thấy RBAC hoạt động trực tiếp.

## Run

```zsh
cd /Users/hieutran/AndroidStudioProjects/rbac_client/example/flutter_todo_contact_demo
flutter pub get
flutter run
```

## Test

```zsh
cd /Users/hieutran/AndroidStudioProjects/rbac_client/example/flutter_todo_contact_demo
flutter test
```

