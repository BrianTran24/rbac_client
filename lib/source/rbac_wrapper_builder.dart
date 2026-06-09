import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class RBACWrapperGenerator extends Generator {
  static final _checker = TypeChecker.fromUrl(
    'package:rbac_client/annotation.dart#GenerateRBACWrapper',
  );

  /// Ex: Input:
  /// abstract class UserService {
  ///   @Access(type: 'permission', permission: AppPermission.userRead)
  ///   Future<String> getUser(String userId);
  ///
  ///   @Access(type: 'self', ownerParam: 'userId')
  ///   Future<void> updateProfile(String userId, String name);
  ///
  ///   Future<void> ping();
  /// }
  ///
  /// Output:
  /// class UserServiceGuarded implements UserService {
  ///   final UserService _inner;
  ///   final RBACSessionStore _sessionStore;
  ///  final RBACUserContextResolver _contextResolver;
  ///
  ///   UserServiceGuarded(this._inner, this._sessionStore, this._contextResolver);
  ///
  ///   @override
  ///   Future<String> getUser(String userId) async {
  ///     final token = await _sessionStore.token;
  ///     final permissions = await _sessionStore.permissions;
  ///     if (token == null || token.isEmpty) {
  ///       throw ForbiddenException('User not authenticated');
  ///     }
  ///     final userContext = _contextResolver.resolve(
  ///       token: token,
  ///       permissions: permissions,
  ///     );
  ///     requirePermission(userContext, AppPermission.userRead);
  ///     return await _inner.getUser(userId);
  ///   }
  ///
  ///   @override
  ///   Future<void> updateProfile(String userId, String name) async {
  ///     final token = await _sessionStore.token;
  ///     final permissions = await _sessionStore.permissions;
  ///     if (token == null || token.isEmpty) {
  ///       throw ForbiddenException('User not authenticated');
  ///     }
  ///     final userContext = _contextResolver.resolve(
  ///       token: token,
  ///       permissions: permissions,
  ///     );
  ///     assertSelfScope(userContext, userId.toString());
  ///     return await _inner.updateProfile(userId, name);
  ///   }
  ///
  ///   @override
  ///   Future<void> ping() {
  ///     return _inner.ping();
  ///   }
  /// }
  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();

    for (final annotated in library.annotatedWith(_checker)) {
      final element = annotated.element;
      final output = _generateForElement(element);
      if (output != null) {
        buffer.writeln(output);
      }
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  String? _generateForElement(Element element) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@GenerateRBACWrapper() can only be used on abstract classes.',
        element: element,
      );
    }

    if (!element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@GenerateRBACWrapper() must annotate an abstract class.',
        element: element,
      );
    }

    final className = element.displayName;
    final wrapperName = '${className}Guarded';

    final buffer = StringBuffer();

    buffer.writeln('class $wrapperName implements $className {');
    buffer.writeln('  final $className _inner;');
    buffer.writeln('  final RBACSessionStore _sessionStore;');
    buffer.writeln('  final RBACUserContextResolver _contextResolver;');
    buffer.writeln('');
    buffer.writeln(
      '  $wrapperName(this._inner, this._sessionStore, this._contextResolver);',
    );
    buffer.writeln('');

    for (final method in element.methods) {
      if (method.isPrivate || method.isStatic) continue;

      final accessAnnotation = _findAccessAnnotation(method);
      final generatedMethod = _generateMethod(method, accessAnnotation);
      buffer.writeln(generatedMethod);
      buffer.writeln('');
    }

    buffer.writeln('}');

    return buffer.toString();
  }


  ///Hàm _findAccessAnnotation() dùng để tìm kiếm annotation @Access trên một method.
  /// Cụ thể:
  /// Duyệt qua tất cả metadata (annotations) của method
  /// Kiểm tra xem annotation nào có tên là 'Access'
  /// Trả về ElementAnnotation đầu tiên tìm thấy, hoặc null nếu không có
  ElementAnnotation? _findAccessAnnotation(MethodElement method) {
    for (final metadata in method.metadata) {
      final value = metadata.computeConstantValue();
      if (value == null) continue;
      if (value.type?.getDisplayString(withNullability: false) == 'Access') {
        return metadata;
      }
    }
    return null;
  }

  String _generateMethod(MethodElement method, ElementAnnotation? annotation) {
    final returnType = method.returnType.getDisplayString(withNullability: true);
    final methodName = method.displayName;
    final generatedGuardCode =
        annotation == null
            ? ''
            : _buildGuardCode(method, annotation.computeConstantValue());
    final requiresGuard = generatedGuardCode.isNotEmpty;

    if (requiresGuard && !_isFutureReturnType(returnType)) {
      throw InvalidGenerationSourceError(
        'Guarded method $methodName must declare Future or Future<T> because generated RBAC checks await asynchronous session state; only unguarded synchronous methods are supported.',
        element: method,
      );
    }

    // Separate required positional, optional positional, and named params
    final positional = method.parameters.where((p) => p.isPositional && p.isRequired);
    final optionalPositional = method.parameters.where((p) => p.isOptional && p.isPositional);
    final named = method.parameters.where((p) => p.isNamed);

    final paramParts = <String>[];
    for (final p in positional) {
      paramParts.add('${p.type.getDisplayString(withNullability: true)} ${p.name}');
    }
    if (optionalPositional.isNotEmpty) {
      final inner = optionalPositional.map((p) {
        final type = p.type.getDisplayString(withNullability: true);
        final defaultVal = p.defaultValueCode != null ? ' = ${p.defaultValueCode}' : '';
        return '$type ${p.name}$defaultVal';
      }).join(', ');
      paramParts.add('[$inner]');
    }
    if (named.isNotEmpty) {
      final inner = named.map((p) {
        final type = p.type.getDisplayString(withNullability: true);
        final req = p.isRequired ? 'required ' : '';
        final defaultVal = p.defaultValueCode != null ? ' = ${p.defaultValueCode}' : '';
        return '$req$type ${p.name}$defaultVal';
      }).join(', ');
      paramParts.add('{$inner}');
    }
    final params = paramParts.join(', ');

    // Build args string (positional first, then named with name: value)
    final argParts = <String>[];
    for (final p in method.parameters) {
      if (p.isNamed) {
        argParts.add('${p.name}: ${p.name}');
      } else {
        argParts.add(p.name);
      }
    }
    final args = argParts.join(', ');

    final buffer = StringBuffer();

    buffer.writeln('  @override');
    buffer.writeln(
      '  $returnType $methodName($params)${requiresGuard ? ' async' : ''} {',
    );

    if (requiresGuard) {
      buffer.writeln('    final token = await _sessionStore.token;');
      buffer.writeln('    final permissions = await _sessionStore.permissions;');
      buffer.writeln('    if (token == null || token.isEmpty) {');
      buffer.writeln('      throw ForbiddenException(\'User not authenticated\');');
      buffer.writeln('    }');
      buffer.writeln(
        '    final userContext = _contextResolver.resolve(token: token, permissions: permissions);',
      );
      buffer.writeln('    $generatedGuardCode');
    }

    if (returnType == 'void') {
      buffer.writeln('    _inner.$methodName($args);');
    } else {
      final awaitKeyword = requiresGuard ? 'await ' : '';
      buffer.writeln('    return ${awaitKeyword}_inner.$methodName($args);');
    }
    buffer.writeln('  }');

    return buffer.toString();
  }

  String _buildGuardCode(MethodElement method, DartObject? accessValue) {
    if (accessValue == null) return '';

    final type = accessValue.getField('type')?.toStringValue();

    final ownerParam = accessValue.getField('ownerParam')?.toStringValue();

    switch (type) {
      case 'none':
        return '';

      case 'permission':
        final permissionExpression = _permissionExpression(accessValue);
        if (permissionExpression == null || permissionExpression.isEmpty) {
          throw InvalidGenerationSourceError(
            'Method ${method.displayName} has @Access.permission with an unsupported permission value. Use an enum value implementing PermissionKey (for example: AppPermission.userRead).',
            element: method,
          );
        }
        return 'requirePermission(userContext, $permissionExpression);';

      case 'self':
        if (ownerParam == null || ownerParam.isEmpty) {
          throw InvalidGenerationSourceError(
            'Method ${method.displayName} has @Access.self but no ownerParam value.',
            element: method,
          );
        }

        final found = method.parameters.any((p) => p.name == ownerParam);
        if (!found) {
          throw InvalidGenerationSourceError(
            'Method ${method.displayName} does not contain ownerParam "$ownerParam".',
            element: method,
          );
        }

        return 'assertSelfScope(userContext, $ownerParam.toString());';

      default:
        throw InvalidGenerationSourceError(
          'Unsupported access type "$type" on method ${method.displayName}.',
          element: method,
        );
    }
  }

  bool _isFutureReturnType(String returnType) {
    return returnType.startsWith('Future<') ||
        returnType == 'Future' ||
        returnType.startsWith('FutureOr<') ||
        returnType == 'FutureOr';
  }

  String? _permissionExpression(DartObject accessValue) {
    final permissionField = accessValue.getField('permission');
    if (permissionField == null || permissionField.isNull) return null;

    final stringValue = permissionField.toStringValue();
    if (stringValue != null) {
      return "'${_escapeDartStringLiteral(stringValue)}'";
    }

    final intValue = permissionField.toIntValue();
    if (intValue != null) return '$intValue';

    final doubleValue = permissionField.toDoubleValue();
    if (doubleValue != null) return '$doubleValue';

    final boolValue = permissionField.toBoolValue();
    if (boolValue != null) return '$boolValue';

    final variable = permissionField.variable;
    final typeName = variable?.enclosingElement?.displayName;
    final valueName = variable?.displayName;
    if (typeName != null && valueName != null) {
      return '$typeName.$valueName';
    }

    return null;
  }

  String _escapeDartStringLiteral(String value) {
    final buffer = StringBuffer();

    for (final rune in value.runes) {
      switch (rune) {
        case 0x5C:
          buffer.write(r'\\');
          break;
        case 0x27:
          buffer.write(r"\'");
          break;
        case 0x24:
          buffer.write(r'\$');
          break;
        case 0x08:
          buffer.write(r'\b');
          break;
        case 0x09:
          buffer.write(r'\t');
          break;
        case 0x0A:
          buffer.write(r'\n');
          break;
        case 0x0B:
          buffer.write(r'\v');
          break;
        case 0x0C:
          buffer.write(r'\f');
          break;
        case 0x0D:
          buffer.write(r'\r');
          break;
        default:
          if (rune < 0x20 || rune == 0x2028 || rune == 0x2029) {
            buffer.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
          } else {
            buffer.write(String.fromCharCode(rune));
          }
          break;
      }
    }

    return buffer.toString();
  }
}