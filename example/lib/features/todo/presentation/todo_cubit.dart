import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_client/rbac.dart';

import '../domain/todo_item.dart';
import '../domain/todo_repository.dart';

class TodoState {
  const TodoState({this.items = const [], this.isLoading = false, this.error});

  final List<TodoItem> items;
  final bool isLoading;
  final String? error;

  TodoState copyWith({
    List<TodoItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TodoState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TodoCubit extends Cubit<TodoState> {
  TodoCubit(this._repository) : super(const TodoState());

  final TodoRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await _repository.fetchTodos();
      emit(state.copyWith(items: items, isLoading: false, clearError: true));
    } on ForbiddenException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    }
  }

  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    try {
      await _repository.addTodo(title.trim());
      await load();
    } on ForbiddenException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> toggle(String id) async {
    try {
      await _repository.toggleTodo(id);
      await load();
    } on ForbiddenException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> remove(String id) async {
    try {
      await _repository.deleteTodo(id);
      await load();
    } on ForbiddenException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}
