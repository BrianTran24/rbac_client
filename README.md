# rbac_client

Reusable RBAC package that contains:

- `@GenerateRBACWrapper()` for repository wrapper generation
- `@Access.*` method-level guard annotations
- shared runtime contracts (`RBACSessionStore`, `RBACUserContextResolver`)
- generic guard helpers (`UserContext`, `requirePermission`, `assertSelfScope`)

## Typed permissions

Define permissions as an enum and implement `PermissionKey` so
`@Access.permission(...)` is strongly typed at compile-time.

```dart
import 'package:rbac_client/rbac.dart';

enum AppPermission implements PermissionKey {
  userRead('user.read'),
  userWrite('user.write');

  @override
  final String code;

  const AppPermission(this.code);
}
```

Then use it in annotations:

```dart
@Access.permission(AppPermission.userRead)
Future<void> getUser(String userId);
```

## Usage

1. Add the package as a dependency.
2. Annotate an abstract repository with `@GenerateRBACWrapper()`.
3. Add `@Access.none()`, `@Access.permission(...)`, or `@Access.self(...)` to methods.
4. Provide your own implementations of:
   - `RBACSessionStore`
   - `RBACUserContextResolver`
5. Construct the generated `*Guarded` wrapper with your repository, session store, and resolver.

The package is intentionally app-agnostic: parsing tokens, mapping permission
strings, and building user context stay in the consuming app.
