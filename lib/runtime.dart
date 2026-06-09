import 'annotation.dart';

class ForbiddenException implements Exception {
  final String message;

  ForbiddenException(this.message);

  @override
  String toString() => 'ForbiddenException: $message';
}

class UserContext {
  final String userId;
  final Set<PermissionKey> permissions;

  const UserContext({
    required this.userId,
    required this.permissions,
  });
}

abstract interface class RBACSessionStore {
  Future<String?> get token;

  Future<List<String>> get permissions;
}

abstract interface class RBACUserContextResolver {
  UserContext resolve({
    required String token,
    required List<String> permissions,
  });
}

void requirePermission(UserContext ctx, PermissionKey permission) {
  if (!ctx.permissions.contains(permission)) {
    throw ForbiddenException('Missing permission: ${permission.code}');
  }
}

void assertSelfScope(UserContext ctx, String ownerId) {
  if (ctx.userId != ownerId) {
    throw ForbiddenException('User cannot access another user\'s data');
  }
}
