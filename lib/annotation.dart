/// Annotation to trigger RBAC wrapper code generation.
///
/// Apply this annotation to an abstract class to auto-generate a
/// `<ClassName>Guarded` wrapper that enforces permission checks defined with
/// [Access] on each method.
class GenerateRBACWrapper {
  const GenerateRBACWrapper();
}

/// Contract for permission values used by RBAC checks.
///
/// Prefer `enum ... implements PermissionKey` in consuming apps so annotation
/// values stay compile-time constants and strongly typed.
abstract interface class PermissionKey {
  const PermissionKey();

  String get code;
}

/// Declares how a repository method should be guarded.
class Access {
  final String type;
  final PermissionKey? permission;
  final String? ownerParam;

  const Access._(this.type, {this.permission, this.ownerParam});

  /// Skip RBAC checks for this method.
  const Access.none() : this._('none');

  /// Require the current user to match the method argument named [ownerParam].
  const Access.self({required String ownerParam})
      : this._('self', ownerParam: ownerParam);

  /// Require the current user to hold [permission].
  const Access.permission(PermissionKey permission)
      : this._('permission', permission: permission);
}
