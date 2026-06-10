import 'package:flutter/material.dart';
import 'package:rbac_client/rbac.dart';

import '../../core/capabilities.dart';
import '../../core/permissions.dart';

/// A screen listing every [Capability]. Tap a capability to expand and inspect
/// its dependencies: the API permissions it needs and the prerequisite
/// capabilities it depends on (each with its grant/availability status).
class AccessPage extends StatelessWidget {
  const AccessPage({
    super.key,
    required this.username,
    required this.grantedPermissions,
  });

  final String username;
  final Set<PermissionKey> grantedPermissions;

  @override
  Widget build(BuildContext context) {
    final evaluator = CapabilityEvaluator(grantedPermissions);

    return Scaffold(
      appBar: AppBar(title: Text('Access · $username')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Legend(
            available: evaluator.availableFrom(allCapabilities).length,
            total: allCapabilities.length,
          ),
          const Divider(height: 1),
          for (final capability in allCapabilities)
            _CapabilityTile(capability: capability, evaluator: evaluator),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.available, required this.total});

  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Capabilities available: $available / $total',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({required this.capability, required this.evaluator});

  final Capability capability;
  final CapabilityEvaluator evaluator;

  @override
  Widget build(BuildContext context) {
    final result = evaluator.evaluate(capability);
    final available = result.isAvailable;

    return ExpansionTile(
      leading: Icon(
        available ? Icons.check_circle : Icons.lock_outline,
        color: available ? Colors.green : Colors.redAccent,
      ),
      title: Text(capability.label),
      subtitle: Text(
        available ? 'Available' : 'Locked — tap to see why',
        style: TextStyle(
          color: available ? Colors.green : Colors.redAccent,
          fontSize: 12,
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Required permissions ──────────────────────────────────────────
        const _SectionHeader('Required permissions'),
        if (capability.requiredPermissions.isEmpty)
          const _EmptyRow('No permissions required')
        else
          for (final permission in capability.requiredPermissions)
            _StatusRow(
              granted: grantedHas(permission),
              title: _permissionLabel(permission),
              subtitle: permission.code,
            ),

        const SizedBox(height: 8),

        // ── Prerequisite capabilities ─────────────────────────────────────
        const _SectionHeader('Prerequisite capabilities'),
        if (capability.prerequisites.isEmpty)
          const _EmptyRow('No prerequisites')
        else
          for (final prerequisite in capability.prerequisites)
            _StatusRow(
              granted: evaluator.isAvailable(prerequisite),
              title: prerequisite.label,
              subtitle: prerequisite.id,
              grantedIcon: Icons.check_circle,
              deniedIcon: Icons.lock_outline,
            ),
      ],
    );
  }

  bool grantedHas(PermissionKey permission) =>
      evaluator.grantedPermissions.contains(permission);

  String _permissionLabel(PermissionKey permission) {
    return permission is DemoPermission ? permission.label : permission.code;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.granted,
    required this.title,
    required this.subtitle,
    this.grantedIcon = Icons.check_circle,
    this.deniedIcon = Icons.cancel_outlined,
  });

  final bool granted;
  final String title;
  final String subtitle;
  final IconData grantedIcon;
  final IconData deniedIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? grantedIcon : deniedIcon,
            size: 18,
            color: granted ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

