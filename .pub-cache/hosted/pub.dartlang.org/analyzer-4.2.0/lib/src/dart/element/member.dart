// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class ConstructorMember extends ExecutableMember
    with ConstructorElementMixin
    implements ConstructorElement {
  /// Initialize a newly created element to represent a constructor, based on
  /// the [declaration], and applied [substitution].
  ConstructorMember(
    TypeProviderImpl? typeProvider,
    ConstructorElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) : super(typeProvider, declaration, substitution, isLegacy,
            const <TypeParameterElement>[]);

  @override
  ConstructorElement get declaration => super.declaration as ConstructorElement;

  @override
  String get displayName => declaration.displayName;

  @override
  ClassElement get enclosingElement => declaration.enclosingElement;

  @override
  bool get isConst => declaration.isConst;

  @override
  bool get isConstantEvaluated => declaration.isConstantEvaluated;

  @override
  bool get isFactory => declaration.isFactory;

  @override
  String get name => declaration.name;

  @override
  int? get nameEnd => declaration.nameEnd;

  @override
  int? get periodOffset => declaration.periodOffset;

  @override
  ConstructorElement? get redirectedConstructor {
    var element = this.declaration.redirectedConstructor;
    if (element == null) {
      return null;
    }

    ConstructorElement declaration;
    MapSubstitution substitution;
    if (element is ConstructorMember) {
      declaration = element._declaration as ConstructorElement;
      var map = <TypeParameterElement, DartType>{};
      var elementMap = element._substitution.map;
      for (var typeParameter in elementMap.keys) {
        var type = elementMap[typeParameter]!;
        map[typeParameter] = _substitution.substituteType(type);
      }
      substitution = Substitution.fromMap(map);
    } else {
      declaration = element;
      substitution = _substitution;
    }

    return ConstructorMember(_typeProvider, declaration, substitution, false);
  }

  @override
  InterfaceType get returnType => type.returnType as InterfaceType;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// If the given [constructor]'s type is different when any type parameters
  /// from the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a constructor member
  /// representing the given constructor. Return the member that was created, or
  /// the original constructor if no member was created.
  static ConstructorElement from(
      ConstructorElement constructor, InterfaceType definingType) {
    if (definingType.typeArguments.isEmpty) {
      return constructor;
    }

    var isLegacy = false;
    if (constructor is ConstructorMember) {
      isLegacy = constructor.isLegacy;
      constructor = constructor.declaration;
    }

    return ConstructorMember(
      constructor.library.typeProvider as TypeProviderImpl,
      constructor,
      Substitution.fromInterfaceType(definingType),
      isLegacy,
    );
  }
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class ExecutableMember extends Member implements ExecutableElement {
  @override
  final List<TypeParameterElement> typeParameters;

  FunctionType? _type;

  /// Initialize a newly created element to represent a callable element (like a
  /// method or function or property), based on the [declaration], and applied
  /// [substitution].
  ///
  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [declaration] type
  /// parameters with the provided fresh [typeParameters].
  ExecutableMember(
    super.typeProvider,
    ExecutableElement super.declaration,
    super.substitution,
    super.isLegacy,
    this.typeParameters,
  );

  @override
  ExecutableElement get declaration => super.declaration as ExecutableElement;

  @override
  String get displayName => declaration.displayName;

  @override
  bool get hasImplicitReturnType => declaration.hasImplicitReturnType;

  @override
  bool get isAbstract => declaration.isAbstract;

  @override
  bool get isAsynchronous => declaration.isAsynchronous;

  @override
  bool get isExternal => declaration.isExternal;

  @override
  bool get isGenerator => declaration.isGenerator;

  @override
  bool get isOperator => declaration.isOperator;

  @override
  bool get isSimplyBounded => declaration.isSimplyBounded;

  @override
  bool get isStatic => declaration.isStatic;

  @override
  bool get isSynchronous => declaration.isSynchronous;

  @override
  LibraryElement get library => _declaration.library!;

  @override
  Source get librarySource => _declaration.librarySource!;

  @override
  List<ParameterElement> get parameters {
    return declaration.parameters.map<ParameterElement>((p) {
      if (p is FieldFormalParameterElement) {
        return FieldFormalParameterMember(
            _typeProvider, p, _substitution, isLegacy);
      }
      if (p is SuperFormalParameterElement) {
        return SuperFormalParameterMember(
            _typeProvider, p, _substitution, isLegacy);
      }
      return ParameterMember(_typeProvider, p, _substitution, isLegacy);
    }).toList();
  }

  @override
  DartType get returnType => type.returnType;

  @override
  FunctionType get type {
    if (_type != null) return _type!;

    _type = _substitution.substituteType(declaration.type) as FunctionType;
    _type = _toLegacyType(_type!) as FunctionType;
    return _type!;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }

  static ExecutableElement from2(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    TypeProviderImpl? typeProvider;
    var isLegacy = false;
    var combined = substitution;
    if (element is ExecutableMember) {
      ExecutableMember member = element;
      element = member.declaration;
      typeProvider = member._typeProvider;

      isLegacy = member.isLegacy;

      var map = <TypeParameterElement, DartType>{};
      for (var entry in member._substitution.map.entries) {
        map[entry.key] = substitution.substituteType(entry.value);
      }
      map.addAll(substitution.map);
      combined = Substitution.fromMap(map);
    } else {
      typeProvider = element.library.typeProvider as TypeProviderImpl;
    }

    if (!isLegacy && combined.map.isEmpty) {
      return element;
    }

    if (element is ConstructorElement) {
      return ConstructorMember(typeProvider, element, combined, isLegacy);
    } else if (element is MethodElement) {
      return MethodMember(typeProvider, element, combined, isLegacy);
    } else if (element is PropertyAccessorElement) {
      return PropertyAccessorMember(typeProvider, element, combined, isLegacy);
    } else {
      throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class FieldFormalParameterMember extends ParameterMember
    implements FieldFormalParameterElement {
  factory FieldFormalParameterMember(
    TypeProviderImpl? typeProvider,
    FieldFormalParameterElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return FieldFormalParameterMember._(
      typeProvider,
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  FieldFormalParameterMember._(
    super.typeProvider,
    FieldFormalParameterElement super.declaration,
    super.substitution,
    super.isLegacy,
    super.typeParameters,
  ) : super._();

  @override
  FieldElement? get field {
    var field = (declaration as FieldFormalParameterElement).field;
    if (field == null) {
      return null;
    }

    return FieldMember(_typeProvider, field, _substitution, isLegacy);
  }

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class FieldMember extends VariableMember implements FieldElement {
  /// Initialize a newly created element to represent a field, based on the
  /// [declaration], with applied [substitution].
  FieldMember(
    super.typeProvider,
    FieldElement super.declaration,
    super.substitution,
    super.isLegacy,
  );

  @override
  FieldElement get declaration => super.declaration as FieldElement;

  @override
  String get displayName => declaration.displayName;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  PropertyAccessorElement? get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        _typeProvider, baseGetter, _substitution, isLegacy);
  }

  @override
  bool get hasInitializer => declaration.hasInitializer;

  @override
  bool get isAbstract => declaration.isAbstract;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isEnumConstant => declaration.isEnumConstant;

  @override
  bool get isExternal => declaration.isExternal;

  @override
  LibraryElement get library => _declaration.library!;

  @override
  String get name => declaration.name;

  @override
  PropertyAccessorElement? get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        _typeProvider, baseSetter, _substitution, isLegacy);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);

  /// If the given [field]'s type is different when any type parameters from the
  /// defining type's declaration are replaced with the actual type arguments
  /// from the [definingType], create a field member representing the given
  /// field. Return the member that was created, or the base field if no member
  /// was created.
  static FieldElement from(FieldElement field, InterfaceType definingType) {
    if (definingType.typeArguments.isEmpty) {
      return field;
    }
    return FieldMember(
      field.library.typeProvider as TypeProviderImpl,
      field,
      Substitution.fromInterfaceType(definingType),
      false,
    );
  }

  static FieldElement from2(
    FieldElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    var typeProvider = element.library.typeProvider as TypeProviderImpl;
    return FieldMember(typeProvider, element, substitution, false);
  }
}

class FunctionMember extends ExecutableMember implements FunctionElement {
  FunctionMember(TypeProviderImpl? typeProvider, FunctionElement declaration,
      bool isLegacy)
      : super(
          typeProvider,
          declaration,
          Substitution.empty,
          isLegacy,
          declaration.typeParameters,
        );

  @override
  FunctionElement get declaration => super.declaration as FunctionElement;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  bool get isDartCoreIdentical => declaration.isDartCoreIdentical;

  @override
  bool get isEntryPoint => declaration.isEntryPoint;

  @override
  String get name => declaration.name;

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitFunctionElement(this);
  }
}

/// An element defined in a parameterized type where the values of the type
/// parameters are known.
abstract class Member implements Element {
  /// A type provider (might be legacy, might be null-safe).
  final TypeProviderImpl? _typeProvider;

  /// The element on which the parameterized element was created.
  final Element _declaration;

  /// The substitution for type parameters referenced in the base element.
  final MapSubstitution _substitution;

  /// If `true`, then this is a legacy view on a NNBD element.
  final bool isLegacy;

  /// Initialize a newly created element to represent a member, based on the
  /// [declaration], and applied [_substitution].
  Member(this._typeProvider, this._declaration, this._substitution,
      this.isLegacy) {
    if (_declaration is Member) {
      throw StateError('Members must be created from a declarations.');
    }
    if (_typeProvider == null && isLegacy) {
      throw StateError(
          'A type provider must be supplied for legacy conversion');
    }
  }

  @override
  AnalysisContext get context => _declaration.context;

  @override
  Element get declaration => _declaration;

  @override
  String get displayName => _declaration.displayName;

  @override
  String? get documentationComment => _declaration.documentationComment;

  @override
  Element? get enclosingElement => _declaration.enclosingElement;

  @override
  bool get hasAlwaysThrows => _declaration.hasAlwaysThrows;

  @override
  bool get hasDeprecated => _declaration.hasDeprecated;

  @override
  bool get hasDoNotStore => _declaration.hasDoNotStore;

  @override
  bool get hasFactory => _declaration.hasFactory;

  @override
  bool get hasInternal => _declaration.hasInternal;

  @override
  bool get hasIsTest => _declaration.hasIsTest;

  @override
  bool get hasIsTestGroup => _declaration.hasIsTestGroup;

  @override
  bool get hasJS => _declaration.hasJS;

  @override
  bool get hasLiteral => _declaration.hasLiteral;

  @override
  bool get hasMustCallSuper => _declaration.hasMustCallSuper;

  @override
  bool get hasNonVirtual => _declaration.hasNonVirtual;

  @override
  bool get hasOptionalTypeArgs => _declaration.hasOptionalTypeArgs;

  @override
  bool get hasOverride => _declaration.hasOverride;

  @override
  bool get hasProtected => _declaration.hasProtected;

  @override
  bool get hasRequired => _declaration.hasRequired;

  @override
  bool get hasSealed => _declaration.hasSealed;

  @override
  bool get hasUseResult => _declaration.hasUseResult;

  @override
  bool get hasVisibleForOverriding => _declaration.hasVisibleForOverriding;

  @override
  bool get hasVisibleForTemplate => _declaration.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => _declaration.hasVisibleForTesting;

  @override
  int get id => _declaration.id;

  @override
  bool get isPrivate => _declaration.isPrivate;

  @override
  bool get isPublic => _declaration.isPublic;

  @override
  bool get isSynthetic => _declaration.isSynthetic;

  @override
  ElementKind get kind => _declaration.kind;

  @override
  LibraryElement? get library => _declaration.library;

  @override
  Source? get librarySource => _declaration.librarySource;

  @override
  ElementLocation get location => _declaration.location!;

  @override
  List<ElementAnnotation> get metadata => _declaration.metadata;

  @override
  String? get name => _declaration.name;

  @override
  int get nameLength => _declaration.nameLength;

  @override
  int get nameOffset => _declaration.nameOffset;

  @override
  Element get nonSynthetic => _declaration.nonSynthetic;

  @override
  AnalysisSession? get session => _declaration.session;

  @override
  Source get source => _declaration.source!;

  /// The substitution for type parameters referenced in the base element.
  MapSubstitution get substitution => _substitution;

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  String getDisplayString({
    required bool withNullability,
    bool multiline = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      skipAllDynamicArguments: false,
      withNullability: withNullability,
      multiline: multiline,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  String getExtendedDisplayName(String? shortName) =>
      _declaration.getExtendedDisplayName(shortName);

  @Deprecated('Use isAccessibleIn2() instead')
  @override
  bool isAccessibleIn(LibraryElement? library) =>
      _declaration.isAccessibleIn(library);

  @override
  bool isAccessibleIn2(LibraryElement library) =>
      _declaration.isAccessibleIn2(library);

  /// Use the given [visitor] to visit all of the [children].
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    // TODO(brianwilkerson) Make this private
    for (Element child in children) {
      child.accept(visitor);
    }
  }

  @override
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return declaration.thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() =>
      declaration.thisOrAncestorOfType<E>();

  @override
  String toString() {
    return getDisplayString(withNullability: false);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }

  /// If this member is a legacy view, erase nullability from the [type].
  /// Otherwise, return the type unchanged.
  DartType _toLegacyType(DartType type) {
    if (isLegacy) {
      return NullabilityEliminator.perform(_typeProvider!, type);
    } else {
      return type;
    }
  }

  /// Return the legacy view of them [element], so that all its types, and
  /// types of any elements that are returned from it, are legacy types.
  ///
  /// If the [element] is declared in a legacy library, return it unchanged.
  static Element legacy(Element element) {
    if (element is ConstructorElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else if (element is Member) {
        var member = element as Member;
        return ConstructorMember(
          member._typeProvider,
          member._declaration as ConstructorElement,
          member._substitution,
          true,
        );
      } else {
        var typeProvider = element.library.typeProvider as TypeProviderImpl;
        return ConstructorMember(
            typeProvider, element, Substitution.empty, true);
      }
    } else if (element is FunctionElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else {
        var typeProvider = element is Member
            ? (element as Member)._typeProvider
            : element.library.typeProvider as TypeProviderImpl;
        return FunctionMember(
            typeProvider, element.declaration as FunctionElement, true);
      }
    } else if (element is MethodElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else if (element is Member) {
        var member = element as Member;
        return MethodMember(
          member._typeProvider,
          member._declaration as MethodElement,
          member._substitution,
          true,
        );
      } else {
        var typeProvider = element.library.typeProvider as TypeProviderImpl;
        return MethodMember(typeProvider, element, Substitution.empty, true);
      }
    } else if (element is PropertyAccessorElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else if (element is Member) {
        var member = element as Member;
        return PropertyAccessorMember(
          member._typeProvider,
          member._declaration as PropertyAccessorElement,
          member._substitution,
          true,
        );
      } else {
        var typeProvider = element.library.typeProvider as TypeProviderImpl;
        return PropertyAccessorMember(
            typeProvider, element, Substitution.empty, true);
      }
    } else {
      return element;
    }
  }
}

/// A method element defined in a parameterized type where the values of the
/// type parameters are known.
class MethodMember extends ExecutableMember implements MethodElement {
  factory MethodMember(
    TypeProviderImpl? typeProvider,
    MethodElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return MethodMember._(
      typeProvider,
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  MethodMember._(
    super.typeProvider,
    MethodElement super.declaration,
    super.substitution,
    super.isLegacy,
    super.typeParameters,
  );

  @override
  MethodElement get declaration => super.declaration as MethodElement;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  String get name => declaration.name;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);

  /// If the given [method]'s type is different when any type parameters from
  /// the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a method member representing the
  /// given method. Return the member that was created, or the base method if no
  /// member was created.
  static MethodElement? from(
      MethodElement? method, InterfaceType definingType) {
    if (method == null || definingType.typeArguments.isEmpty) {
      return method;
    }

    var typeProvider = method.library.typeProvider as TypeProviderImpl;
    return MethodMember(
      typeProvider,
      method,
      Substitution.fromInterfaceType(definingType),
      false,
    );
  }

  static MethodElement from2(
    MethodElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    var typeProvider = element.library.typeProvider as TypeProviderImpl;
    return MethodMember(typeProvider, element, substitution, false);
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class ParameterMember extends VariableMember
    with ParameterElementMixin
    implements ParameterElement {
  @override
  final List<TypeParameterElement> typeParameters;

  factory ParameterMember(
    TypeProviderImpl? typeProvider,
    ParameterElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return ParameterMember._(
      typeProvider,
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  /// Initialize a newly created element to represent a parameter, based on the
  /// [declaration], with applied [substitution].
  ParameterMember._(
    super.typeProvider,
    ParameterElement super.declaration,
    super.substitution,
    super.isLegacy,
    this.typeParameters,
  );

  @override
  ParameterElement get declaration => super.declaration as ParameterElement;

  @override
  String? get defaultValueCode => declaration.defaultValueCode;

  @override
  Element? get enclosingElement => declaration.enclosingElement;

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  int get hashCode => declaration.hashCode;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isInitializingFormal => declaration.isInitializingFormal;

  @override
  bool get isSuperFormal => declaration.isSuperFormal;

  @override
  String get name => declaration.name;

  @deprecated
  @override
  ParameterKind get parameterKind {
    var kind = declaration.parameterKind;
    if (isLegacy && kind == ParameterKind.NAMED_REQUIRED) {
      return ParameterKind.NAMED;
    }
    return kind;
  }

  @override
  List<ParameterElement> get parameters {
    final type = this.type;
    if (type is FunctionType) {
      return type.parameters;
    }
    return const <ParameterElement>[];
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }

  static ParameterElement from(
      ParameterElement element, MapSubstitution substitution) {
    TypeProviderImpl? typeProvider;
    var isLegacy = false;
    var combined = substitution;
    if (element is ParameterMember) {
      var member = element;
      element = member.declaration;
      typeProvider = member._typeProvider;

      isLegacy = member.isLegacy;

      var map = <TypeParameterElement, DartType>{};
      for (var entry in member._substitution.map.entries) {
        map[entry.key] = substitution.substituteType(entry.value);
      }
      map.addAll(substitution.map);
      combined = Substitution.fromMap(map);
    }

    if (!isLegacy && combined.map.isEmpty) {
      return element;
    }

    return ParameterMember(typeProvider, element, combined, isLegacy);
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
class PropertyAccessorMember extends ExecutableMember
    implements PropertyAccessorElement {
  factory PropertyAccessorMember(
    TypeProviderImpl? typeProvider,
    PropertyAccessorElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return PropertyAccessorMember._(
      typeProvider,
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  PropertyAccessorMember._(
    super.typeProvider,
    PropertyAccessorElement super.declaration,
    super.substitution,
    super.isLegacy,
    super.typeParameters,
  );

  @override
  PropertyAccessorElement? get correspondingGetter {
    var baseGetter = declaration.correspondingGetter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        _typeProvider, baseGetter, _substitution, isLegacy);
  }

  @override
  PropertyAccessorElement? get correspondingSetter {
    var baseSetter = declaration.correspondingSetter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        _typeProvider, baseSetter, _substitution, isLegacy);
  }

  @override
  PropertyAccessorElement get declaration =>
      super.declaration as PropertyAccessorElement;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  bool get isGetter => declaration.isGetter;

  @override
  bool get isSetter => declaration.isSetter;

  @override
  String get name => declaration.name;

  @override
  PropertyInducingElement get variable {
    // TODO
    PropertyInducingElement variable = declaration.variable;
    if (variable is FieldElement) {
      return FieldMember(_typeProvider, variable, _substitution, isLegacy);
    } else if (variable is TopLevelVariableElement) {
      return TopLevelVariableMember(
          _typeProvider, variable, _substitution, isLegacy);
    }
    return variable;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (isGetter ? 'get ' : 'set ') + variable.displayName,
    );
  }

  /// If the given [accessor]'s type is different when any type parameters from
  /// the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create an accessor member representing
  /// the given accessor. Return the member that was created, or the base
  /// accessor if no member was created.
  static PropertyAccessorElement? from(
      PropertyAccessorElement? accessor, InterfaceType definingType) {
    if (accessor == null || definingType.typeArguments.isEmpty) {
      return accessor;
    }

    var typeProvider = accessor.library.typeProvider as TypeProviderImpl;
    return PropertyAccessorMember(
      typeProvider,
      accessor,
      Substitution.fromInterfaceType(definingType),
      false,
    );
  }
}

class SuperFormalParameterMember extends ParameterMember
    implements SuperFormalParameterElement {
  factory SuperFormalParameterMember(
    TypeProviderImpl? typeProvider,
    SuperFormalParameterElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return SuperFormalParameterMember._(
      typeProvider,
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  SuperFormalParameterMember._(
    super.typeProvider,
    SuperFormalParameterElement super.declaration,
    super.substitution,
    super.isLegacy,
    super.typeParameters,
  ) : super._();

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  ParameterElement? get superConstructorParameter {
    var superConstructorParameter =
        (declaration as SuperFormalParameterElement).superConstructorParameter;
    if (superConstructorParameter == null) {
      return null;
    }

    return ParameterMember.from(superConstructorParameter, substitution);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitSuperFormalParameterElement(this);
}

class TopLevelVariableMember extends VariableMember
    implements TopLevelVariableElement {
  TopLevelVariableMember(
    super.typeProvider,
    super.declaration,
    super.substitution,
    super.isLegacy,
  );

  @override
  TopLevelVariableElement get declaration =>
      _declaration as TopLevelVariableElement;

  @override
  String get displayName => declaration.displayName;

  @override
  PropertyAccessorElement? get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        _typeProvider, baseGetter, _substitution, isLegacy);
  }

  @override
  bool get hasInitializer => declaration.hasInitializer;

  @override
  bool get isExternal => declaration.isExternal;

  @override
  LibraryElement get library => _declaration.library!;

  @override
  String get name => declaration.name;

  @override
  PropertyAccessorElement? get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        _typeProvider, baseSetter, _substitution, isLegacy);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTopLevelVariableElement(this);
  }
}

/// A variable element defined in a parameterized type where the values of the
/// type parameters are known.
abstract class VariableMember extends Member implements VariableElement {
  DartType? _type;

  /// Initialize a newly created element to represent a variable, based on the
  /// [declaration], with applied [substitution].
  VariableMember(
    super.typeProvider,
    VariableElement super.declaration,
    super.substitution,
    super.isLegacy,
  );

  @override
  VariableElement get declaration => super.declaration as VariableElement;

  @override
  bool get hasImplicitType => declaration.hasImplicitType;

  @override
  bool get isConst => declaration.isConst;

  @override
  bool get isConstantEvaluated => declaration.isConstantEvaluated;

  @override
  bool get isFinal => declaration.isFinal;

  @override
  bool get isLate => declaration.isLate;

  @override
  bool get isStatic => declaration.isStatic;

  @override
  DartType get type {
    if (_type != null) return _type!;

    _type = _substitution.substituteType(declaration.type);
    _type = _toLegacyType(_type!);
    return _type!;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() => declaration.computeConstantValue();
}

class _SubstitutedTypeParameters {
  final List<TypeParameterElement> elements;
  final MapSubstitution substitution;

  factory _SubstitutedTypeParameters(
    List<TypeParameterElement> elements,
    MapSubstitution substitution,
  ) {
    if (elements.isEmpty) {
      return _SubstitutedTypeParameters._(elements, substitution);
    }

    // Create type formals with specialized bounds.
    // For example `<U extends T>` where T comes from an outer scope.
    var newElements = <TypeParameterElement>[];
    var newTypes = <TypeParameterType>[];
    for (int i = 0; i < elements.length; i++) {
      var element = elements[i];
      var newElement = TypeParameterElementImpl.synthetic(element.name);
      newElements.add(newElement);
      newTypes.add(
        newElement.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
    }

    // Update bounds to reference new TypeParameterElement(s).
    var substitution2 = Substitution.fromPairs(elements, newTypes);
    for (int i = 0; i < newElements.length; i++) {
      var element = elements[i];
      var newElement = newElements[i] as TypeParameterElementImpl;
      var bound = element.bound;
      if (bound != null) {
        var newBound = substitution.substituteType(bound);
        newBound = substitution2.substituteType(newBound);
        newElement.bound = newBound;
      }
    }

    if (substitution.map.isEmpty) {
      return _SubstitutedTypeParameters._(newElements, substitution2);
    }

    return _SubstitutedTypeParameters._(
      newElements,
      Substitution.fromMap({
        ...substitution.map,
        ...substitution2.map,
      }),
    );
  }

  _SubstitutedTypeParameters._(this.elements, this.substitution);
}
