// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// The type builder for a [RecordType].
class RecordTypeBuilder extends TypeBuilder {
  /// The type system of the library with the type name.
  final TypeSystemImpl typeSystem;

  /// The node for which this builder is created.
  final RecordTypeAnnotationImpl node;

  /// The ordered list of field types, first positional, then named.
  final List<DartType> fieldTypes;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// This flag is set to `true` while building this type.
  bool _isBuilding = false;

  /// The actual built type, not a [TypeBuilder] anymore.
  RecordTypeImpl? _type;

  RecordTypeBuilder({
    required this.typeSystem,
    required this.node,
    required this.fieldTypes,
    required this.nullabilitySuffix,
  });

  factory RecordTypeBuilder.of(
    TypeSystemImpl typeSystem,
    RecordTypeAnnotationImpl node,
  ) {
    return RecordTypeBuilder(
      typeSystem: typeSystem,
      node: node,
      fieldTypes: node.fields.map((field) => field.type.typeOrThrow).toList(),
      nullabilitySuffix: node.question != null
          ? NullabilitySuffix.question
          : NullabilitySuffix.none,
    );
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    if (visitor is LinkingTypeVisitor<R>) {
      var visitor2 = visitor as LinkingTypeVisitor<R>;
      return visitor2.visitRecordTypeBuilder(this);
    } else {
      throw StateError('Should not happen outside linking.');
    }
  }

  @override
  RecordTypeImpl build() {
    final type = _type;
    if (type != null) {
      return type;
    }

    if (_isBuilding) {
      return _type = _buildRecordType(
        recursionFound: true,
      );
    }

    _isBuilding = true;
    try {
      return _type = _buildRecordType();
    } finally {
      _isBuilding = false;
    }
  }

  @override
  String toString() {
    return node.toSource();
  }

  RecordTypeImpl _buildRecordType({
    bool recursionFound = false,
  }) {
    var fieldTypeIndex = 0;

    DartType nextFieldType() {
      if (recursionFound) {
        return typeSystem.typeProvider.dynamicType;
      } else {
        final type = fieldTypes[fieldTypeIndex++];
        return _buildType(type);
      }
    }

    final positionalFields = node.positionalFields.map((field) {
      return RecordTypePositionalFieldImpl(
        type: nextFieldType(),
      );
    }).toList();

    final namedFields = node.namedFields?.fields.map((field) {
      return RecordTypeNamedFieldImpl(
        name: field.name.lexeme,
        type: nextFieldType(),
      );
    }).toList();

    return node.type = RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields ?? const [],
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static DartType _buildType(DartType type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }
}
