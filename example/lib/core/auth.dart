import 'package:flutter/foundation.dart';
import 'package:rbac_client/rbac.dart';

import 'permissions.dart';

class DemoSessionStore implements RBACSessionStore {
  String? _token = 'demo-token';
  List<String> _permissions = DemoRole.editor.permissions
      .map((e) => e.code)
      .toList();

  @override
  Future<String?> get token async => _token;

  @override
  Future<List<String>> get permissions async => _permissions;

  void updateRole(DemoRole role) {
    _permissions = role.permissions.map((e) => e.code).toList();
  }
}

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

class DemoAuthController extends ChangeNotifier {
  DemoAuthController(this._sessionStore);

  final DemoSessionStore _sessionStore;
  DemoRole _role = DemoRole.editor;

  DemoRole get role => _role;

  void setRole(DemoRole role) {
    _role = role;
    _sessionStore.updateRole(role);
    notifyListeners();
  }
}
