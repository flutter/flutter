// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [RecordLiteral]s.
class RecordLiteralResolver {
  final ResolverVisitor _resolver;

  RecordLiteralResolver({
    required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ErrorReporter get errorReporter => _resolver.errorReporter;

  /// Report any named fields in the record literal [node] that use a previously
  /// defined name.
  void reportDuplicateFieldDefinitions(RecordLiteralImpl node) {
    var usedNames = <String, NamedExpression>{};
    for (var field in node.fields) {
      if (field is NamedExpressionImpl) {
        var name = field.name.label.name;
        var previousField = usedNames[name];
        if (previousField != null) {
          errorReporter.reportError(DiagnosticFactory()
              .duplicateFieldDefinitionInLiteral(
                  errorReporter.source, field, previousField));
        } else {
          usedNames[name] = field;
        }
      }
    }
  }

  /// Report any fields in the record literal [node] that use an invalid name.
  void reportInvalidFieldNames(RecordLiteralImpl node) {
    var fields = node.fields;
    var positionalCount = 0;
    for (var field in fields) {
      if (field is! NamedExpression) {
        positionalCount++;
      }
    }
    for (var field in fields) {
      if (field is NamedExpressionImpl) {
        var nameNode = field.name.label;
        var name = nameNode.name;
        if (name.startsWith('_')) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, nameNode);
        } else {
          final index = RecordTypeExtension.positionalFieldIndex(name);
          if (index != null) {
            if (index < positionalCount) {
              errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, nameNode);
            }
          } else {
            var objectElement = _resolver.typeProvider.objectElement;
            if (objectElement.getGetter(name) != null ||
                objectElement.getMethod(name) != null) {
              errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT,
                  nameNode);
            }
          }
        }
      }
    }
  }

  void resolve(
    RecordLiteralImpl node, {
    required DartType? contextType,
  }) {
    _resolveFields(node, contextType);
    _buildType(node, contextType);

    reportDuplicateFieldDefinitions(node);
    reportInvalidFieldNames(node);
  }

  void _buildType(RecordLiteralImpl node, DartType? contextType) {
    final positionalFields = <RecordTypePositionalFieldImpl>[];
    final namedFields = <RecordTypeNamedFieldImpl>[];
    for (final field in node.fields) {
      final fieldType = field.typeOrThrow;
      if (field is NamedExpressionImpl) {
        namedFields.add(
          RecordTypeNamedFieldImpl(
            name: field.name.label.name,
            type: fieldType,
          ),
        );
      } else {
        positionalFields.add(
          RecordTypePositionalFieldImpl(
            type: fieldType,
          ),
        );
      }
    }

    _resolver.inferenceHelper.recordStaticType(
      node,
      RecordTypeImpl(
        positionalFields: positionalFields,
        namedFields: namedFields,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      contextType: contextType,
    );
  }

  void _resolveField(ExpressionImpl field, DartType? contextType) {
    _resolver.analyzeExpression(field, contextType);
    field = _resolver.popRewrite()!;

    // Implicit cast from `dynamic`.
    if (contextType != null && field.typeOrThrow.isDynamic) {
      field.staticType = contextType;
      if (field is NamedExpressionImpl) {
        field.expression.staticType = contextType;
      }
    }
  }

  void _resolveFields(RecordLiteralImpl node, DartType? contextType) {
    if (contextType is RecordType) {
      var index = 0;
      for (final field in node.fields) {
        DartType? fieldContextType;
        if (field is NamedExpressionImpl) {
          final name = field.name.label.name;
          fieldContextType = contextType.namedField(name)?.type;
        } else {
          final positionalFields = contextType.positionalFields;
          if (index < positionalFields.length) {
            fieldContextType = positionalFields[index++].type;
          }
        }
        _resolveField(field, fieldContextType);
      }
    } else {
      for (final field in node.fields) {
        _resolveField(field, null);
      }
    }
  }
}
