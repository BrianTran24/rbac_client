import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'rbac_wrapper_builder.dart';

Builder rbacWrapperBuilder(BuilderOptions options) =>
    PartBuilder(
      [RBACWrapperGenerator()],
      '.g.dart',
    );