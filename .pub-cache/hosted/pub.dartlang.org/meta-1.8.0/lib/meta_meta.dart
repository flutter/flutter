// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations that describe the intended use of other annotations.
library meta_meta;

/// An annotation used on classes that are intended to be used as annotations
/// to indicate the kinds of declarations and directives for which the
/// annotation is appropriate.
///
/// The kinds are represented by the constants defined in [TargetKind].
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a class, where the
///   class must be usable as an annotation (that is, contain at least one
///   `const` constructor).
/// * the annotated annotation is associated with anything other than the kinds
///   of declarations listed as valid targets.
@Target({TargetKind.classType})
class Target {
  /// The kinds of declarations with which the annotated annotation can be
  /// associated.
  final Set<TargetKind> kinds;

  const Target(this.kinds);
}

/// An enumeration of the kinds of targets to which an annotation can be
/// applied.
enum TargetKind {
  /// Indicates that an annotation is valid on any class declaration.
  classType,

  /// Indicates that an annotation is valid on any enum declaration.
  enumType,

  /// Indicates that an annotation is valid on any extension declaration.
  extension,

  /// Indicates that an annotation is valid on any field declaration, both
  /// instance and static fields, whether it's in a class, mixin or extension.
  field,

  /// Indicates that an annotation is valid on any top-level function
  /// declaration.
  function,

  /// Indicates that an annotation is valid on the first directive in a library,
  /// whether that's a `library`, `import`, `export` or `part` directive. This
  /// doesn't include the `part of` directive in a part file.
  library,

  /// Indicates that an annotation is valid on any getter declaration, both
  /// instance or static getters, whether it's in a class, mixin, extension, or
  /// at the top-level of a library.
  getter,

  /// Indicates that an annotation is valid on any method declaration, both
  /// instance and static methods, whether it's in a class, mixin or extension.
  method,

  /// Indicates that an annotation is valid on any mixin declaration.
  mixinType,

  /// Indicates that an annotation is valid on any formal parameter declaration,
  /// whether it's in a function, method, constructor, or closure.
  parameter,

  /// Indicates that an annotation is valid on any setter declaration, both
  /// instance or static setters, whether it's in a class, mixin, extension, or
  /// at the top-level of a library.
  setter,

  /// Indicates that an annotation is valid on any top-level variable
  /// declaration.
  topLevelVariable,

  /// Indicates that an annotation is valid on any declaration that introduces a
  /// type. This includes classes, enums, mixins and typedefs, but does not
  /// include extensions because extensions don't introduce a type.
  type,

  /// Indicates that an annotation is valid on any typedef declaration.
  typedefType,
}

extension TargetKindExtension on TargetKind {
  /// Return a user visible string used to describe this target kind.
  String get displayString {
    switch (this) {
      case TargetKind.classType:
        return 'classes';
      case TargetKind.enumType:
        return 'enums';
      case TargetKind.extension:
        return 'extensions';
      case TargetKind.field:
        return 'fields';
      case TargetKind.function:
        return 'top-level functions';
      case TargetKind.library:
        return 'libraries';
      case TargetKind.getter:
        return 'getters';
      case TargetKind.method:
        return 'methods';
      case TargetKind.mixinType:
        return 'mixins';
      case TargetKind.parameter:
        return 'parameters';
      case TargetKind.setter:
        return 'setters';
      case TargetKind.topLevelVariable:
        return 'top-level variables';
      case TargetKind.type:
        return 'types (classes, enums, mixins, or typedefs)';
      case TargetKind.typedefType:
        return 'typedefs';
    }
  }
}
