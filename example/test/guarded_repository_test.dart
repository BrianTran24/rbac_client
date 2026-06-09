import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_client/rbac.dart';

import 'package:flutter_todo_contact_demo/core/auth.dart';
import 'package:flutter_todo_contact_demo/core/permissions.dart';
import 'package:flutter_todo_contact_demo/features/todo/data/todo_repository_impl.dart';
import 'package:flutter_todo_contact_demo/features/todo/domain/todo_repository.dart';
import 'package:flutter_todo_contact_demo/features/contact/data/contact_repository_impl.dart';
import 'package:flutter_todo_contact_demo/features/contact/domain/contact_repository.dart';

/// Builds a session store seeded with an explicit set of permissions.
DemoSessionStore _sessionWith(Set<DemoPermission> permissions) {
  return DemoSessionStore()
    ..updateFromLogin(
      MockLoginResult(
        username: 'tester',
        permissions: permissions.map((p) => p.code).toList(),
      ),
    );
}

void main() {
  final resolver = DemoUserContextResolver();

  group('Generated TodoRepositoryGuarded', () {
    test('blocks addTodo when todoAdd permission is missing', () {
      final repo = TodoRepositoryGuarded(
        InMemoryTodoRepository(),
        _sessionWith({DemoPermission.todoView}),
        resolver,
      );

      expect(
        () => repo.addTodo('not allowed'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('allows addTodo when todoAdd permission is granted', () async {
      final repo = TodoRepositoryGuarded(
        InMemoryTodoRepository(),
        _sessionWith({DemoPermission.todoView, DemoPermission.todoAdd}),
        resolver,
      );

      await repo.addTodo('allowed');
      final items = await repo.fetchTodos();

      expect(items.any((item) => item.title == 'allowed'), isTrue);
    });

    test('blocks fetchTodos when todoView permission is missing', () {
      final repo = TodoRepositoryGuarded(
        InMemoryTodoRepository(),
        _sessionWith({DemoPermission.todoAdd}),
        resolver,
      );

      expect(
        () => repo.fetchTodos(),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('Generated ContactRepositoryGuarded', () {
    test('blocks deleteContact when contactDelete permission is missing', () {
      final repo = ContactRepositoryGuarded(
        InMemoryContactRepository(),
        _sessionWith({DemoPermission.contactView}),
        resolver,
      );

      expect(
        () => repo.deleteContact('c1'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('allows fetchContacts when contactView permission is granted',
        () async {
      final repo = ContactRepositoryGuarded(
        InMemoryContactRepository(),
        _sessionWith({DemoPermission.contactView}),
        resolver,
      );

      final items = await repo.fetchContacts();
      expect(items, isNotEmpty);
    });
  });

  group('MockAuthRepository', () {
    test('admin always receives every permission', () async {
      final result = await MockAuthRepository().login('admin');
      expect(result.granted.length, DemoPermission.values.length);
    });

    test('login returns a valid (possibly empty) permission subset', () async {
      final result = await MockAuthRepository().login('alice');
      expect(result.granted.every(DemoPermission.values.contains), isTrue);
    });
  });
}
