// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta_meta.dart';

extension ElementAnnotationExtensions on ElementAnnotation {
  static final Map<String, TargetKind> _targetKindsByName = {
    for (final kind in TargetKind.values) kind.toString(): kind,
  };

  /// Return the target kinds defined for this [ElementAnnotation].
  Set<TargetKind> get targetKinds {
    final element = this.element;
    ClassElement? classElement;
    if (element is PropertyAccessorElement) {
      if (element.isGetter) {
        var type = element.returnType;
        if (type is InterfaceType) {
          classElement = type.element;
        }
      }
    } else if (element is ConstructorElement) {
      classElement = element.enclosingElement;
    }
    if (classElement == null) {
      return const <TargetKind>{};
    }
    for (var annotation in classElement.metadata) {
      if (annotation.isTarget) {
        var value = annotation.computeConstantValue()!;
        var kinds = <TargetKind>{};

        for (var kindObject in value.getField('kinds')!.toSetValue()!) {
          // We can't directly translate the index from the analyzed TargetKind
          // constant to TargetKinds.values because the analyzer from the SDK
          // may have been compiled with a different version of pkg:meta.
          var index = kindObject.getField('index')!.toIntValue()!;
          var targetKindClass =
              (kindObject.type as InterfaceType).element as EnumElementImpl;
          // Instead, map constants to their TargetKind by comparing getter
          // names.
          var getter = targetKindClass.constants[index];
          var name = 'TargetKind.${getter.name}';

          var foundTargetKind = _targetKindsByName[name];
          if (foundTargetKind != null) {
            kinds.add(foundTargetKind);
          }
        }
        return kinds;
      }
    }
    return const <TargetKind>{};
  }
}

extension ElementExtension on Element {
  /// Return `true` if this element is an instance member of a class or mixin.
  ///
  /// Only [MethodElement]s and [PropertyAccessorElement]s are supported.
  /// We intentionally exclude [ConstructorElement]s - they can only be
  /// invoked in instance creation expressions, and [FieldElement]s - they
  /// cannot be invoked directly and are always accessed using corresponding
  /// [PropertyAccessorElement]s.
  bool get isInstanceMember {
    var this_ = this;
    var enclosing = this_.enclosingElement;
    if (enclosing is ClassElement) {
      return this_ is MethodElement && !this_.isStatic ||
          this_ is PropertyAccessorElement && !this_.isStatic;
    }
    return false;
  }

  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@doNotStore`
  /// annotation.
  bool get hasOrInheritsDoNotStore {
    if (hasDoNotStore) {
      return true;
    }

    var ancestor = enclosingElement;
    if (ancestor is ClassElement) {
      if (ancestor.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement;
    } else if (ancestor is ExtensionElement) {
      if (ancestor.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement;
    }

    return ancestor is CompilationUnitElement &&
        ancestor.enclosingElement.hasDoNotStore;
  }
}

extension ParameterElementExtensions on ParameterElement {
  /// Return [ParameterElement] with the specified properties replaced.
  ParameterElement copyWith({
    DartType? type,
    ParameterKind? kind,
    bool? isCovariant,
  }) {
    return ParameterElementImpl.synthetic(
      name,
      type ?? this.type,
      // ignore: deprecated_member_use_from_same_package
      kind ?? parameterKind,
    )..isExplicitlyCovariant = isCovariant ?? this.isCovariant;
  }
}
