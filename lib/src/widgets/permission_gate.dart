import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../annotation.dart';

/// Provides the current user's granted permissions to the widget subtree.
///
/// Place a single [PermissionScope] above any [PermissionGate]s (typically near
/// the top of the authenticated part of the app) and rebuild it whenever the
/// permission set changes (e.g. after login / logout / role switch).
///
/// ```dart
/// PermissionScope(
///   permissions: currentUser.permissions, // Set<PermissionKey>
///   child: HomePage(),
/// );
/// ```
class PermissionScope extends InheritedWidget {
  const PermissionScope({
    super.key,
    required this.permissions,
    required super.child,
  });

  /// The set of permissions the current user holds.
  final Set<PermissionKey> permissions;

  /// Reads the nearest [PermissionScope]'s permissions.
  /// Returns an empty set when no scope is found.
  static Set<PermissionKey> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PermissionScope>();
    return scope?.permissions ?? const {};
  }

  /// Whether the current user holds [permission].
  static bool has(BuildContext context, PermissionKey permission) {
    return of(context).contains(permission);
  }

  @override
  bool updateShouldNotify(PermissionScope oldWidget) =>
      !setEquals(permissions, oldWidget.permissions);
}

/// Shows [child] only when the current user holds [permission];
/// otherwise renders [fallback] (an empty box by default).
///
/// Requires a [PermissionScope] ancestor.
///
/// ```dart
/// PermissionGate(
///   permission: AppPermission.todoAdd,
///   child: ElevatedButton(onPressed: ..., child: const Text('Add')),
/// );
/// ```
///
/// > 🔒 This is a UI convenience, not a security boundary. Always keep your
/// > repository-level `@Access` guards — they are the real enforcement.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  /// The permission required to render [child].
  final PermissionKey permission;

  /// The widget shown when the permission is granted.
  final Widget child;

  /// The widget shown when the permission is missing.
  /// Defaults to an empty (zero-size) widget, effectively hiding [child].
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return PermissionScope.has(context, permission) ? child : fallback;
  }
}

