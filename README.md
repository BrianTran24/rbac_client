# rbac_client

Reusable RBAC package that contains:

- `@GenerateRBACWrapper()` for repository wrapper generation
- `@Access.*` method-level guard annotations
- shared runtime contracts (`RBACSessionStore`, `RBACUserContextResolver`)
- generic guard helpers (`UserContext`, `requirePermission`, `assertSelfScope`)
- capability model for feature-level access (`Capability`, `FeatureCapability`, `CapabilityEvaluator`)
- Flutter UI helpers (`PermissionScope`, `PermissionGate`, `CapabilityGate`) via `package:rbac_client/widgets.dart`

## Entry points

| Import | Use for |
|---|---|
| `package:rbac_client/rbac.dart` | Annotations + runtime contracts + guard helpers |
| `package:rbac_client/widgets.dart` | Flutter permission-aware widgets (`PermissionScope`, `PermissionGate`) |

## Permission-aware widgets

Show/hide any widget based on the current user's permissions:

```dart
import 'package:rbac_client/widgets.dart';

// Provide the current permissions once, high in the tree:
PermissionScope(
  permissions: currentUser.permissions, // Set<PermissionKey>
  child: HomePage(),
);

// Then gate any widget – it hides itself when the permission is missing:
PermissionGate(
  permission: AppPermission.todoAdd,
  child: ElevatedButton(onPressed: addTodo, child: const Text('Add')),
);
```

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

## 📖 Step-by-step guide

See the full 8-step guide (with code samples, the `@Access` reference table, and
troubleshooting):

➡️ **[doc/usage_guide.md](doc/usage_guide.md)**

You can also explore the runnable example in [`example/`](example) — a Flutter
TODO + Contact app following the Repository → Cubit → UI architecture, with a
mock login that returns random permissions.


# rbac_client
