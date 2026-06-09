import '../domain/todo_item.dart';
import '../domain/todo_repository.dart';

/// In-memory implementation – pure business logic, no RBAC awareness.
/// Wrap this with the generated [TodoRepositoryGuarded] to enforce permissions.
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
