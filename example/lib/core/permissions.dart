import 'package:rbac_client/rbac.dart';

/// All fine-grained permissions used in this demo.
/// Each entry maps to a specific action on a specific feature.
enum DemoPermission implements PermissionKey {
  // ── TODO feature ──────────────────────────────────────────
  todoView('todo.view'),
  todoAdd('todo.add'),
  todoToggle('todo.toggle'),
  todoDelete('todo.delete'),

  // ── Contact feature ───────────────────────────────────────
  contactView('contact.view'),
  contactAdd('contact.add'),
  contactDelete('contact.delete');

  @override
  final String code;
  const DemoPermission(this.code);

  static DemoPermission? fromCode(String code) {
    for (final p in DemoPermission.values) {
      if (p.code == code) return p;
    }
    return null;
  }

  String get label {
    switch (this) {
      case todoView:     return '👀 View TODOs';
      case todoAdd:      return '➕ Add TODO';
      case todoToggle:   return '✅ Toggle TODO';
      case todoDelete:   return '🗑 Delete TODO';
      case contactView:  return '👀 View Contacts';
      case contactAdd:   return '➕ Add Contact';
      case contactDelete:return '🗑 Delete Contact';
    }
  }
}
