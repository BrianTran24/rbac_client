import 'package:rbac_client/rbac.dart';

import '../../../core/permissions.dart';
import '../domain/todo_item.dart';
import '../domain/todo_repository.dart';

class InMemoryTodoRepository implements TodoRepository {
  final List<TodoItem> _items = [
    const TodoItem(id: 't1', title: 'Learn repository pattern'),
    const TodoItem(id: 't2', title: 'Connect Cubit to UI'),
  ];

  int _counter = 3;

  @override
  Future<void> addTodo(String title) async {
    _items.add(TodoItem(id: 't${_counter++}', title: title));
  }

  @override
  Future<void> deleteTodo(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<TodoItem>> fetchTodos() async {
    return List<TodoItem>.from(_items);
  }

  @override
  Future<void> toggleTodo(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = _items[index];
    _items[index] = current.copyWith(isDone: !current.isDone);
  }
}

class GuardedTodoRepository implements TodoRepository {
  GuardedTodoRepository(this._inner, this._sessionStore, this._contextResolver);

  final TodoRepository _inner;
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
  Future<void> addTodo(String title) async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.todoWrite);
    return _inner.addTodo(title);
  }

  @override
  Future<void> deleteTodo(String id) async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.todoWrite);
    return _inner.deleteTodo(id);
  }

  @override
  Future<List<TodoItem>> fetchTodos() async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.todoRead);
    return _inner.fetchTodos();
  }

  @override
  Future<void> toggleTodo(String id) async {
    final ctx = await _resolveContext();
    requirePermission(ctx, DemoPermission.todoWrite);
    return _inner.toggleTodo(id);
  }
}
