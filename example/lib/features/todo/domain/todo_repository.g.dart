// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_repository.dart';

// **************************************************************************
// RBACWrapperGenerator
// **************************************************************************

class TodoRepositoryGuarded implements TodoRepository {
  final TodoRepository _inner;
  final RBACSessionStore _sessionStore;
  final RBACUserContextResolver _contextResolver;

  TodoRepositoryGuarded(this._inner, this._sessionStore, this._contextResolver);

  @override
  Future<List<TodoItem>> fetchTodos() async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.todoView);
    return await _inner.fetchTodos();
  }

  @override
  Future<void> addTodo(String title) async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.todoAdd);
    return await _inner.addTodo(title);
  }

  @override
  Future<void> toggleTodo(String id) async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.todoToggle);
    return await _inner.toggleTodo(id);
  }

  @override
  Future<void> deleteTodo(String id) async {
    final token = await _sessionStore.token;
    final permissions = await _sessionStore.permissions;
    if (token == null || token.isEmpty) {
      throw ForbiddenException('User not authenticated');
    }
    final userContext =
        _contextResolver.resolve(token: token, permissions: permissions);
    requirePermission(userContext, DemoPermission.todoDelete);
    return await _inner.deleteTodo(id);
  }
}
