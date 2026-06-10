import 'package:rbac_client/rbac.dart';

import 'permissions.dart';

/// Capabilities = user-facing features of this demo app.
///
/// Each capability maps to the API permissions its use cases need, and may
/// depend on another capability as a prerequisite.

// ── TODO feature ────────────────────────────────────────────────────────────

/// Being able to view the TODO list.
const viewTodos = FeatureCapability(
  'todo.view',
  requiredPermissions: {DemoPermission.todoView},
);

/// Full TODO management (add + delete). You can only manage TODOs that you can
/// also view, so [viewTodos] is a prerequisite.
const manageTodos = FeatureCapability(
  'todo.manage',
  requiredPermissions: {DemoPermission.todoAdd, DemoPermission.todoDelete},
  prerequisites: {viewTodos},
);

// ── Contact feature ─────────────────────────────────────────────────────────

/// Being able to view the contact list.
const viewContacts = FeatureCapability(
  'contact.view',
  requiredPermissions: {DemoPermission.contactView},
);

/// Full contact management (add + delete), requires [viewContacts] first.
const manageContacts = FeatureCapability(
  'contact.manage',
  requiredPermissions: {
    DemoPermission.contactAdd,
    DemoPermission.contactDelete,
  },
  prerequisites: {viewContacts},
);

/// All capabilities, handy for overviews.
const allCapabilities = <Capability>[
  viewTodos,
  manageTodos,
  viewContacts,
  manageContacts,
];

/// Human-friendly labels for capabilities shown in the UI.
extension CapabilityLabel on Capability {
  String get label {
    switch (id) {
      case 'todo.view':
        return 'View TODOs';
      case 'todo.manage':
        return 'Manage TODOs';
      case 'contact.view':
        return 'View Contacts';
      case 'contact.manage':
        return 'Manage Contacts';
      default:
        return id;
    }
  }
}

