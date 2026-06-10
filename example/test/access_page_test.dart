import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_client/rbac.dart';

import 'package:flutter_todo_contact_demo/core/permissions.dart';
import 'package:flutter_todo_contact_demo/features/access/access_page.dart';

void main() {
  Widget app(Set<PermissionKey> granted) => MaterialApp(
        home: AccessPage(username: 'tester', grantedPermissions: granted),
      );

  testWidgets('lists all capabilities with availability count', (tester) async {
    await tester.pumpWidget(
      app({DemoPermission.todoView}), // only viewTodos available
    );

    expect(find.text('View TODOs'), findsOneWidget);
    expect(find.text('Manage TODOs'), findsOneWidget);
    expect(find.text('View Contacts'), findsOneWidget);
    expect(find.text('Manage Contacts'), findsOneWidget);

    // 1 of 4 capabilities available (only viewTodos).
    expect(find.text('Capabilities available: 1 / 4'), findsOneWidget);
  });

  testWidgets('expanding a locked capability reveals its dependencies',
      (tester) async {
    // Has add+delete but NOT view → manageTodos locked by the viewTodos prereq.
    await tester.pumpWidget(
      app({DemoPermission.todoAdd, DemoPermission.todoDelete}),
    );

    await tester.tap(find.text('Manage TODOs'));
    await tester.pumpAndSettle();

    // Dependency sections appear.
    expect(find.text('REQUIRED PERMISSIONS'), findsOneWidget);
    expect(find.text('PREREQUISITE CAPABILITIES'), findsOneWidget);

    // The unmet prerequisite is shown inside the expanded tile.
    expect(find.text('View TODOs'), findsWidgets);
  });
}

