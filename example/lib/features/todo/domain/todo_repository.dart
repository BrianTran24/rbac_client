import 'package:rbac_client/rbac.dart';
import '../../../core/permissions.dart';
import 'todo_item.dart';

part 'todo_repository.g.dart';

/// Abstract contract for TODO data operations.
///
/// Annotated with [GenerateRBACWrapper] so that `build_runner` auto-generates
/// [TodoRepositoryGuarded] — a wrapper that enforces permission checks before
/// delegating to the real implementation.
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
