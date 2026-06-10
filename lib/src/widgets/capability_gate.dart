import 'package:flutter/widgets.dart';

import '../../capability.dart';
import 'permission_gate.dart';

/// Shows [child] only when [capability] is available for the current user;
/// otherwise renders [fallback] (an empty box by default).
///
/// Availability is computed from the permissions provided by the nearest
/// [PermissionScope], honouring the capability's required permissions **and**
/// its prerequisite capabilities.
///
/// ```dart
/// CapabilityGate(
///   capability: manageTodos, // requires todoAdd+todoDelete AND viewTodos
///   child: const Text('Full management enabled'),
/// );
/// ```
///
/// > 🔒 This is a UI convenience, not a security boundary. Always keep your
/// > repository-level `@Access` guards — they are the real enforcement.
class CapabilityGate extends StatelessWidget {
  const CapabilityGate({
    super.key,
    required this.capability,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  /// The capability required to render [child].
  final Capability capability;

  /// The widget shown when the capability is available.
  final Widget child;

  /// The widget shown when the capability is unavailable.
  /// Defaults to an empty (zero-size) widget, effectively hiding [child].
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final granted = PermissionScope.of(context);
    final available = CapabilityEvaluator(granted).isAvailable(capability);
    return available ? child : fallback;
  }
}

