import 'package:rbac_client/rbac.dart';

import '../../../core/permissions.dart';
import '../domain/contact_item.dart';
import '../domain/contact_repository.dart';

class InMemoryContactRepository implements ContactRepository {
  final List<ContactItem> _items = const [
    ContactItem(id: 'c1', name: 'Alice', phone: '0901234567'),
    ContactItem(id: 'c2', name: 'Bob', phone: '0912345678'),
  ].toList();

  int _counter = 3;

  @override
  Future<void> addContact({required String name, required String phone}) async {
    _items.add(ContactItem(id: 'c${_counter++}', name: name, phone: phone));
  }

  @override
  Future<void> deleteContact(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<ContactItem>> fetchContacts() async {
    return List<ContactItem>.from(_items);
  }
}

class GuardedContactRepository implements ContactRepository {
  GuardedContactRepository(
    this._inner,
    this._sessionStore,
    this._contextResolver,
  );

  final ContactRepository _inner;
  final RBACSessionStore _sessionStore;
  final RBACUserContextResolver _contextResolver;

  Future<UserContext> _resolveContext() async {
    final token = await _sessionStore.token;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }

    final permissions = await _sessionStore.permissions;
    return _contextResolver.resolve(token: token, permissions: permissions);
  }

  @override
  Future<void> addContact({required String name, required String phone}) async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.contactWrite);
    return _inner.addContact(name: name, phone: phone);
  }

  @override
  Future<void> deleteContact(String id) async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.contactWrite);
    return _inner.deleteContact(id);
  }

  @override
  Future<List<ContactItem>> fetchContacts() async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.contactRead);
    return _inner.fetchContacts();
  }
}
