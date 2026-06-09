import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:rbac_client/rbac.dart';
import 'permissions.dart';

// ──────────────────────────────────────────────────────────
// Mock login result
// ──────────────────────────────────────────────────────────
class MockLoginResult {
  const MockLoginResult({required this.username, required this.permissions});

  final String username;
  final List<String> permissions;

  /// Permissions resolved to typed [DemoPermission] values.
  Set<DemoPermission> get granted =>
      permissions.map(DemoPermission.fromCode).whereType<DemoPermission>().toSet();
}

// ──────────────────────────────────────────────────────────
// Mock auth repository – simulates a backend login API.
// On every login it returns a *random* subset of all permissions
// so you can see RBAC enforcement in action.
// ──────────────────────────────────────────────────────────
class MockAuthRepository {
  static const mockUsers = ['alice', 'bob', 'charlie', 'admin'];

  final _random = Random();

  Future<MockLoginResult> login(String username) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));

    // Randomly grant each permission with 50 % probability.
    // 'admin' always gets everything for convenience.
    final permissions =
        username == 'admin'
            ? DemoPermission.values.map((p) => p.code).toList()
            : DemoPermission.values
                .where((_) => _random.nextBool())
                .map((p) => p.code)
                .toList();

    return MockLoginResult(username: username, permissions: permissions);
  }
}

// ──────────────────────────────────────────────────────────
// Session store – updated after every login
// ──────────────────────────────────────────────────────────
class DemoSessionStore implements RBACSessionStore {
  String? _token;
  List<String> _permissions = [];

  void updateFromLogin(MockLoginResult result) {
    _token = 'token-${result.username}';
    _permissions = List.of(result.permissions);
  }

  @override
  Future<String?> get token async => _token;

  @override
  Future<List<String>> get permissions async => List.of(_permissions);
}

// ──────────────────────────────────────────────────────────
// Context resolver – maps raw permission codes to typed values
// ──────────────────────────────────────────────────────────
class DemoUserContextResolver implements RBACUserContextResolver {
  @override
  UserContext resolve({
    required String token,
    required List<String> permissions,
  }) {
    final mapped =
        permissions
            .map(DemoPermission.fromCode)
            .whereType<DemoPermission>()
            .toSet();
    return UserContext(userId: token, permissions: mapped);
  }
}

// ──────────────────────────────────────────────────────────
// Auth controller – drives the login flow and notifies UI
// ──────────────────────────────────────────────────────────
class DemoAuthController extends ChangeNotifier {
  DemoAuthController(this._sessionStore, this._authRepo);

  final DemoSessionStore _sessionStore;
  final MockAuthRepository _authRepo;

  MockLoginResult? _current;
  bool isLoading = false;

  bool get isLoggedIn => _current != null;
  MockLoginResult? get current => _current;

  Future<void> login(String username) async {
    isLoading = true;
    notifyListeners();
    _current = await _authRepo.login(username);
    _sessionStore.updateFromLogin(_current!);
    isLoading = false;
    notifyListeners();
  }

  /// Re-login as the same user → new random permissions.
  Future<void> shufflePermissions() async {
    if (_current == null) return;
    await login(_current!.username);
  }

  void logout() {
    _current = null;
    isLoading = false;
    notifyListeners();
  }
}
