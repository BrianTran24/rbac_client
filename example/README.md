# Flutter TODO + Contact Demo (RBAC Client)

A demo app showcasing `rbac_client` with a clear 3-layer architecture:

1. **Repository → RepositoryImpl** (+ generated `*Guarded`)
2. **Cubit** (state management, catches `ForbiddenException`)
3. **UI** (Widgets)

> 📖 Step-by-step integration guide: [`../doc/usage_guide.md`](../doc/usage_guide.md)

## Structure

```
lib/
  core/
    permissions.dart    # DemoPermission (enum implements PermissionKey)
    auth.dart           # MockAuthRepository, SessionStore, Resolver, AuthController
  features/
    todo/
      domain/           # TodoRepository (@GenerateRBACWrapper) + TodoItem
      data/             # InMemoryTodoRepository (+ generated TodoRepositoryGuarded)
      presentation/     # TodoCubit + TodoPage
    contact/
      domain/           # ContactRepository (@GenerateRBACWrapper) + ContactItem
      data/             # InMemoryContactRepository (+ generated ContactRepositoryGuarded)
      presentation/     # ContactCubit + ContactPage
  main.dart             # Login flow + wiring
```

## Permissions

Each repository action maps to one permission:

| Feature | Permissions |
|---|---|
| TODO | `todo.view`, `todo.add`, `todo.toggle`, `todo.delete` |
| Contact | `contact.view`, `contact.add`, `contact.delete` |

## Mock login (random permissions)

`MockAuthRepository.login(username)` simulates a backend API:

- Each login returns a **random subset of permissions** (50% chance per permission).
- The `admin` user always gets **all** permissions.

In the UI you can:

- **Log in** as one of the sample users (`alice`, `bob`, `charlie`, `admin`).
- View a **permissions badge** plus a bottom sheet listing granted/denied permissions.
- Tap **Shuffle** to log in again as the same user for a new random permission set.
- **Log out** to return to the login screen.

Missing a permission blocks the action and shows a `Missing permission: ...` error.

## Generate code

```zsh
dart run build_runner build --delete-conflicting-outputs
```

## Run

```zsh
cd example
flutter pub get
flutter run
```

## Test

```zsh
cd example
flutter test
```

