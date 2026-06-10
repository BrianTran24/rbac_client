# RBAC Client – Usage Guide (Step by step)

This guide walks you through integrating `rbac_client` into a Flutter/Dart app
using the **Repository → Cubit/Bloc → UI** architecture, with code generation
that automatically produces permission-checking guard classes.

> 💡 A complete, runnable example lives in the [`example/`](../example) folder.

---

## Table of contents

1. [Architecture overview](#1-architecture-overview)
2. [Installation](#2-installation)
3. [Step 1 – Define permissions](#step-1--define-permissions)
4. [Step 2 – Declare the repository + annotations](#step-2--declare-the-repository--annotations)
5. [Step 3 – Configure build_runner & generate](#step-3--configure-build_runner--generate)
6. [Step 4 – Write the real implementation](#step-4--write-the-real-implementation)
7. [Step 5 – Implement RBACSessionStore](#step-5--implement-rbacsessionstore)
8. [Step 6 – Implement RBACUserContextResolver](#step-6--implement-rbacusercontextresolver)
9. [Step 7 – Assemble the guarded wrapper](#step-7--assemble-the-guarded-wrapper)
10. [Step 8 – Use it in Cubit & UI](#step-8--use-it-in-cubit--ui)
11. [Hiding widgets by permission (PermissionGate)](#hiding-widgets-by-permission-permissiongate)
12. [Capabilities (feature-level access)](#capabilities-feature-level-access)
13. [@Access reference](#access-reference)
14. [Troubleshooting](#troubleshooting)

---

## 1. Architecture overview

```
┌────────────┐      ┌─────────────────────┐      ┌──────────────┐
│    UI      │ ───▶ │   Cubit / Bloc      │ ───▶ │  Repository  │  (abstract + @Access)
│ (Widgets)  │      │ (catch Forbidden)   │      └──────┬───────┘
└────────────┘      └─────────────────────┘             │ implements
                                                         ▼
                                            ┌────────────────────────┐
                                            │  XxxRepositoryGuarded   │  ← GENERATED
                                            │  (permission checks)    │
                                            └────────────┬───────────┘
                                                         │ wraps
                                                         ▼
                                            ┌────────────────────────┐
                                            │  InMemoryXxxRepository  │  (real logic)
                                            └────────────────────────┘
```

`rbac_client` provides:

| Component | Responsibility |
|---|---|
| `@GenerateRBACWrapper()` | Marks an abstract class so a `*Guarded` wrapper is generated |
| `@Access.permission(...)` / `@Access.self(...)` / `@Access.none()` | Declares the access rule for each method |
| `PermissionKey` | Contract for defining strongly-typed permissions |
| `RBACSessionStore` | Supplies the current token + list of permissions |
| `RBACUserContextResolver` | Turns a token + permissions into a `UserContext` |
| `requirePermission`, `assertSelfScope` | Guard helpers invoked by the generated code |
| `ForbiddenException` | Thrown when a required permission is missing |

---

## 2. Installation

Add it to your app's `pubspec.yaml`:

```yaml
dependencies:
  rbac_client:
    path: ../   # or git/hosted, depending on how you distribute it

dev_dependencies:
  build_runner: ^2.4.13
```

Fetch packages:

```zsh
flutter pub get
```

---

## Step 1 – Define permissions

Define permissions as an `enum implements PermissionKey`. Each permission maps
to one specific action on one repository.

```dart
// lib/core/permissions.dart
import 'package:rbac_client/rbac.dart';

enum DemoPermission implements PermissionKey {
  // TODO feature
  todoView('todo.view'),
  todoAdd('todo.add'),
  todoToggle('todo.toggle'),
  todoDelete('todo.delete'),

  // Contact feature
  contactView('contact.view'),
  contactAdd('contact.add'),
  contactDelete('contact.delete');

  @override
  final String code;
  const DemoPermission(this.code);

  /// Map a raw code string (e.g. from an API) back to the enum.
  static DemoPermission? fromCode(String code) {
    for (final p in DemoPermission.values) {
      if (p.code == code) return p;
    }
    return null;
  }
}
```

> ✅ Because it is an `enum` (a compile-time constant) it can be used directly in
> annotations while staying type-checked at compile time.

---

## Step 2 – Declare the repository + annotations

Create an **abstract class** and:
- annotate the class with `@GenerateRBACWrapper()`
- annotate each method with `@Access.permission(...)`
- declare `part 'your_file.g.dart';`

```dart
// lib/features/todo/domain/todo_repository.dart
import 'package:rbac_client/rbac.dart';
import '../../../core/permissions.dart';
import 'todo_item.dart';

part 'todo_repository.g.dart'; // 👈 the file that will be generated

@GenerateRBACWrapper()
abstract class TodoRepository {
  @Access.permission(DemoPermission.todoView)
  Future<List<TodoItem>> fetchTodos();

  @Access.permission(DemoPermission.todoAdd)
  Future<void> addTodo(String title);

  @Access.permission(DemoPermission.todoToggle)
  Future<void> toggleTodo(String id);

  @Access.permission(DemoPermission.todoDelete)
  Future<void> deleteTodo(String id);
}
```

> ⚠️ **Important:** every guarded method must return `Future` or `Future<T>`,
> because the permission check is asynchronous (it needs to `await` the session).

---

## Step 3 – Configure build_runner & generate

The `rbac_client` builder is applied automatically to dependent packages thanks
to `auto_apply: dependents`, so you **don't** need a `build.yaml` in your app.

Just run:

```zsh
# Generate once
dart run build_runner build --delete-conflicting-outputs

# Or watch and regenerate continuously while you edit
dart run build_runner watch --delete-conflicting-outputs
```

The result is `todo_repository.g.dart` containing `TodoRepositoryGuarded`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'todo_repository.dart';

class TodoRepositoryGuarded implements TodoRepository {
  final TodoRepository _inner;
  final RBACSessionStore _sessionStore;
  final RBACUserContextResolver _contextResolver;

  TodoRepositoryGuarded(this._inner, this._sessionStore, this._contextResolver);

  @override
  Future<void> addTodo(String title) async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.todoAdd); // 👈 generated guard
    return await _inner.addTodo(title);
  }
  // ... other methods
}
```

---

## Step 4 – Write the real implementation

The implementation holds **business logic only** and knows nothing about RBAC:

```dart
// lib/features/todo/data/todo_repository_impl.dart
import '../domain/todo_item.dart';
import '../domain/todo_repository.dart';

class InMemoryTodoRepository implements TodoRepository {
  final List<TodoItem> _items = [];
  int _counter = 1;

  @override
  Future<List<TodoItem>> fetchTodos() async => List.of(_items);

  @override
  Future<void> addTodo(String title) async {
    _items.add(TodoItem(id: 't${_counter++}', title: title));
  }

  @override
  Future<void> toggleTodo(String id) async { /* ... */ }

  @override
  Future<void> deleteTodo(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
```

---

## Step 5 – Implement RBACSessionStore

`RBACSessionStore` exposes the current **token** and **list of permission codes**
(typically taken from the login result / a locally stored token).

```dart
// lib/core/auth.dart
import 'package:rbac_client/rbac.dart';

class DemoSessionStore implements RBACSessionStore {
  String? _token;
  List<String> _permissions = [];

  /// Call this after a successful login.
  void updateFromLogin(String token, List<String> permissionCodes) {
    _token = token;
    _permissions = List.of(permissionCodes);
  }

  @override
  Future<String?> get token async => _token;

  @override
  Future<List<String>> get permissions async => List.of(_permissions);
}
```

---

## Step 6 – Implement RBACUserContextResolver

The resolver converts a token + list of permission code strings into a
`UserContext` whose permissions are mapped to the typed enum.

```dart
// lib/core/auth.dart
class DemoUserContextResolver implements RBACUserContextResolver {
  @override
  UserContext resolve({
    required String token,
    required List<String> permissions,
  }) {
    final mapped = permissions
        .map(DemoPermission.fromCode)
        .whereType<DemoPermission>()
        .toSet();

    return UserContext(userId: token, permissions: mapped);
  }
}
```

---

## Step 7 – Assemble the guarded wrapper

Wrap the real implementation with the generated `*Guarded` class:

```dart
final sessionStore = DemoSessionStore();
final resolver = DemoUserContextResolver();

final TodoRepository todoRepository = TodoRepositoryGuarded(
  InMemoryTodoRepository(), // real logic
  sessionStore,             // token + permissions
  resolver,                 // maps to UserContext
);
```

From now on, every call to `todoRepository.addTodo(...)` automatically checks
the `todoAdd` permission before executing. A missing permission throws a
`ForbiddenException`.

---

## Step 8 – Use it in Cubit & UI

The Cubit calls the repository and **catches `ForbiddenException`** to surface
the error:

```dart
// presentation/todo_cubit.dart
class TodoCubit extends Cubit<TodoState> {
  TodoCubit(this._repo) : super(const TodoState());
  final TodoRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await _repo.fetchTodos();
      emit(state.copyWith(items: items, isLoading: false));
    } on ForbiddenException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    }
  }

  Future<void> add(String title) async {
    try {
      await _repo.addTodo(title);
      await load();
    } on ForbiddenException catch (e) {
      emit(state.copyWith(error: e.message)); // e.g. "Missing permission: todo.add"
    }
  }
}
```

The UI simply listens to the state and shows `state.error` when present:

```dart
if (state.error != null)
  Text(state.error!, style: const TextStyle(color: Colors.red)),
```

---

## Hiding widgets by permission (PermissionGate)

Besides guarding repository calls, you often want to **hide UI elements** (an Add
button, a delete icon, a menu entry) when the user lacks a permission. The
package ships a small reusable widget for this, available from a dedicated
Flutter entry point:

```dart
import 'package:rbac_client/widgets.dart';
```

It has two parts:

- **`PermissionScope`** – an `InheritedWidget` that exposes the current user's
  granted permissions to the subtree. Place it once, high in the authenticated
  part of the tree, and rebuild it when permissions change (after login/logout).
- **`PermissionGate`** – shows its `child` only when the given `PermissionKey`
  is granted; otherwise it renders `fallback` (an empty box by default, i.e. it
  hides the widget entirely).

### 1. Provide the permissions once

```dart
// Rebuilds whenever the auth state changes.
PermissionScope(
  permissions: Set<PermissionKey>.from(authController.current!.granted),
  child: HomePage(...),
);
```

### 2. Gate any widget

```dart
// The button disappears completely when the user lacks todoAdd.
PermissionGate(
  permission: DemoPermission.todoAdd,
  child: ElevatedButton(
    onPressed: _add,
    child: const Text('Add'),
  ),
);

// Optionally show something else instead of hiding.
PermissionGate(
  permission: DemoPermission.contactDelete,
  fallback: const Icon(Icons.lock_outline, color: Colors.grey),
  child: IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
);
```

### 3. Imperative check

When you need a boolean (e.g. inside `build`), use the static helper:

```dart
if (PermissionScope.has(context, DemoPermission.todoDelete)) {
  // ...
}
```

> 🔒 `PermissionGate` is a **UI convenience**, not a security boundary. Always
> keep the repository-level `@Access` guards — they are the real enforcement.

---

## Capabilities (feature-level access)

Permissions are fine-grained (one per API action). A **Capability** is a higher
level concept: it represents a **user-facing feature** an actor interacts with.

The mental model:

- An **actor** interacts with the app.
- The app runs **use cases** to fulfil a request; each use case may call APIs,
  which is what a `PermissionKey` protects.
- A **Capability** groups the permissions a feature needs, and can depend on
  **other capabilities** as prerequisites.

A capability is **available** when:

1. all of its `requiredPermissions` are granted, **and**
2. all of its `prerequisites` are (recursively) available.

### Define capabilities

```dart
import 'package:rbac_client/rbac.dart';

// "View" is the base capability of the feature.
const viewTodos = FeatureCapability(
  'todo.view',
  requiredPermissions: {AppPermission.todoView},
);

// "Manage" needs add + delete AND depends on being able to view first.
const manageTodos = FeatureCapability(
  'todo.manage',
  requiredPermissions: {AppPermission.todoAdd, AppPermission.todoDelete},
  prerequisites: {viewTodos}, // prerequisite capability
);
```

### Evaluate capabilities

```dart
final evaluator = CapabilityEvaluator(currentUser.permissions);

evaluator.isAvailable(manageTodos);        // bool (checks perms + prerequisites)
evaluator.missingPermissions(manageTodos); // Set<PermissionKey> not granted
evaluator.unmetPrerequisites(manageTodos); // Set<Capability> not available
evaluator.availableFrom(allCapabilities);  // List<Capability> currently usable

final result = evaluator.evaluate(manageTodos);
// result.isAvailable / result.missingPermissions / result.unmetPrerequisites
```

> A prerequisite cycle (a config bug) throws `CapabilityCycleError`.

### Gate widgets by capability

`CapabilityGate` works exactly like `PermissionGate`, but evaluates a whole
capability (permissions **and** prerequisites) using the permissions from the
nearest `PermissionScope`:

```dart
import 'package:rbac_client/widgets.dart';

CapabilityGate(
  capability: manageTodos, // hidden unless add+delete granted AND viewTodos met
  child: const Text('Full TODO management enabled'),
);
```

### Build an access/permissions screen

A common need is a screen that lists every capability and lets the user tap one
to inspect its dependencies (required permissions + prerequisite capabilities,
each with its status). The example app ships a reference implementation:
[`example/lib/features/access/access_page.dart`](../example/lib/features/access/access_page.dart).

It builds a `CapabilityEvaluator` from the granted permissions and, for each
capability, shows `evaluate(capability)` results in an expandable tile:

```dart
final evaluator = CapabilityEvaluator(grantedPermissions);
final result = evaluator.evaluate(capability);
// result.isAvailable / result.missingPermissions / result.unmetPrerequisites
```

---

## @Access reference

| Annotation | Meaning | Generated code |
|---|---|---|
| `@Access.none()` | Skip the permission check (public method) | No guard, calls through directly |
| `@Access.permission(X)` | Require the user to hold permission `X` | `requirePermission(ctx, X);` |
| `@Access.self(ownerParam: 'userId')` | Require the user to act on their own data | `assertSelfScope(ctx, userId.toString());` |
| *(no annotation)* | Method is not guarded | Calls `_inner` directly |

Example of `@Access.self`:

```dart
@Access.self(ownerParam: 'userId')
Future<void> updateProfile(String userId, String name);
```

Generated:

```dart
assertSelfScope(userContext, userId.toString());
```

---

## Troubleshooting

| Symptom | Cause & fix |
|---|---|
| `*Guarded isn't defined` | Not generated yet. Run `dart run build_runner build --delete-conflicting-outputs`. Make sure you declared `part 'xxx.g.dart';`. |
| `Target of URI doesn't exist: '.../permissions.dart'` | Wrong relative import path. Recount the `../` levels. |
| `Guarded method ... must declare Future` | A guarded method returns a synchronous type. Change it to `Future` / `Future<T>`. |
| `@Access.permission with an unsupported permission value` | The value passed in is not a constant (an enum value implementing `PermissionKey`). Use `enum ... implements PermissionKey`. |
| Correct permission but still `ForbiddenException` | `RBACSessionStore.permissions` was not updated after login, or `fromCode` maps the `code` string incorrectly. |
| Annotation changed but code is stale | You are not running `watch`. Re-run `build` or use `build_runner watch`. |

---

## 8-step recap

1. **Permissions** – `enum implements PermissionKey`
2. **Repository** – abstract class + `@GenerateRBACWrapper()` + `@Access.*` + `part`
3. **Generate** – `dart run build_runner build`
4. **Impl** – real logic class `implements XxxRepository`
5. **SessionStore** – supplies token + permission codes
6. **Resolver** – maps to `UserContext`
7. **Wrapper** – `XxxRepositoryGuarded(impl, session, resolver)`
8. **Cubit/UI** – call the repo, catch `ForbiddenException`

🎉 Done! All permission checks are now centralized, generated, and type-safe.

