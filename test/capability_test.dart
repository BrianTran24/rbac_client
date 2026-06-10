import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_client/rbac.dart';

enum P implements PermissionKey {
  view('view'),
  add('add'),
  delete('delete');

  @override
  final String code;
  const P(this.code);
}

const view = FeatureCapability('view', requiredPermissions: {P.view});
const manage = FeatureCapability(
  'manage',
  requiredPermissions: {P.add, P.delete},
  prerequisites: {view},
);

void main() {
  group('CapabilityEvaluator', () {
    test('available when permissions and prerequisites are satisfied', () {
      final evaluator = CapabilityEvaluator({P.view, P.add, P.delete});

      expect(evaluator.isAvailable(view), isTrue);
      expect(evaluator.isAvailable(manage), isTrue);
    });

    test('unavailable when a required permission is missing', () {
      final evaluator = CapabilityEvaluator({P.view, P.add}); // no delete

      expect(evaluator.isAvailable(manage), isFalse);
      expect(evaluator.missingPermissions(manage), {P.delete});
    });

    test('unavailable when a prerequisite is not met', () {
      // Has add+delete but NOT view → prerequisite "view" fails.
      final evaluator = CapabilityEvaluator({P.add, P.delete});

      expect(evaluator.isAvailable(manage), isFalse);
      expect(evaluator.unmetPrerequisites(manage), {view});
    });

    test('evaluate reports both reasons', () {
      final evaluator = CapabilityEvaluator({P.add}); // missing delete + view

      final result = evaluator.evaluate(manage);
      expect(result.isAvailable, isFalse);
      expect(result.missingPermissions, {P.delete});
      expect(result.unmetPrerequisites, {view});
      expect(result.hasAllPermissions, isFalse);
    });

    test('availableFrom filters the available capabilities', () {
      final evaluator = CapabilityEvaluator({P.view});

      expect(evaluator.availableFrom([view, manage]), [view]);
    });

    test('throws CapabilityCycleError on prerequisite cycles', () {
      // Build a mutable cycle: a -> b -> a
      final a = _MutableCapability('a', requiredPermissions: {P.view});
      final b = _MutableCapability('b', requiredPermissions: {P.view});
      a.prerequisites.add(b);
      b.prerequisites.add(a);

      final evaluator = CapabilityEvaluator({P.view});

      expect(
        () => evaluator.isAvailable(a),
        throwsA(isA<CapabilityCycleError>()),
      );
    });
  });
}

/// Test-only mutable capability to construct cycles.
class _MutableCapability implements Capability {
  _MutableCapability(this.id, {Set<PermissionKey>? requiredPermissions})
      : requiredPermissions = requiredPermissions ?? {},
        prerequisites = {};

  @override
  final String id;
  @override
  final Set<PermissionKey> requiredPermissions;
  @override
  final Set<Capability> prerequisites;
}

