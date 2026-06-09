// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_repository.dart';

// **************************************************************************
// RBACWrapperGenerator
// **************************************************************************

class ContactRepositoryGuarded implements ContactRepository {
  final ContactRepository _inner;
  final RBACSessionStore _sessionStore;
  final RBACUserContextResolver _contextResolver;

  ContactRepositoryGuarded(
      this._inner, this._sessionStore, this._contextResolver);

  @override
  Future<List<ContactItem>> fetchContacts() async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.contactView);
    return await _inner.fetchContacts();
  }

  @override
  Future<void> addContact({required String name, required String phone}) async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.contactAdd);
    return await _inner.addContact(name: name, phone: phone);
  }

  @override
  Future<void> deleteContact(String id) async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.contactDelete);
    return await _inner.deleteContact(id);
  }
}
