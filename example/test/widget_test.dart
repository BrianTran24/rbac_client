import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_client/rbac.dart';
import 'package:rbac_client/widgets.dart';

import 'package:flutter_todo_contact_demo/core/permissions.dart';

/// Helper: wraps [child] in a [PermissionScope] holding [granted].
Widget _wrap(Set<PermissionKey> granted, Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: PermissionScope(permissions: granted, child: child),
  );
}

void main() {
  testWidgets('shows child when the permission is granted', (tester) async {
    await tester.pumpWidget(
      _wrap(
        {DemoPermission.todoAdd},
        const PermissionGate(
          permission: DemoPermission.todoAdd,
          child: Text('ADD'),
        ),
      ),
    );

    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('hides child when the permission is missing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        {DemoPermission.todoView}, // no todoAdd
        const PermissionGate(
          permission: DemoPermission.todoAdd,
          child: Text('ADD'),
        ),
      ),
    );

    expect(find.text('ADD'), findsNothing);
  });

  testWidgets('renders fallback when the permission is missing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const {},
        const PermissionGate(
          permission: DemoPermission.todoAdd,
          fallback: Text('NO ACCESS'),
          child: Text('ADD'),
        ),
      ),
    );

    expect(find.text('ADD'), findsNothing);
    expect(find.text('NO ACCESS'), findsOneWidget);
  });

  testWidgets('PermissionScope.has reflects the granted set', (tester) async {
    late bool canAdd;
    late bool canDelete;

    await tester.pumpWidget(
      _wrap(
        {DemoPermission.todoAdd},
        Builder(
          builder: (context) {
            canAdd = PermissionScope.has(context, DemoPermission.todoAdd);
            canDelete = PermissionScope.has(context, DemoPermission.todoDelete);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(canAdd, isTrue);
    expect(canDelete, isFalse);
  });
}
