import 'package:test/test.dart';

import 'package:rbac_client/rbac.dart';

enum TestPermission implements PermissionKey {
  read('read'),
  write('write');

  @override
  final String code;

  const TestPermission(this.code);
}

void main() {
  test('requirePermission allows existing permission', () {
	final ctx = UserContext(
	  userId: 'u-1',
	  permissions: {TestPermission.read},
	);

	expect(() => requirePermission(ctx, TestPermission.read), returnsNormally);
  });

  test('requirePermission throws ForbiddenException for missing permission', () {
	final ctx = UserContext(
	  userId: 'u-1',
	  permissions: {TestPermission.read},
	);

	expect(
	  () => requirePermission(ctx, TestPermission.write),
	  throwsA(
		isA<ForbiddenException>().having(
		  (e) => e.message,
		  'message',
		  contains('write'),
		),
	  ),
	);
  });
}

