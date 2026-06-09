import 'todo_item.dart';

abstract interface class TodoRepository {
  Future<List<TodoItem>> fetchTodos();
  Future<void> addTodo(String title);
  Future<void> toggleTodo(String id);
  Future<void> deleteTodo(String id);
}
