import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_client/rbac.dart';

import 'package:flutter_todo_contact_demo/core/auth.dart';
import 'package:flutter_todo_contact_demo/core/permissions.dart';
import 'package:flutter_todo_contact_demo/features/todo/data/todo_repository_impl.dart';

void main() {
  test('viewer role cannot write TODO', () async {
    final session = DemoSessionStore()..updateRole(DemoRole.viewer);
    final resolver = DemoUserContextResolver();
    final repo = GuardedTodoRepository(
      InMemoryTodoRepository(),
      session,
      resolver,
    );

    expect(
      () => repo.addTodo('not allowed'),
      throwsA(isA<ForbiddenException>()),
    );
  });

  test('editor role can write TODO', () async {
    final session = DemoSessionStore()..updateRole(DemoRole.editor);
    final resolver = DemoUserContextResolver();
    final repo = GuardedTodoRepository(
      InMemoryTodoRepository(),
      session,
      resolver,
    );

    await repo.addTodo('allowed');
    final items = await repo.fetchTodos();

    expect(items.any((item) => item.title == 'allowed'), isTrue);
  });
}
