class TodoItem {
  const TodoItem({required this.id, required this.title, this.isDone = false});

  final String id;
  final String title;
  final bool isDone;

  TodoItem copyWith({String? id, String? title, bool? isDone}) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
