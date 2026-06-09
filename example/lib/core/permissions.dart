import 'package:rbac_client/rbac.dart';

enum DemoPermission implements PermissionKey {
  todoRead('todo.read'),
  todoWrite('todo.write'),
  contactRead('contact.read'),
  contactWrite('contact.write');

  @override
  final String code;

  const DemoPermission(this.code);

  static DemoPermission? fromCode(String code) {
    for (final permission in DemoPermission.values) {
      if (permission.code == code) {
        return permission;
      }
    }
    return null;
  }
}

enum DemoRole { viewer, editor }

extension DemoRolePermissions on DemoRole {
  Set<DemoPermission> get permissions {
    switch (this) {
      case DemoRole.viewer:
        return {DemoPermission.todoRead, DemoPermission.contactRead};
      case DemoRole.editor:
        return Set<DemoPermission>.from(DemoPermission.values);
    }
  }
}
