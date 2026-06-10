import 'annotation.dart';

/// A user-facing **feature** (something an actor interacts with in the UI).
///
/// A capability becomes *available* when:
/// 1. the user holds every permission in [requiredPermissions] (the API-level
///    permissions exercised by the underlying use cases), **and**
/// 2. every capability in [prerequisites] is itself available (recursively).
///
/// Capabilities can therefore depend on each other as preconditions, e.g.
/// "manage todos" may require "view todos" first.
abstract interface class Capability {
  /// Stable, unique identifier (useful for logging and cycle detection).
  String get id;

  /// API-level permissions this capability needs (via its use cases).
  Set<PermissionKey> get requiredPermissions;

  /// Other capabilities that must be available *before* this one.
  Set<Capability> get prerequisites;
}

/// Default, immutable [Capability] implementation.
///
/// ```dart
/// const viewTodos = FeatureCapability(
///   'todo.view',
///   requiredPermissions: {AppPermission.todoView},
/// );
///
/// const manageTodos = FeatureCapability(
///   'todo.manage',
///   requiredPermissions: {AppPermission.todoAdd, AppPermission.todoDelete},
///   prerequisites: {viewTodos}, // can only manage what you can view
/// );
/// ```
class FeatureCapability implements Capability {
  const FeatureCapability(
    this.id, {
    this.requiredPermissions = const {},
    this.prerequisites = const {},
  });

  @override
  final String id;

  @override
  final Set<PermissionKey> requiredPermissions;

  @override
  final Set<Capability> prerequisites;

  @override
  String toString() => 'Capability($id)';
}

/// Thrown when [Capability.prerequisites] form a cycle (a configuration bug).
class CapabilityCycleError extends Error {
  CapabilityCycleError(this.path);

  /// The chain of capability ids that loops back on itself.
  final List<String> path;

  @override
  String toString() =>
      'CapabilityCycleError: prerequisite cycle detected: '
      '${path.join(' -> ')}';
}

/// Detailed result of evaluating a [Capability] against a permission set.
class CapabilityResult {
  const CapabilityResult({
    required this.capability,
    required this.isAvailable,
    required this.missingPermissions,
    required this.unmetPrerequisites,
  });

  /// The capability that was evaluated.
  final Capability capability;

  /// Whether the capability is fully available.
  final bool isAvailable;

  /// Directly required permissions that are not granted.
  final Set<PermissionKey> missingPermissions;

  /// Direct prerequisites that are not (recursively) available.
  final Set<Capability> unmetPrerequisites;

  /// Whether all directly required permissions are granted
  /// (ignores prerequisites).
  bool get hasAllPermissions => missingPermissions.isEmpty;
}

/// Evaluates [Capability]s against a fixed set of granted permissions.
///
/// Create one per permission snapshot (e.g. after each login) and reuse it to
/// evaluate any number of capabilities.
class CapabilityEvaluator {
  CapabilityEvaluator(this.grantedPermissions);

  /// The permissions the current user holds.
  final Set<PermissionKey> grantedPermissions;

  /// Permissions directly required by [capability] that are not granted
  /// (does not consider prerequisites).
  Set<PermissionKey> missingPermissions(Capability capability) {
    return capability.requiredPermissions
        .where((p) => !grantedPermissions.contains(p))
        .toSet();
  }

  /// Whether the user holds every permission directly required by [capability]
  /// (ignores prerequisites).
  bool hasPermissions(Capability capability) =>
      capability.requiredPermissions.every(grantedPermissions.contains);

  /// Whether [capability] is fully available: all required permissions granted
  /// **and** every prerequisite available (recursively).
  ///
  /// Throws [CapabilityCycleError] if the prerequisites contain a cycle.
  bool isAvailable(Capability capability) => _isAvailable(capability, <String>[]);

  bool _isAvailable(Capability capability, List<String> stack) {
    if (stack.contains(capability.id)) {
      throw CapabilityCycleError([...stack, capability.id]);
    }
    if (!hasPermissions(capability)) return false;

    stack.add(capability.id);
    try {
      for (final prerequisite in capability.prerequisites) {
        if (!_isAvailable(prerequisite, stack)) return false;
      }
    } finally {
      stack.removeLast();
    }
    return true;
  }

  /// Direct prerequisites of [capability] that are not available.
  Set<Capability> unmetPrerequisites(Capability capability) {
    return capability.prerequisites
        .where((prerequisite) => !isAvailable(prerequisite))
        .toSet();
  }

  /// Full evaluation with reasons (missing permissions + unmet prerequisites).
  CapabilityResult evaluate(Capability capability) {
    return CapabilityResult(
      capability: capability,
      isAvailable: isAvailable(capability),
      missingPermissions: missingPermissions(capability),
      unmetPrerequisites: unmetPrerequisites(capability),
    );
  }

  /// Returns only the capabilities from [all] that are currently available.
  List<Capability> availableFrom(Iterable<Capability> all) {
    return all.where(isAvailable).toList();
  }
}


