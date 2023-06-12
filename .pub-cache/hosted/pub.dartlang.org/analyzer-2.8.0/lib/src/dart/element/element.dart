// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart'
    show Namespace, NamespaceBuilder;
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/inference_error.dart';

/// A concrete implementation of a [ClassElement].
abstract class AbstractClassElementImpl extends _ExistingElementImpl
    implements ClassElement {
  /// The type defined by the class.
  InterfaceType? _thisType;

  /// A list containing all of the accessors (getters and setters) contained in
  /// this class.
  List<PropertyAccessorElement> _accessors = _Sentinel.propertyAccessorElement;

  /// A list containing all of the fields contained in this class.
  List<FieldElement> _fields = _Sentinel.fieldElement;

  /// A list containing all of the methods contained in this class.
  List<MethodElement> _methods = _Sentinel.methodElement;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  AbstractClassElementImpl(String name, int offset) : super(name, offset);

  /// Set the accessors contained in this class to the given [accessors].
  set accessors(List<PropertyAccessorElement> accessors) {
    assert(!isMixinApplication);
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  String get displayName => name;

  @override
  CompilationUnitElementImpl get enclosingElement {
    return _enclosingElement as CompilationUnitElementImpl;
  }

  /// Set the fields contained in this class to the given [fields].
  set fields(List<FieldElement> fields) {
    assert(!isMixinApplication);
    for (FieldElement field in fields) {
      (field as FieldElementImpl).enclosingElement = this;
    }
    _fields = fields;
  }

  @override
  bool get isDartCoreObject => false;

  @override
  bool get isEnum => false;

  @override
  bool get isMixin => false;

  @override
  List<InterfaceType> get superclassConstraints => const <InterfaceType>[];

  @override
  InterfaceType get thisType {
    if (_thisType == null) {
      List<DartType> typeArguments;
      if (typeParameters.isNotEmpty) {
        typeArguments = typeParameters.map<DartType>((t) {
          return t.instantiate(nullabilitySuffix: _noneOrStarSuffix);
        }).toList();
      } else {
        typeArguments = const <DartType>[];
      }
      return _thisType = instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: _noneOrStarSuffix,
      );
    }
    return _thisType!;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitClassElement(this);

  @override
  FieldElement? getField(String name) {
    for (FieldElement fieldElement in fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) {
    int length = accessors.length;
    for (int i = 0; i < length; i++) {
      PropertyAccessorElement accessor = accessors[i];
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String methodName) {
    int length = methods.length;
    for (int i = 0; i < length; i++) {
      MethodElement method = methods[i];
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return getSetterFromAccessors(setterName, accessors);
  }

  @override
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    if (typeArguments.length != typeParameters.length) {
      var ta = 'typeArguments.length (${typeArguments.length})';
      var tp = 'typeParameters.length (${typeParameters.length})';
      throw ArgumentError('$ta != $tp');
    }
    return InterfaceTypeImpl(
      element: this,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  MethodElement? lookUpConcreteMethod(
          String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName).where(
          (MethodElement method) =>
              !method.isAbstract && method.isAccessibleIn(library)));

  @override
  PropertyAccessorElement? lookUpGetter(
          String getterName, LibraryElement library) =>
      _first(_implementationsOfGetter(getterName).where(
          (PropertyAccessorElement getter) => getter.isAccessibleIn(library)));

  @override
  PropertyAccessorElement? lookUpInheritedConcreteGetter(
          String getterName, LibraryElement library) =>
      _first(_implementationsOfGetter(getterName).where(
          (PropertyAccessorElement getter) =>
              !getter.isAbstract &&
              !getter.isStatic &&
              getter.isAccessibleIn(library) &&
              getter.enclosingElement != this));

  ExecutableElement? lookUpInheritedConcreteMember(
      String name, LibraryElement library) {
    if (name.endsWith('=')) {
      return lookUpInheritedConcreteSetter(name, library);
    } else {
      return lookUpInheritedConcreteMethod(name, library) ??
          lookUpInheritedConcreteGetter(name, library);
    }
  }

  @override
  MethodElement? lookUpInheritedConcreteMethod(
          String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName).where(
          (MethodElement method) =>
              !method.isAbstract &&
              !method.isStatic &&
              method.isAccessibleIn(library) &&
              method.enclosingElement != this));

  @override
  PropertyAccessorElement? lookUpInheritedConcreteSetter(
          String setterName, LibraryElement library) =>
      _first(_implementationsOfSetter(setterName).where(
          (PropertyAccessorElement setter) =>
              !setter.isAbstract &&
              !setter.isStatic &&
              setter.isAccessibleIn(library) &&
              setter.enclosingElement != this));

  @override
  MethodElement? lookUpInheritedMethod(
          String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName).where(
          (MethodElement method) =>
              !method.isStatic &&
              method.isAccessibleIn(library) &&
              method.enclosingElement != this));

  @override
  MethodElement? lookUpMethod(String methodName, LibraryElement library) =>
      _first(_implementationsOfMethod(methodName)
          .where((MethodElement method) => method.isAccessibleIn(library)));

  @override
  PropertyAccessorElement? lookUpSetter(
          String setterName, LibraryElement library) =>
      _first(_implementationsOfSetter(setterName).where(
          (PropertyAccessorElement setter) => setter.isAccessibleIn(library)));

  /// Return the static getter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement? lookupStaticGetter(
      String name, LibraryElement library) {
    return _first(_implementationsOfGetter(name).where((element) {
      return element.isStatic && element.isAccessibleIn(library);
    }));
  }

  /// Return the static method with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  MethodElement? lookupStaticMethod(String name, LibraryElement library) {
    return _first(_implementationsOfMethod(name).where((element) {
      return element.isStatic && element.isAccessibleIn(library);
    }));
  }

  /// Return the static setter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement? lookupStaticSetter(
      String name, LibraryElement library) {
    return _first(_implementationsOfSetter(name).where((element) {
      return element.isStatic && element.isAccessibleIn(library);
    }));
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(fields, visitor);
  }

  /// Return an iterable containing all of the implementations of a getter with
  /// the given [getterName] that are defined in this class any any superclass
  /// of this class (but not in interfaces).
  ///
  /// The getters that are returned are not filtered in any way. In particular,
  /// they can include getters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The getters are returned based on the depth of their defining class; if
  /// this class contains a definition of the getter it will occur first, if
  /// Object contains a definition of the getter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfGetter(
      String getterName) sync* {
    ClassElement? classElement = this;
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    while (classElement != null && visitedClasses.add(classElement)) {
      var getter = classElement.getGetter(getterName);
      if (getter != null) {
        yield getter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        getter = mixin.element.getGetter(getterName);
        if (getter != null) {
          yield getter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /// Return an iterable containing all of the implementations of a method with
  /// the given [methodName] that are defined in this class any any superclass
  /// of this class (but not in interfaces).
  ///
  /// The methods that are returned are not filtered in any way. In particular,
  /// they can include methods that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The methods are returned based on the depth of their defining class; if
  /// this class contains a definition of the method it will occur first, if
  /// Object contains a definition of the method it will occur last.
  Iterable<MethodElement> _implementationsOfMethod(String methodName) sync* {
    ClassElement? classElement = this;
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    while (classElement != null && visitedClasses.add(classElement)) {
      var method = classElement.getMethod(methodName);
      if (method != null) {
        yield method;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        method = mixin.element.getMethod(methodName);
        if (method != null) {
          yield method;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /// Return an iterable containing all of the implementations of a setter with
  /// the given [setterName] that are defined in this class any any superclass
  /// of this class (but not in interfaces).
  ///
  /// The setters that are returned are not filtered in any way. In particular,
  /// they can include setters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The setters are returned based on the depth of their defining class; if
  /// this class contains a definition of the setter it will occur first, if
  /// Object contains a definition of the setter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfSetter(
      String setterName) sync* {
    ClassElement? classElement = this;
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    while (classElement != null && visitedClasses.add(classElement)) {
      var setter = classElement.getSetter(setterName);
      if (setter != null) {
        yield setter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        setter = mixin.element.getSetter(setterName);
        if (setter != null) {
          yield setter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  static PropertyAccessorElement? getSetterFromAccessors(
      String setterName, List<PropertyAccessorElement> accessors) {
    // TODO (jwren) revisit- should we append '=' here or require clients to
    // include it?
    // Do we need the check for isSetter below?
    if (!StringUtilities.endsWithChar(setterName, 0x3D)) {
      setterName += '=';
    }
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isSetter && accessor.name == setterName) {
        return accessor;
      }
    }
    return null;
  }

  /// Return the first element from the given [iterable], or `null` if the
  /// iterable is empty.
  static E? _first<E>(Iterable<E> iterable) {
    if (iterable.isEmpty) {
      return null;
    }
    return iterable.first;
  }
}

/// An [AbstractClassElementImpl] which is a class.
class ClassElementImpl extends AbstractClassElementImpl
    with TypeParameterizedElementMixin {
  /// The superclass of the class, or `null` for [Object].
  InterfaceType? _supertype;

  /// A list containing all of the mixins that are applied to the class being
  /// extended in order to derive the superclass of this class.
  List<InterfaceType> _mixins = const [];

  /// A list containing all of the interfaces that are implemented by this
  /// class.
  List<InterfaceType> _interfaces = const [];

  /// For classes which are not mixin applications, a list containing all of the
  /// constructors contained in this class, or `null` if the list of
  /// constructors has not yet been built.
  ///
  /// For classes which are mixin applications, the list of constructors is
  /// computed on the fly by the [constructors] getter, and this field is
  /// `null`.
  List<ConstructorElement> _constructors = _Sentinel.constructorElement;

  /// A flag indicating whether the types associated with the instance members
  /// of this class have been inferred.
  bool hasBeenInferred = false;

  /// This callback is set during mixins inference to handle reentrant calls.
  List<InterfaceType>? Function(ClassElementImpl)? mixinInferenceCallback;

  /// TODO(scheglov) implement as modifier
  bool _isSimplyBounded = true;

  ElementLinkedData? linkedData;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassElementImpl(String name, int offset) : super(name, offset);

  @override
  List<PropertyAccessorElement> get accessors {
    if (!identical(_accessors, _Sentinel.propertyAccessorElement)) {
      return _accessors;
    }

    var linkedData = this.linkedData;
    if (linkedData is ClassElementLinkedData) {
      linkedData.readMembers(this);
      return _accessors;
    }

    return _accessors;
  }

  @override
  List<InterfaceType> get allSupertypes {
    var sessionImpl = library.session as AnalysisSessionImpl;
    return sessionImpl.classHierarchy.implementedInterfaces(this);
  }

  @override
  List<ConstructorElement> get constructors {
    if (!identical(_constructors, _Sentinel.constructorElement)) {
      return _constructors;
    }

    if (isMixinApplication) {
      // Assign to break a possible infinite recursion during computing.
      _constructors = const <ConstructorElement>[];
      return _constructors = _computeMixinAppConstructors();
    }

    var linkedData = this.linkedData;
    if (linkedData is ClassElementLinkedData) {
      linkedData.readMembers(this);
      return _constructors;
    }

    if (_constructors.isEmpty) {
      var constructor = ConstructorElementImpl('', -1);
      constructor.isSynthetic = true;
      constructor.enclosingElement = this;
      _constructors = <ConstructorElement>[constructor];
    }

    return _constructors;
  }

  /// Set the constructors contained in this class to the given [constructors].
  ///
  /// Should only be used for class elements that are not mixin applications.
  set constructors(List<ConstructorElement> constructors) {
    assert(!isMixinApplication);
    for (ConstructorElement constructor in constructors) {
      (constructor as ConstructorElementImpl).enclosingElement = this;
    }
    _constructors = constructors;
  }

  @override
  List<FieldElement> get fields {
    if (!identical(_fields, _Sentinel.fieldElement)) {
      return _fields;
    }

    var linkedData = this.linkedData;
    if (linkedData is ClassElementLinkedData) {
      linkedData.readMembers(this);
      return _fields;
    }

    return _fields;
  }

  @override
  bool get hasNonFinalField {
    List<ClassElement> classesToVisit = <ClassElement>[];
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    classesToVisit.add(this);
    while (classesToVisit.isNotEmpty) {
      ClassElement currentElement = classesToVisit.removeAt(0);
      if (visitedClasses.add(currentElement)) {
        // check fields
        for (FieldElement field in currentElement.fields) {
          if (!field.isFinal &&
              !field.isConst &&
              !field.isStatic &&
              !field.isSynthetic) {
            return true;
          }
        }
        // check mixins
        for (InterfaceType mixinType in currentElement.mixins) {
          ClassElement mixinElement = mixinType.element;
          classesToVisit.add(mixinElement);
        }
        // check super
        InterfaceType? supertype = currentElement.supertype;
        if (supertype != null) {
          classesToVisit.add(supertype.element);
        }
      }
    }
    // not found
    return false;
  }

  /// Return `true` if the class has a concrete `noSuchMethod()` method distinct
  /// from the one declared in class `Object`, as per the Dart Language
  /// Specification (section 10.4).
  bool get hasNoSuchMethod {
    MethodElement? method = lookUpConcreteMethod(
        FunctionElement.NO_SUCH_METHOD_METHOD_NAME, library);
    var definingClass = method?.enclosingElement as ClassElement?;
    return definingClass != null && !definingClass.isDartCoreObject;
  }

  @override
  bool get hasStaticMember {
    for (MethodElement method in methods) {
      if (method.isStatic) {
        return true;
      }
    }
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isStatic) {
        return true;
      }
    }
    return false;
  }

  @override
  List<InterfaceType> get interfaces =>
      ElementTypeProvider.current.getClassInterfaces(this);

  set interfaces(List<InterfaceType> interfaces) {
    _interfaces = interfaces;
  }

  List<InterfaceType> get interfacesInternal {
    linkedData?.read(this);
    return _interfaces;
  }

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isDartCoreObject => !isMixin && supertype == null;

  bool get isEnumLike {
    // Must be a concrete class.
    if (isAbstract || isMixin) {
      return false;
    }

    // With only private non-factory constructors.
    for (var constructor in constructors) {
      if (constructor.isPublic || constructor.isFactory) {
        return false;
      }
    }

    // With 2+ static const fields with the type of this class.
    var numberOfElements = 0;
    for (var field in fields) {
      if (field.isStatic && field.isConst && field.type == thisType) {
        numberOfElements++;
      }
    }
    if (numberOfElements < 2) {
      return false;
    }

    // No subclasses in the library.
    for (var unit in library.units) {
      for (var class_ in unit.classes) {
        if (class_.supertype?.element == this) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  bool get isMixinApplication {
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

  /// Set whether this class is a mixin application.
  set isMixinApplication(bool isMixinApplication) {
    setModifier(Modifier.MIXIN_APPLICATION, isMixinApplication);
  }

  /// TODO(scheglov) implement as modifier
  @override
  bool get isSimplyBounded {
    return _isSimplyBounded;
  }

  /// TODO(scheglov) implement as modifier
  set isSimplyBounded(bool isSimplyBounded) {
    _isSimplyBounded = isSimplyBounded;
  }

  @override
  bool get isValidMixin {
    final supertype = this.supertype;
    if (supertype != null && !supertype.isDartCoreObject) {
      return false;
    }
    for (ConstructorElement constructor in constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        return false;
      }
    }
    return true;
  }

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MethodElement> get methods {
    if (!identical(_methods, _Sentinel.methodElement)) {
      return _methods;
    }

    var linkedData = this.linkedData;
    if (linkedData is ClassElementLinkedData) {
      linkedData.readMembers(this);
      return _methods;
    }

    return _methods;
  }

  /// Set the methods contained in this class to the given [methods].
  set methods(List<MethodElement> methods) {
    assert(!isMixinApplication);
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    _methods = methods;
  }

  @override
  List<InterfaceType> get mixins {
    if (mixinInferenceCallback != null) {
      var mixins = mixinInferenceCallback!(this);
      if (mixins != null) {
        return _mixins = mixins;
      }
    }

    linkedData?.read(this);
    return _mixins;
  }

  set mixins(List<InterfaceType> mixins) {
    _mixins = mixins;
  }

  @override
  String get name {
    return super.name!;
  }

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  List<String> get superInvokedNames => const <String>[];

  @override
  InterfaceType? get supertype {
    linkedData?.read(this);
    if (_supertype != null) return _supertype!;

    if (hasModifier(Modifier.DART_CORE_OBJECT)) {
      return null;
    }

    return _supertype;
  }

  set supertype(InterfaceType? supertype) {
    _supertype = supertype;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return super.typeParameters;
  }

  /// Set the type parameters defined for this class to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  ConstructorElement? get unnamedConstructor {
    for (ConstructorElement element in constructors) {
      if (element.name.isEmpty) {
        return element;
      }
    }
    return null;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeClassElement(this);
  }

  @override
  ConstructorElement? getNamedConstructor(String name) =>
      getNamedConstructorFromList(name, constructors);

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(constructors, visitor);
    safelyVisitChildren(methods, visitor);
    safelyVisitChildren(typeParameters, visitor);
  }

  /// Compute a list of constructors for this class, which is a mixin
  /// application.  If specified, [visitedClasses] is a list of the other mixin
  /// application classes which have been visited on the way to reaching this
  /// one (this is used to detect cycles).
  List<ConstructorElement> _computeMixinAppConstructors(
      [List<ClassElementImpl>? visitedClasses]) {
    if (supertype == null) {
      // Shouldn't ever happen, since the only classes with no supertype are
      // Object and mixins, and they aren't a mixin application. But for
      // safety's sake just assume an empty list.
      assert(false);
      return <ConstructorElement>[];
    }

    var superElement = supertype!.element as ClassElementImpl;

    // First get the list of constructors of the superclass which need to be
    // forwarded to this class.
    Iterable<ConstructorElement> constructorsToForward;
    if (!superElement.isMixinApplication) {
      final library = this.library;
      constructorsToForward = superElement.constructors
          .where((constructor) => constructor.isAccessibleIn(library))
          .where((constructor) => !constructor.isFactory);
    } else {
      if (visitedClasses == null) {
        visitedClasses = <ClassElementImpl>[this];
      } else {
        if (visitedClasses.contains(this)) {
          // Loop in the class hierarchy.  Don't try to forward any
          // constructors.
          return <ConstructorElement>[];
        }
        visitedClasses.add(this);
      }
      try {
        constructorsToForward =
            superElement._computeMixinAppConstructors(visitedClasses);
      } finally {
        visitedClasses.removeLast();
      }
    }

    // Figure out the type parameter substitution we need to perform in order
    // to produce constructors for this class.  We want to be robust in the
    // face of errors, so drop any extra type arguments and fill in any missing
    // ones with `dynamic`.
    var superClassParameters = superElement.typeParameters;
    List<DartType> argumentTypes = List<DartType>.filled(
        superClassParameters.length, DynamicTypeImpl.instance);
    for (int i = 0; i < supertype!.typeArguments.length; i++) {
      if (i >= argumentTypes.length) {
        break;
      }
      argumentTypes[i] = supertype!.typeArguments[i];
    }
    var substitution =
        Substitution.fromPairs(superClassParameters, argumentTypes);

    bool typeHasInstanceVariables(InterfaceType type) =>
        type.element.fields.any((e) => !e.isSynthetic);

    // Now create an implicit constructor for every constructor found above,
    // substituting type parameters as appropriate.
    return constructorsToForward
        .map((ConstructorElement superclassConstructor) {
      var name = superclassConstructor.name;
      var implicitConstructor = ConstructorElementImpl(name, -1);
      implicitConstructor.isSynthetic = true;
      implicitConstructor.name = name;
      implicitConstructor.nameOffset = -1;

      var containerRef = reference!.getChild('@constructor');
      var implicitReference = containerRef.getChild(name);
      implicitConstructor.reference = implicitReference;
      implicitReference.element = implicitConstructor;

      var hasMixinWithInstanceVariables = mixins.any(typeHasInstanceVariables);
      implicitConstructor.isConst =
          superclassConstructor.isConst && !hasMixinWithInstanceVariables;
      List<ParameterElement> superParameters = superclassConstructor.parameters;
      int count = superParameters.length;
      var argumentsForSuperInvocation = <Expression>[];
      if (count > 0) {
        var implicitParameters = <ParameterElement>[];
        for (int i = 0; i < count; i++) {
          ParameterElement superParameter = superParameters[i];
          ParameterElementImpl implicitParameter;
          if (superParameter is ConstVariableElement) {
            var constVariable = superParameter as ConstVariableElement;
            implicitParameter = DefaultParameterElementImpl(
              name: superParameter.name,
              nameOffset: -1,
              // ignore: deprecated_member_use_from_same_package
              parameterKind: superParameter.parameterKind,
            )..constantInitializer = constVariable.constantInitializer;
          } else {
            implicitParameter = ParameterElementImpl(
              name: superParameter.name,
              nameOffset: -1,
              // ignore: deprecated_member_use_from_same_package
              parameterKind: superParameter.parameterKind,
            );
          }
          implicitParameter.isConst = superParameter.isConst;
          implicitParameter.isFinal = superParameter.isFinal;
          implicitParameter.isSynthetic = true;
          implicitParameter.type =
              substitution.substituteType(superParameter.type);
          implicitParameters.add(implicitParameter);
          argumentsForSuperInvocation.add(
            astFactory.simpleIdentifier(
              StringToken(TokenType.STRING, implicitParameter.name, -1),
            )
              ..staticElement = implicitParameter
              ..staticType = implicitParameter.type,
          );
        }
        implicitConstructor.parameters = implicitParameters;
      }
      implicitConstructor.enclosingElement = this;

      var isNamed = superclassConstructor.name.isNotEmpty;
      implicitConstructor.constantInitializers = [
        astFactory.superConstructorInvocation(
          Tokens.super_(),
          isNamed ? Tokens.period() : null,
          isNamed
              ? (astFactory.simpleIdentifier(
                  StringToken(TokenType.STRING, superclassConstructor.name, -1),
                )..staticElement = superclassConstructor)
              : null,
          astFactory.argumentList(
            Tokens.openParenthesis(),
            argumentsForSuperInvocation,
            Tokens.closeParenthesis(),
          ),
        )..staticElement = superclassConstructor,
      ];

      return implicitConstructor;
    }).toList(growable: false);
  }

  static ConstructorElement? getNamedConstructorFromList(
      String name, List<ConstructorElement> constructors) {
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    for (ConstructorElement element in constructors) {
      if (element.name == name) {
        return element;
      }
    }
    return null;
  }
}

/// A concrete implementation of a [CompilationUnitElement].
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement {
  /// The source that corresponds to this compilation unit.
  @override
  late Source source;

  @override
  LineInfo? lineInfo;

  /// The source of the library containing this compilation unit.
  ///
  /// This is the same as the source of the containing [LibraryElement],
  /// except that it does not require the containing [LibraryElement] to be
  /// computed.
  @override
  late Source librarySource;

  /// A list containing all of the top-level accessors (getters and setters)
  /// contained in this compilation unit.
  List<PropertyAccessorElement> _accessors = const [];

  /// A list containing all of the classes contained in this compilation unit.
  List<ClassElement> _classes = const [];

  /// A list containing all of the enums contained in this compilation unit.
  List<ClassElement> _enums = const [];

  /// A list containing all of the extensions contained in this compilation
  /// unit.
  List<ExtensionElement> _extensions = const [];

  /// A list containing all of the top-level functions contained in this
  /// compilation unit.
  List<FunctionElement> _functions = const [];

  /// A list containing all of the mixins contained in this compilation unit.
  List<ClassElement> _mixins = const [];

  /// A list containing all of the type aliases contained in this compilation
  /// unit.
  List<TypeAliasElement> _typeAliases = const [];

  /// A list containing all of the variables contained in this compilation unit.
  List<TopLevelVariableElement> _variables = const [];

  ElementLinkedData? linkedData;

  /// Initialize a newly created compilation unit element to have the given
  /// [name].
  CompilationUnitElementImpl() : super(null, -1);

  @override
  List<PropertyAccessorElement> get accessors {
    return _accessors;
  }

  /// Set the top-level accessors (getters and setters) contained in this
  /// compilation unit to the given [accessors].
  set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  List<ClassElement> get classes {
    return _classes;
  }

  /// Set the classes contained in this compilation unit to [classes].
  set classes(List<ClassElement> classes) {
    for (ClassElement class_ in classes) {
      // Another implementation of ClassElement is _DeferredClassElement,
      // which is used to resynthesize classes lazily. We cannot cast it
      // to ClassElementImpl, and it already can provide correct values of the
      // 'enclosingElement' property.
      if (class_ is ClassElementImpl) {
        class_.enclosingElement = this;
      }
    }
    _classes = classes;
  }

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return this;
  }

  @override
  List<ClassElement> get enums {
    return _enums;
  }

  /// Set the enums contained in this compilation unit to the given [enums].
  set enums(List<ClassElement> enums) {
    for (ClassElement enumDeclaration in enums) {
      (enumDeclaration as EnumElementImpl).enclosingElement = this;
    }
    _enums = enums;
  }

  @override
  List<ExtensionElement> get extensions {
    return _extensions;
  }

  /// Set the extensions contained in this compilation unit to the given
  /// [extensions].
  set extensions(List<ExtensionElement> extensions) {
    for (ExtensionElement extension in extensions) {
      (extension as ExtensionElementImpl).enclosingElement = this;
    }
    _extensions = extensions;
  }

  @override
  List<FunctionElement> get functions {
    return _functions;
  }

  /// Set the top-level functions contained in this compilation unit to the
  ///  given[functions].
  set functions(List<FunctionElement> functions) {
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    _functions = functions;
  }

  @override
  int get hashCode => source.hashCode;

  @Deprecated('Not useful for clients')
  @override
  bool get hasLoadLibraryFunction {
    final functions = this.functions;
    for (int i = 0; i < functions.length; i++) {
      if (functions[i].name == FunctionElement.LOAD_LIBRARY_NAME) {
        return true;
      }
    }
    return false;
  }

  @override
  String get identifier => '${source.uri}';

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<ClassElement> get mixins {
    return _mixins;
  }

  /// Set the mixins contained in this compilation unit to the given [mixins].
  set mixins(List<ClassElement> mixins) {
    for (var type in mixins) {
      (type as MixinElementImpl).enclosingElement = this;
    }
    _mixins = mixins;
  }

  @override
  AnalysisSession get session => enclosingElement.session;

  @override
  List<TopLevelVariableElement> get topLevelVariables {
    return _variables;
  }

  /// Set the top-level variables contained in this compilation unit to the
  ///  given[variables].
  set topLevelVariables(List<TopLevelVariableElement> variables) {
    for (TopLevelVariableElement field in variables) {
      (field as TopLevelVariableElementImpl).enclosingElement = this;
    }
    _variables = variables;
  }

  @override
  List<TypeAliasElement> get typeAliases {
    return _typeAliases;
  }

  /// Set the type aliases contained in this compilation unit to [typeAliases].
  set typeAliases(List<TypeAliasElement> typeAliases) {
    for (var typeAlias in typeAliases) {
      (typeAlias as ElementImpl).enclosingElement = this;
    }
    _typeAliases = typeAliases;
  }

  @override
  TypeParameterizedElementMixin? get typeParameterContext => null;

  @Deprecated('Use classes instead')
  @override
  List<ClassElement> get types {
    return _classes;
  }

  @override
  bool operator ==(Object object) =>
      object is CompilationUnitElementImpl && source == object.source;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitCompilationUnitElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeCompilationUnitElement(this);
  }

  @override
  ClassElement? getEnum(String enumName) {
    for (ClassElement enumDeclaration in enums) {
      if (enumDeclaration.name == enumName) {
        return enumDeclaration;
      }
    }
    return null;
  }

  @override
  ClassElement? getType(String className) {
    for (ClassElement class_ in classes) {
      if (class_.name == className) {
        return class_;
      }
    }
    return null;
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(classes, visitor);
    safelyVisitChildren(enums, visitor);
    safelyVisitChildren(extensions, visitor);
    safelyVisitChildren(functions, visitor);
    safelyVisitChildren(mixins, visitor);
    safelyVisitChildren(typeAliases, visitor);
    safelyVisitChildren(topLevelVariables, visitor);
  }
}

/// A [FieldElement] for a 'const' or 'final' field that has an initializer.
///
/// TODO(paulberry): we should rename this class to reflect the fact that it's
/// used for both const and final fields.  However, we shouldn't do so until
/// we've created an API for reading the values of constants; until that API is
/// available, clients are likely to read constant values by casting to
/// ConstFieldElementImpl, so it would be a breaking change to rename this
/// class.
class ConstFieldElementImpl extends FieldElementImpl with ConstVariableElement {
  /// Initialize a newly created synthetic field element to have the given
  /// [name] and [offset].
  ConstFieldElementImpl(String name, int offset) : super(name, offset);

  @override
  Expression? get constantInitializer {
    linkedData?.read(this);
    return super.constantInitializer;
  }
}

/// A field element representing an enum constant.
class ConstFieldElementImpl_EnumValue extends ConstFieldElementImpl_ofEnum {
  final int _index;

  ConstFieldElementImpl_EnumValue(
      EnumElementImpl enumElement, String name, this._index)
      : super(enumElement, name);

  @override
  Expression? get constantInitializer => null;

  @override
  EvaluationResultImpl? get evaluationResult {
    if (_evaluationResult == null) {
      Map<String, DartObjectImpl> fieldMap = <String, DartObjectImpl>{
        'index': DartObjectImpl(
          library.typeSystem,
          library.typeProvider.intType,
          IntState(_index),
        ),
        // TODO(brianwilkerson) There shouldn't be a field with the same name as
        //  the constant, but we can't remove it until a version of dartdoc that
        //  doesn't depend on it has been published and pulled into the SDK. The
        //  map entry below should be removed when
        //  https://github.com/dart-lang/dartdoc/issues/2318 has been resolved.
        name: DartObjectImpl(
          library.typeSystem,
          library.typeProvider.intType,
          IntState(_index),
        ),
      };
      DartObjectImpl value = DartObjectImpl(
        library.typeSystem,
        type,
        GenericState(fieldMap),
      );
      _evaluationResult = EvaluationResultImpl(value);
    }
    return _evaluationResult;
  }

  @override
  bool get hasInitializer => false;

  @override
  Element get nonSynthetic => this;

  @override
  InterfaceType get type =>
      ElementTypeProvider.current.getFieldType(this) as InterfaceType;

  @override
  InterfaceType get typeInternal => _enum.thisType;
}

/// The synthetic `values` field of an enum.
class ConstFieldElementImpl_EnumValues extends ConstFieldElementImpl_ofEnum {
  ConstFieldElementImpl_EnumValues(EnumElementImpl enumElement)
      : super(enumElement, 'values') {
    isSynthetic = true;
  }

  @override
  EvaluationResultImpl get evaluationResult {
    if (_evaluationResult == null) {
      var constantValues = <DartObjectImpl>[];
      for (FieldElement field in _enum.fields) {
        if (field is ConstFieldElementImpl_EnumValue) {
          constantValues.add(field.evaluationResult!.value!);
        }
      }
      _evaluationResult = EvaluationResultImpl(
        DartObjectImpl(
          library.typeSystem,
          type,
          ListState(constantValues),
        ),
      );
    }
    return _evaluationResult!;
  }

  @override
  String get name => 'values';

  @override
  InterfaceType get type =>
      ElementTypeProvider.current.getFieldType(this) as InterfaceType;

  @override
  InterfaceType get typeInternal {
    if (_type == null) {
      return _type = library.typeProvider.listType(_enum.thisType);
    }
    return _type as InterfaceType;
  }
}

/// An abstract constant field of an enum.
abstract class ConstFieldElementImpl_ofEnum extends ConstFieldElementImpl {
  final EnumElementImpl _enum;

  ConstFieldElementImpl_ofEnum(this._enum, String name) : super(name, -1) {
    enclosingElement = _enum;
  }

  @override
  set evaluationResult(_) {
    assert(false);
  }

  @override
  bool get isConst => true;

  @override
  set isConst(bool isConst) {
    assert(false);
  }

  @override
  bool get isConstantEvaluated => true;

  @override
  set isFinal(bool isFinal) {
    assert(false);
  }

  @override
  bool get isStatic => true;

  @override
  set isStatic(bool isStatic) {
    assert(false);
  }

  @override
  Element get nonSynthetic => _enum;

  @override
  set type(DartType type) {
    assert(false);
  }
}

/// A [LocalVariableElement] for a local 'const' variable that has an
/// initializer.
class ConstLocalVariableElementImpl extends LocalVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created local variable element to have the given [name]
  /// and [offset].
  ConstLocalVariableElementImpl(String name, int offset) : super(name, offset);
}

/// A concrete implementation of a [ConstructorElement].
class ConstructorElementImpl extends ExecutableElementImpl
    with ConstructorElementMixin
    implements ConstructorElement {
  /// The constructor to which this constructor is redirecting.
  ConstructorElement? _redirectedConstructor;

  /// The initializers for this constructor (used for evaluating constant
  /// instance creation expressions).
  List<ConstructorInitializer> _constantInitializers = const [];

  @override
  int? periodOffset;

  @override
  int? nameEnd;

  /// For every constructor we initially set this flag to `true`, and then
  /// set it to `false` during computing constant values if we detect that it
  /// is a part of a cycle.
  bool _isCycleFree = true;

  @override
  bool isConstantEvaluated = false;

  /// Initialize a newly created constructor element to have the given [name]
  /// and [offset].
  ConstructorElementImpl(String name, int offset) : super(name, offset);

  /// Return the constant initializers for this element, which will be empty if
  /// there are no initializers, or `null` if there was an error in the source.
  List<ConstructorInitializer> get constantInitializers {
    linkedData?.read(this);
    return _constantInitializers;
  }

  set constantInitializers(List<ConstructorInitializer> constantInitializers) {
    _constantInitializers = constantInitializers;
  }

  @override
  ConstructorElement get declaration => this;

  @override
  String get displayName {
    var className = enclosingElement.name;
    var name = this.name;
    if (name.isNotEmpty) {
      return '$className.$name';
    } else {
      return className;
    }
  }

  @override
  ClassElementImpl get enclosingElement =>
      super.enclosingElement as ClassElementImpl;

  @override
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this constructor represents a 'const' constructor.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  bool get isCycleFree {
    return _isCycleFree;
  }

  set isCycleFree(bool isCycleFree) {
    // This property is updated in ConstantEvaluationEngine even for
    // resynthesized constructors, so we don't have the usual assert here.
    _isCycleFree = isCycleFree;
  }

  @override
  bool get isFactory {
    return hasModifier(Modifier.FACTORY);
  }

  /// Set whether this constructor represents a factory method.
  set isFactory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  @override
  bool get isStatic => false;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  int get nameLength {
    final nameEnd = this.nameEnd;
    if (nameEnd == null || periodOffset == null) {
      return 0;
    } else {
      return nameEnd - nameOffset;
    }
  }

  @override
  Element get nonSynthetic {
    return isSynthetic ? enclosingElement : this;
  }

  @override
  ConstructorElement? get redirectedConstructor {
    linkedData?.read(this);
    return _redirectedConstructor;
  }

  set redirectedConstructor(ConstructorElement? redirectedConstructor) {
    _redirectedConstructor = redirectedConstructor;
  }

  @override
  InterfaceType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this)
          as InterfaceType;

  @override
  set returnType(DartType returnType) {
    assert(false);
  }

  @override
  InterfaceType get returnTypeInternal {
    return (_returnType ??= enclosingElement.thisType) as InterfaceType;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false);
  }

  @override
  FunctionType get typeInternal {
    // TODO(scheglov) Remove "element" in the breaking changes branch.
    return _type ??= FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// Ensures that dependencies of this constructor, such as default values
  /// of formal parameters, are evaluated.
  void computeConstantDependencies() {
    if (!isConstantEvaluated) {
      var analysisOptions = context.analysisOptions as AnalysisOptionsImpl;
      computeConstants(library.typeProvider, library.typeSystem,
          context.declaredVariables, [this], analysisOptions.experimentStatus);
    }
  }
}

/// Common implementation for methods defined in [ConstructorElement].
mixin ConstructorElementMixin implements ConstructorElement {
  @override
  bool get isDefaultConstructor {
    // unnamed
    if (name.isNotEmpty) {
      return false;
    }
    // no required parameters
    for (ParameterElement parameter in parameters) {
      if (parameter.isNotOptional) {
        return false;
      }
    }
    // OK, can be used as default constructor
    return true;
  }
}

/// A [TopLevelVariableElement] for a top-level 'const' variable that has an
/// initializer.
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  ConstTopLevelVariableElementImpl(String name, int offset)
      : super(name, offset);

  @override
  Expression? get constantInitializer {
    linkedData?.read(this);
    return super.constantInitializer;
  }
}

/// Mixin used by elements that represent constant variables and have
/// initializers.
///
/// Note that in correct Dart code, all constant variables must have
/// initializers.  However, analyzer also needs to handle incorrect Dart code,
/// in which case there might be some constant variables that lack initializers.
/// This interface is only used for constant variables that have initializers.
///
/// This class is not intended to be part of the public API for analyzer.
mixin ConstVariableElement implements ElementImpl, ConstantEvaluationTarget {
  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression? constantInitializer;

  EvaluationResultImpl? _evaluationResult;

  EvaluationResultImpl? get evaluationResult => _evaluationResult;

  set evaluationResult(EvaluationResultImpl? evaluationResult) {
    _evaluationResult = evaluationResult;
  }

  @override
  bool get isConstantEvaluated => _evaluationResult != null;

  /// Return a representation of the value of this variable, forcing the value
  /// to be computed if it had not previously been computed, or `null` if either
  /// this variable was not declared with the 'const' modifier or if the value
  /// of this variable could not be computed because of errors.
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      var analysisOptions = context.analysisOptions as AnalysisOptionsImpl;
      computeConstants(library!.typeProvider, library!.typeSystem,
          context.declaredVariables, [this], analysisOptions.experimentStatus);
    }
    return evaluationResult?.value;
  }
}

/// A [FieldFormalParameterElementImpl] for parameters that have an initializer.
class DefaultFieldFormalParameterElementImpl
    extends FieldFormalParameterElementImpl with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultFieldFormalParameterElementImpl({
    required String name,
    required int nameOffset,
    required ParameterKind parameterKind,
  }) : super(
          name: name,
          nameOffset: nameOffset,
          parameterKind: parameterKind,
        );

  @override
  String? get defaultValueCode {
    return constantInitializer?.toSource();
  }
}

/// A [ParameterElement] for parameters that have an initializer.
class DefaultParameterElementImpl extends ParameterElementImpl
    with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultParameterElementImpl({
    required String? name,
    required int nameOffset,
    required ParameterKind parameterKind,
  }) : super(
          name: name,
          nameOffset: nameOffset,
          parameterKind: parameterKind,
        );

  @override
  String? get defaultValueCode {
    return constantInitializer?.toSource();
  }
}

/// The synthetic element representing the declaration of the type `dynamic`.
class DynamicElementImpl extends ElementImpl implements TypeDefiningElement {
  /// Return the unique instance of this class.
  static DynamicElementImpl get instance =>
      DynamicTypeImpl.instance.element as DynamicElementImpl;

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  DynamicElementImpl() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => null;
}

/// A concrete implementation of an [ElementAnnotation].
class ElementAnnotationImpl implements ElementAnnotation {
  /// The name of the top-level variable used to mark that a function always
  /// throws, for dead code purposes.
  static const String _ALWAYS_THROWS_VARIABLE_NAME = "alwaysThrows";

  /// The name of the class used to mark an element as being deprecated.
  static const String _DEPRECATED_CLASS_NAME = "Deprecated";

  /// The name of the top-level variable used to mark an element as being
  /// deprecated.
  static const String _DEPRECATED_VARIABLE_NAME = "deprecated";

  /// The name of the top-level variable used to mark an element as not to be
  /// stored.
  static const String _DO_NOT_STORE_VARIABLE_NAME = "doNotStore";

  /// The name of the top-level variable used to mark a method as being a
  /// factory.
  static const String _FACTORY_VARIABLE_NAME = "factory";

  /// The name of the top-level variable used to mark a class and its subclasses
  /// as being immutable.
  static const String _IMMUTABLE_VARIABLE_NAME = "immutable";

  /// The name of the top-level variable used to mark an element as being
  /// internal to its package.
  static const String _INTERNAL_VARIABLE_NAME = "internal";

  /// The name of the top-level variable used to mark a constructor as being
  /// literal.
  static const String _LITERAL_VARIABLE_NAME = "literal";

  /// The name of the top-level variable used to mark a type as having
  /// "optional" type arguments.
  static const String _OPTIONAL_TYPE_ARGS_VARIABLE_NAME = "optionalTypeArgs";

  /// The name of the top-level variable used to mark a function as running
  /// a single test.
  static const String _IS_TEST_VARIABLE_NAME = "isTest";

  /// The name of the top-level variable used to mark a function as running
  /// a test group.
  static const String _IS_TEST_GROUP_VARIABLE_NAME = "isTestGroup";

  /// The name of the class used to JS annotate an element.
  static const String _JS_CLASS_NAME = "JS";

  /// The name of `js` library, used to define JS annotations.
  static const String _JS_LIB_NAME = "js";

  /// The name of `meta` library, used to define analysis annotations.
  static const String _META_LIB_NAME = "meta";

  /// The name of `meta_meta` library, used to define annotations for other
  /// annotations.
  static const String _META_META_LIB_NAME = "meta_meta";

  /// The name of the top-level variable used to mark a method as requiring
  /// overriders to call super.
  static const String _MUST_CALL_SUPER_VARIABLE_NAME = "mustCallSuper";

  /// The name of `angular.meta` library, used to define angular analysis
  /// annotations.
  static const String _NG_META_LIB_NAME = "angular.meta";

  /// The name of the top-level variable used to mark a member as being nonVirtual.
  static const String _NON_VIRTUAL_VARIABLE_NAME = "nonVirtual";

  /// The name of the top-level variable used to mark a method as being expected
  /// to override an inherited method.
  static const String _OVERRIDE_VARIABLE_NAME = "override";

  /// The name of the top-level variable used to mark a method as being
  /// protected.
  static const String _PROTECTED_VARIABLE_NAME = "protected";

  /// The name of the top-level variable used to mark a class as implementing a
  /// proxy object.
  static const String PROXY_VARIABLE_NAME = "proxy";

  /// The name of the class used to mark a parameter as being required.
  static const String _REQUIRED_CLASS_NAME = "Required";

  /// The name of the top-level variable used to mark a parameter as being
  /// required.
  static const String _REQUIRED_VARIABLE_NAME = "required";

  /// The name of the top-level variable used to mark a class as being sealed.
  static const String _SEALED_VARIABLE_NAME = "sealed";

  /// The name of the class used to annotate a class as an annotation with a
  /// specific set of target element kinds.
  static const String _TARGET_CLASS_NAME = 'Target';

  /// The name of the class used to mark a returned element as requiring use.
  static const String _USE_RESULT_CLASS_NAME = "UseResult";

  /// The name of the top-level variable used to mark a returned element as
  /// requiring use.
  static const String _USE_RESULT_VARIABLE_NAME = "useResult";

  /// The name of the top-level variable used to mark a member as being visible
  /// for overriding only.
  static const String _VISIBLE_FOR_OVERRIDING_NAME = 'visibleForOverriding';

  /// The name of the top-level variable used to mark a method as being
  /// visible for templates.
  static const String _VISIBLE_FOR_TEMPLATE_VARIABLE_NAME =
      "visibleForTemplate";

  /// The name of the top-level variable used to mark a method as being
  /// visible for testing.
  static const String _VISIBLE_FOR_TESTING_VARIABLE_NAME = "visibleForTesting";

  @override
  Element? element;

  /// The compilation unit in which this annotation appears.
  CompilationUnitElementImpl compilationUnit;

  /// The AST of the annotation itself, cloned from the resolved AST for the
  /// source code.
  late Annotation annotationAst;

  /// The result of evaluating this annotation as a compile-time constant
  /// expression, or `null` if the compilation unit containing the variable has
  /// not been resolved.
  EvaluationResultImpl? evaluationResult;

  /// Initialize a newly created annotation. The given [compilationUnit] is the
  /// compilation unit in which the annotation appears.
  ElementAnnotationImpl(this.compilationUnit);

  @override
  List<AnalysisError> get constantEvaluationErrors =>
      evaluationResult?.errors ?? const <AnalysisError>[];

  @override
  AnalysisContext get context => compilationUnit.library.context;

  @override
  bool get isAlwaysThrows => _isPackageMetaGetter(_ALWAYS_THROWS_VARIABLE_NAME);

  @override
  bool get isConstantEvaluated => evaluationResult != null;

  @override
  bool get isDeprecated {
    final element = this.element;
    if (element is ConstructorElement) {
      return element.library.isDartCore &&
          element.enclosingElement.name == _DEPRECATED_CLASS_NAME;
    } else if (element is PropertyAccessorElement) {
      return element.library.isDartCore &&
          element.name == _DEPRECATED_VARIABLE_NAME;
    }
    return false;
  }

  @override
  bool get isDoNotStore => _isPackageMetaGetter(_DO_NOT_STORE_VARIABLE_NAME);

  @override
  bool get isFactory => _isPackageMetaGetter(_FACTORY_VARIABLE_NAME);

  @override
  bool get isImmutable => _isPackageMetaGetter(_IMMUTABLE_VARIABLE_NAME);

  @override
  bool get isInternal => _isPackageMetaGetter(_INTERNAL_VARIABLE_NAME);

  @override
  bool get isIsTest => _isPackageMetaGetter(_IS_TEST_VARIABLE_NAME);

  @override
  bool get isIsTestGroup => _isPackageMetaGetter(_IS_TEST_GROUP_VARIABLE_NAME);

  @override
  bool get isJS =>
      _isConstructor(libraryName: _JS_LIB_NAME, className: _JS_CLASS_NAME);

  @override
  bool get isLiteral => _isPackageMetaGetter(_LITERAL_VARIABLE_NAME);

  @override
  bool get isMustCallSuper =>
      _isPackageMetaGetter(_MUST_CALL_SUPER_VARIABLE_NAME);

  @override
  bool get isNonVirtual => _isPackageMetaGetter(_NON_VIRTUAL_VARIABLE_NAME);

  @override
  bool get isOptionalTypeArgs =>
      _isPackageMetaGetter(_OPTIONAL_TYPE_ARGS_VARIABLE_NAME);

  @override
  bool get isOverride => _isDartCoreGetter(_OVERRIDE_VARIABLE_NAME);

  /// Return `true` if this is an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get isPragmaVmEntryPoint {
    if (_isConstructor(libraryName: 'dart.core', className: 'pragma')) {
      var value = computeConstantValue();
      var nameValue = value?.getField('name');
      return nameValue?.toStringValue() == 'vm:entry-point';
    }
    return false;
  }

  @override
  bool get isProtected => _isPackageMetaGetter(_PROTECTED_VARIABLE_NAME);

  @override
  bool get isProxy => _isDartCoreGetter(PROXY_VARIABLE_NAME);

  @override
  bool get isRequired =>
      _isConstructor(
          libraryName: _META_LIB_NAME, className: _REQUIRED_CLASS_NAME) ||
      _isPackageMetaGetter(_REQUIRED_VARIABLE_NAME);

  @override
  bool get isSealed => _isPackageMetaGetter(_SEALED_VARIABLE_NAME);

  @override
  bool get isTarget => _isConstructor(
      libraryName: _META_META_LIB_NAME, className: _TARGET_CLASS_NAME);

  @override
  bool get isUseResult =>
      _isConstructor(
          libraryName: _META_LIB_NAME, className: _USE_RESULT_CLASS_NAME) ||
      _isPackageMetaGetter(_USE_RESULT_VARIABLE_NAME);

  @override
  bool get isVisibleForOverriding =>
      _isPackageMetaGetter(_VISIBLE_FOR_OVERRIDING_NAME);

  @override
  bool get isVisibleForTemplate => _isTopGetter(
      libraryName: _NG_META_LIB_NAME,
      name: _VISIBLE_FOR_TEMPLATE_VARIABLE_NAME);

  @override
  bool get isVisibleForTesting =>
      _isPackageMetaGetter(_VISIBLE_FOR_TESTING_VARIABLE_NAME);

  @override
  LibraryElement get library => compilationUnit.library;

  /// Get the library containing this annotation.
  @override
  Source get librarySource => compilationUnit.librarySource;

  @override
  Source get source => compilationUnit.source;

  @override
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      var analysisOptions = context.analysisOptions as AnalysisOptionsImpl;
      var library = compilationUnit.library;
      computeConstants(library.typeProvider, library.typeSystem,
          context.declaredVariables, [this], analysisOptions.experimentStatus);
    }
    return evaluationResult?.value;
  }

  @override
  String toSource() => annotationAst.toSource();

  @override
  String toString() => '@$element';

  bool _isConstructor({
    required String libraryName,
    required String className,
  }) {
    final element = this.element;
    return element is ConstructorElement &&
        element.enclosingElement.name == className &&
        element.library.name == libraryName;
  }

  bool _isDartCoreGetter(String name) {
    return _isTopGetter(
      libraryName: 'dart.core',
      name: name,
    );
  }

  bool _isPackageMetaGetter(String name) {
    return _isTopGetter(
      libraryName: _META_LIB_NAME,
      name: name,
    );
  }

  bool _isTopGetter({
    required String libraryName,
    required String name,
  }) {
    final element = this.element;
    return element is PropertyAccessorElement &&
        element.name == name &&
        element.library.name == libraryName;
  }
}

/// A base class for concrete implementations of an [Element].
abstract class ElementImpl implements Element {
  static const _metadataFlag_isReady = 1 << 0;
  static const _metadataFlag_hasDeprecated = 1 << 1;
  static const _metadataFlag_hasOverride = 1 << 2;

  /// An Unicode right arrow.
  @deprecated
  static final String RIGHT_ARROW = " \u2192 ";

  static int _NEXT_ID = 0;

  @override
  final int id = _NEXT_ID++;

  /// The enclosing element of this element, or `null` if this element is at the
  /// root of the element structure.
  ElementImpl? _enclosingElement;

  Reference? reference;

  /// The name of this element.
  String? _name;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element.
  int _nameOffset = 0;

  /// A bit-encoded form of the modifiers associated with this element.
  int _modifiers = 0;

  /// A list containing all of the metadata associated with this element.
  List<ElementAnnotation> _metadata = const [];

  /// Cached flags denoting presence of specific annotations in [_metadata].
  int _metadataFlags = 0;

  /// A cached copy of the calculated hashCode for this element.
  int? _cachedHashCode;

  /// A cached copy of the calculated location for this element.
  ElementLocation? _cachedLocation;

  /// The documentation comment for this element.
  String? _docComment;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? _codeOffset;

  /// The length of the element's code, or `null` if the element is synthetic.
  int? _codeLength;

  /// Initialize a newly created element to have the given [name] at the given
  /// [_nameOffset].
  ElementImpl(String? name, this._nameOffset, {this.reference}) {
    _name = name != null ? StringUtilities.intern(name) : null;
    reference?.element = this;
  }

  /// The length of the element's code, or `null` if the element is synthetic.
  int? get codeLength => _codeLength;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? get codeOffset => _codeOffset;

  @override
  AnalysisContext get context {
    return _enclosingElement!.context;
  }

  @override
  Element get declaration => this;

  @override
  String get displayName => _name ?? '';

  @override
  String? get documentationComment => _docComment;

  /// The documentation comment source for this element.
  set documentationComment(String? doc) {
    _docComment = doc;
  }

  @override
  Element? get enclosingElement => _enclosingElement;

  /// Set the enclosing element of this element to the given [element].
  set enclosingElement(Element? element) {
    _enclosingElement = element as ElementImpl?;
  }

  /// Return the enclosing unit element (which might be the same as `this`), or
  /// `null` if this element is not contained in any compilation unit.
  CompilationUnitElementImpl get enclosingUnit {
    return _enclosingElement!.enclosingUnit;
  }

  @override
  bool get hasAlwaysThrows {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isAlwaysThrows) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDeprecated {
    return (_getMetadataFlags() & _metadataFlag_hasDeprecated) != 0;
  }

  @override
  bool get hasDoNotStore {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotStore) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasFactory {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isFactory) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode {
    // TODO: We might want to re-visit this optimization in the future.
    // We cache the hash code value as this is a very frequently called method.
    return _cachedHashCode ??= location.hashCode;
  }

  @override
  bool get hasInternal {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isInternal) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTest {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTest) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTestGroup {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTestGroup) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasJS {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasLiteral {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isLiteral) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustCallSuper {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustCallSuper) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasNonVirtual {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isNonVirtual) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOptionalTypeArgs {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOptionalTypeArgs) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOverride {
    return (_getMetadataFlags() & _metadataFlag_hasOverride) != 0;
  }

  /// Return `true` if this element has an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get hasPragmaVmEntryPoint {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation is ElementAnnotationImpl &&
          annotation.isPragmaVmEntryPoint) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasProtected {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRequired {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasSealed {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isSealed) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasUseResult {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isUseResult) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForOverriding {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForOverriding) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTemplate {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTemplate) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTesting {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  /// Return an identifier that uniquely identifies this element among the
  /// children of this element's parent.
  String get identifier => name!;

  bool get isNonFunctionTypeAliasesEnabled {
    return library!.featureSet.isEnabled(Feature.nonfunction_type_aliases);
  }

  @override
  bool get isPrivate {
    final name = this.name;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic {
    return hasModifier(Modifier.SYNTHETIC);
  }

  /// Set whether this element is synthetic.
  set isSynthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  @override
  LibraryElementImpl? get library => thisOrAncestorOfType();

  @override
  Source? get librarySource => library?.source;

  @override
  ElementLocation get location {
    return _cachedLocation ??= ElementLocationImpl.con1(this);
  }

  @override
  List<ElementAnnotation> get metadata {
    return _metadata;
  }

  set metadata(List<ElementAnnotation> metadata) {
    _metadata = metadata;
  }

  @override
  String? get name => _name;

  /// Changes the name of this element.
  set name(String? name) {
    _name = name;
  }

  @override
  int get nameLength => displayName.length;

  @override
  int get nameOffset => _nameOffset;

  /// Sets the offset of the name of this element in the file that contains the
  /// declaration of this element.
  set nameOffset(int offset) {
    _nameOffset = offset;
  }

  @override
  Element get nonSynthetic => this;

  @override
  AnalysisSession? get session {
    return enclosingElement?.session;
  }

  @override
  Source? get source {
    return enclosingElement?.source;
  }

  /// Return the context to resolve type parameters in, or `null` if neither
  /// this element nor any of its ancestors is of a kind that can declare type
  /// parameters.
  TypeParameterizedElementMixin? get typeParameterContext {
    return _enclosingElement?.typeParameterContext;
  }

  NullabilitySuffix get _noneOrStarSuffix {
    return library!.isNonNullableByDefault == true
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    return object is Element &&
        object.kind == kind &&
        object.location == location;
  }

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeAbstractElement(this);
  }

  /// Set this element as the enclosing element for given [element].
  void encloseElement(ElementImpl element) {
    element.enclosingElement = this;
  }

  /// Set this element as the enclosing element for given [elements].
  void encloseElements(List<Element> elements) {
    for (Element element in elements) {
      (element as ElementImpl)._enclosingElement = this;
    }
  }

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
  String getExtendedDisplayName(String? shortName) {
    shortName ??= displayName;
    final source = this.source;
    return "$shortName (${source?.fullName})";
  }

  /// Return `true` if this element has the given [modifier] associated with it.
  bool hasModifier(Modifier modifier) =>
      BooleanArray.get(_modifiers, modifier.ordinal);

  @override
  bool isAccessibleIn(LibraryElement? library) {
    if (Identifier.isPrivateName(name!)) {
      return library == this.library;
    }
    return true;
  }

  /// Use the given [visitor] to visit all of the [children] in the given array.
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    for (Element child in children) {
      child.accept(visitor);
    }
  }

  /// Set the code range for this element.
  void setCodeRange(int offset, int length) {
    _codeOffset = offset;
    _codeLength = length;
  }

  /// Set whether the given [modifier] is associated with this element to
  /// correspond to the given [value].
  void setModifier(Modifier modifier, bool value) {
    _modifiers = BooleanArray.set(_modifiers, modifier.ordinal, value);
  }

  @override
  E thisOrAncestorMatching<E extends Element>(Predicate<Element> predicate) {
    Element? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement;
    }
    return element as E;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    Element? element = this;
    while (element != null && element is! E) {
      element = element.enclosingElement;
    }
    return element as E?;
  }

  @override
  String toString() {
    return getDisplayString(withNullability: true);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }

  /// Return flags that denote presence of a few specific annotations.
  int _getMetadataFlags() {
    var result = _metadataFlags;

    // Has at least `_metadataFlag_isReady`.
    if (result != 0) {
      return result;
    }

    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDeprecated) {
        result |= _metadataFlag_hasDeprecated;
      } else if (annotation.isOverride) {
        result |= _metadataFlag_hasOverride;
      }
    }

    result |= _metadataFlag_isReady;
    return _metadataFlags = result;
  }
}

/// Abstract base class for elements whose type is guaranteed to be a function
/// type.
abstract class ElementImplWithFunctionType implements Element {
  /// Gets the element's return type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `returnType` getter should be used instead.
  DartType get returnTypeInternal;

  /// Gets the element's type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `type` getter should be used instead.
  FunctionType get typeInternal;
}

/// A concrete implementation of an [ElementLocation].
class ElementLocationImpl implements ElementLocation {
  /// The character used to separate components in the encoded form.
  static const int _SEPARATOR_CHAR = 0x3B;

  /// The path to the element whose location is represented by this object.
  late final List<String> _components;

  /// The object managing [indexKeyId] and [indexLocationId].
  Object? indexOwner;

  /// A cached id of this location in index.
  int? indexKeyId;

  /// A cached id of this location in index.
  int? indexLocationId;

  /// Initialize a newly created location to represent the given [element].
  ElementLocationImpl.con1(Element element) {
    List<String> components = <String>[];
    Element? ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl).identifier);
      ancestor = ancestor.enclosingElement;
    }
    _components = components;
  }

  /// Initialize a newly created location from the given [encoding].
  ElementLocationImpl.con2(String encoding) {
    _components = _decode(encoding);
  }

  /// Initialize a newly created location from the given [components].
  ElementLocationImpl.con3(List<String> components) {
    _components = components;
  }

  @override
  List<String> get components => _components;

  @override
  String get encoding {
    StringBuffer buffer = StringBuffer();
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        buffer.writeCharCode(_SEPARATOR_CHAR);
      }
      _encode(buffer, _components[i]);
    }
    return buffer.toString();
  }

  @override
  int get hashCode => Object.hashAll(_components);

  @override
  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    if (object is ElementLocationImpl) {
      List<String> otherComponents = object._components;
      int length = _components.length;
      if (otherComponents.length != length) {
        return false;
      }
      for (int i = 0; i < length; i++) {
        if (_components[i] != otherComponents[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => encoding;

  /// Decode the [encoding] of a location into a list of components and return
  /// the components.
  List<String> _decode(String encoding) {
    List<String> components = <String>[];
    StringBuffer buffer = StringBuffer();
    int index = 0;
    int length = encoding.length;
    while (index < length) {
      int currentChar = encoding.codeUnitAt(index);
      if (currentChar == _SEPARATOR_CHAR) {
        if (index + 1 < length &&
            encoding.codeUnitAt(index + 1) == _SEPARATOR_CHAR) {
          buffer.writeCharCode(_SEPARATOR_CHAR);
          index += 2;
        } else {
          components.add(buffer.toString());
          buffer = StringBuffer();
          index++;
        }
      } else {
        buffer.writeCharCode(currentChar);
        index++;
      }
    }
    components.add(buffer.toString());
    return components;
  }

  /// Append an encoded form of the given [component] to the given [buffer].
  void _encode(StringBuffer buffer, String component) {
    int length = component.length;
    for (int i = 0; i < length; i++) {
      int currentChar = component.codeUnitAt(i);
      if (currentChar == _SEPARATOR_CHAR) {
        buffer.writeCharCode(_SEPARATOR_CHAR);
      }
      buffer.writeCharCode(currentChar);
    }
  }
}

/// An [AbstractClassElementImpl] which is an enum.
class EnumElementImpl extends AbstractClassElementImpl {
  ElementLinkedData? linkedData;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  EnumElementImpl(String name, int offset) : super(name, offset);

  @override
  List<PropertyAccessorElement> get accessors {
    linkedData?.read(this);
    return _accessors;
  }

  @override
  List<InterfaceType> get allSupertypes =>
      <InterfaceType>[...interfaces, supertype];

  List<FieldElement> get constants {
    return fields.where((field) => !field.isSynthetic).toList();
  }

  List<FieldElement> get constants_unresolved {
    return _fields.where((field) => !field.isSynthetic).toList();
  }

  @override
  List<ConstructorElement> get constructors {
    // The equivalent code for enums in the spec shows a single constructor,
    // but that constructor is not callable (since it is a compile-time error
    // to subclass, mix-in, implement, or explicitly instantiate an enum).
    // So we represent this as having no constructors.
    return const <ConstructorElement>[];
  }

  @override
  List<FieldElement> get fields {
    linkedData?.read(this);
    return _fields;
  }

  @override
  bool get hasNonFinalField => false;

  @override
  bool get hasStaticMember => true;

  @override
  List<InterfaceType> get interfaces {
    var enumType = library.typeProvider.enumType;
    return enumType != null ? <InterfaceType>[enumType] : const [];
  }

  @override
  bool get isAbstract => false;

  @override
  bool get isEnum => true;

  @override
  bool get isMixinApplication => false;

  @override
  bool get isSimplyBounded => true;

  @override
  bool get isValidMixin => false;

  @override
  ElementKind get kind => ElementKind.ENUM;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MethodElement> get methods {
    linkedData?.read(this);
    return _methods;
  }

  @override
  List<InterfaceType> get mixins => const <InterfaceType>[];

  @override
  String get name {
    return super.name!;
  }

  @override
  InterfaceType get supertype => library.typeProvider.objectType;

  @override
  List<TypeParameterElement> get typeParameters =>
      const <TypeParameterElement>[];

  @override
  ConstructorElement? get unnamedConstructor => null;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeEnumElement(this);
  }

  /// Create the only method enums have - `toString()`.
  void createToStringMethodElement() {
    var method = MethodElementImpl('toString', -1);
    method.isSynthetic = true;
    method.enclosingElement = this;
    method.reference = reference?.getChild('@method').getChild('toString');
    _methods = <MethodElement>[method];
  }

  @override
  ConstructorElement? getNamedConstructor(String name) => null;

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

/// A base class for concrete implementations of an [ExecutableElement].
abstract class ExecutableElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements ExecutableElement, ElementImplWithFunctionType {
  /// A list containing all of the parameters defined by this executable
  /// element.
  List<ParameterElement> _parameters = const [];

  /// The inferred return type of this executable element.
  DartType? _returnType;

  /// The type of function defined by this executable element.
  FunctionType? _type;

  ElementLinkedData? linkedData;

  /// Initialize a newly created executable element to have the given [name] and
  /// [offset].
  ExecutableElementImpl(String name, int offset, {Reference? reference})
      : super(name, offset, reference: reference);

  @override
  Element get enclosingElement => super.enclosingElement!;

  @override
  bool get hasImplicitReturnType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this executable element has an implicit return type.
  set hasImplicitReturnType(bool hasImplicitReturnType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitReturnType);
  }

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isAsynchronous {
    return hasModifier(Modifier.ASYNCHRONOUS);
  }

  /// Set whether this executable element's body is asynchronous.
  set isAsynchronous(bool isAsynchronous) {
    setModifier(Modifier.ASYNCHRONOUS, isAsynchronous);
  }

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  /// Set whether this executable element is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isGenerator {
    return hasModifier(Modifier.GENERATOR);
  }

  /// Set whether this method's body is a generator.
  set isGenerator(bool isGenerator) {
    setModifier(Modifier.GENERATOR, isGenerator);
  }

  @override
  bool get isOperator => false;

  @override
  bool get isSynchronous => !isAsynchronous;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    return super.name!;
  }

  @override
  List<ParameterElement> get parameters =>
      ElementTypeProvider.current.getExecutableParameters(this);

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  List<ParameterElement> get parameters_unresolved {
    return _parameters;
  }

  /// Gets the element's parameters, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the [parameters] getter should be used instead.
  List<ParameterElement> get parametersInternal {
    linkedData?.read(this);
    return _parameters;
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  set returnType(DartType returnType) {
    _returnType = returnType;
    // We do this because of return type inference. At the moment when we
    // create a local function element we don't know yet its return type,
    // because we have not done static type analysis yet.
    // It somewhere it between we access the type of this element, so it gets
    // cached in the element. When we are done static type analysis, we then
    // should clear this cached type to make it right.
    // TODO(scheglov) Remove when type analysis is done in the single pass.
    _type = null;
  }

  @override
  DartType get returnTypeInternal {
    linkedData?.read(this);
    return _returnType!;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  set type(FunctionType type) {
    _type = type;
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  /// Set the type parameters defined by this executable element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(typeParameters, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/// A concrete implementation of an [ExportElement].
class ExportElementImpl extends UriReferencedElementImpl
    implements ExportElement {
  @override
  LibraryElement? exportedLibrary;

  @override
  List<NamespaceCombinator> combinators = const [];

  /// Initialize a newly created export element at the given [offset].
  ExportElementImpl(int offset) : super(null, offset);

  @override
  CompilationUnitElementImpl get enclosingUnit {
    var enclosingLibrary = enclosingElement as LibraryElementImpl;
    return enclosingLibrary._definingCompilationUnit;
  }

  @override
  String get identifier => exportedLibrary!.name;

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitExportElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExportElement(this);
  }
}

/// A concrete implementation of an [ExtensionElement].
class ExtensionElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements ExtensionElement {
  /// The type being extended.
  DartType? _extendedType;

  /// A list containing all of the accessors (getters and setters) contained in
  /// this extension.
  List<PropertyAccessorElement> _accessors = const [];

  /// A list containing all of the fields contained in this extension.
  List<FieldElement> _fields = const [];

  /// A list containing all of the methods contained in this extension.
  List<MethodElement> _methods = const [];

  ElementLinkedData? linkedData;

  /// Initialize a newly created extension element to have the given [name] at
  /// the given [offset] in the file that contains the declaration of this
  /// element.
  ExtensionElementImpl(String? name, int nameOffset) : super(name, nameOffset);

  @override
  List<PropertyAccessorElement> get accessors {
    return _accessors;
  }

  set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  String get displayName => name ?? '';

  @override
  CompilationUnitElementImpl get enclosingElement {
    return _enclosingElement as CompilationUnitElementImpl;
  }

  @override
  DartType get extendedType =>
      ElementTypeProvider.current.getExtendedType(this);

  set extendedType(DartType extendedType) {
    _extendedType = extendedType;
  }

  DartType get extendedTypeInternal {
    linkedData?.read(this);
    return _extendedType!;
  }

  @override
  List<FieldElement> get fields {
    return _fields;
  }

  set fields(List<FieldElement> fields) {
    for (FieldElement field in fields) {
      (field as FieldElementImpl).enclosingElement = this;
    }
    _fields = fields;
  }

  @override
  String get identifier {
    if (reference != null) {
      return reference!.name;
    }
    return super.identifier;
  }

  @override
  bool get isSimplyBounded => true;

  @override
  ElementKind get kind => ElementKind.EXTENSION;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MethodElement> get methods {
    return _methods;
  }

  /// Set the methods contained in this extension to the given [methods].
  set methods(List<MethodElement> methods) {
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    _methods = methods;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return super.typeParameters;
  }

  /// Set the type parameters defined by this extension to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitExtensionElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionElement(this);
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) {
    int length = accessors.length;
    for (int i = 0; i < length; i++) {
      PropertyAccessorElement accessor = accessors[i];
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String methodName) {
    int length = methods.length;
    for (int i = 0; i < length; i++) {
      MethodElement method = methods[i];
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return AbstractClassElementImpl.getSetterFromAccessors(
        setterName, accessors);
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(accessors, visitor);
    safelyVisitChildren(fields, visitor);
    safelyVisitChildren(methods, visitor);
    safelyVisitChildren(typeParameters, visitor);
  }
}

/// A concrete implementation of a [FieldElement].
class FieldElementImpl extends PropertyInducingElementImpl
    implements FieldElement {
  /// True if this field inherits from a covariant parameter. This happens
  /// when it overrides a field in a supertype that is covariant.
  bool inheritsCovariant = false;

  /// Initialize a newly created synthetic field element to have the given
  /// [name] at the given [offset].
  FieldElementImpl(String name, int offset) : super(name, offset);

  @override
  FieldElement get declaration => this;

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isCovariant {
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this field is explicitly marked as being covariant.
  set isCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isEnumConstant =>
      enclosingElement is ClassElement &&
      (enclosingElement as ClassElement).isEnum &&
      !isSynthetic;

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  /// Set whether this field is static.
  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);
}

/// A [ParameterElementImpl] that has the additional information of the
/// [FieldElement] associated with the parameter.
class FieldFormalParameterElementImpl extends ParameterElementImpl
    implements FieldFormalParameterElement {
  @override
  FieldElement? field;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FieldFormalParameterElementImpl({
    required String name,
    required int nameOffset,
    required ParameterKind parameterKind,
  }) : super(
          name: name,
          nameOffset: nameOffset,
          parameterKind: parameterKind,
        );

  /// Initializing formals are visible only in the "formal parameter
  /// initializer scope", which is the current scope of the initializer list
  /// of the constructor, and which is enclosed in the scope where the
  /// constructor is declared. And according to the specification, they
  /// introduce final local variables, always, regardless whether the field
  /// is final.
  @override
  bool get isFinal => true;

  @override
  bool get isInitializingFormal => true;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A concrete implementation of a [FunctionElement].
class FunctionElementImpl extends ExecutableElementImpl
    implements FunctionElement, FunctionTypedElementImpl {
  /// Initialize a newly created function element to have the given [name] and
  /// [offset].
  FunctionElementImpl(String name, int offset) : super(name, offset);

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  @override
  ExecutableElement get declaration => this;

  @override
  String get identifier {
    String identifier = super.identifier;
    Element? enclosing = enclosingElement;
    if (enclosing is ExecutableElement || enclosing is VariableElement) {
      identifier += "@$nameOffset";
    }
    return identifier;
  }

  @override
  bool get isEntryPoint {
    return isStatic && displayName == FunctionElement.MAIN_FUNCTION_NAME;
  }

  @override
  bool get isStatic => enclosingElement is CompilationUnitElement;

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFunctionElement(this);
}

/// Common internal interface shared by elements whose type is a function type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElementImpl
    implements _ExistingElementImpl, FunctionTypedElement {
  set returnType(DartType returnType);
}

/// The element used for a generic function type.
///
/// Clients may not extend, implement or mix-in this class.
class GenericFunctionTypeElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements
        GenericFunctionTypeElement,
        FunctionTypedElementImpl,
        ElementImplWithFunctionType {
  /// The declared return type of the function.
  DartType? _returnType;

  /// The elements representing the parameters of the function.
  List<ParameterElement> _parameters = const [];

  /// Is `true` if the type has the question mark, so is nullable.
  bool isNullable = false;

  /// The type defined by this element.
  FunctionType? _type;

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  GenericFunctionTypeElementImpl.forOffset(int nameOffset)
      : super("", nameOffset);

  @override
  String get identifier => '-';

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this function type element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  /// Set the return type defined by this function type element to the given
  /// [returnType].
  @override
  set returnType(DartType returnType) {
    _returnType = returnType;
  }

  @override
  DartType get returnTypeInternal {
    return _returnType!;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  /// Set the function type defined by this function type element to the given
  /// [type].
  set type(FunctionType type) {
    _type = type;
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix:
          isNullable ? NullabilitySuffix.question : _noneOrStarSuffix,
    );
  }

  /// Set the type parameters defined by this function type element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitGenericFunctionTypeElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeGenericFunctionTypeElement(this);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(typeParameters, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/// A concrete implementation of a [HideElementCombinator].
class HideElementCombinatorImpl implements HideElementCombinator {
  @override
  List<String> hiddenNames = const [];

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("show ");
    int count = hiddenNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(hiddenNames[i]);
    }
    return buffer.toString();
  }
}

/// A concrete implementation of an [ImportElement].
class ImportElementImpl extends UriReferencedElementImpl
    implements ImportElement {
  @override
  LibraryElement? importedLibrary;

  @override
  PrefixElement? prefix;

  @override
  List<NamespaceCombinator> combinators = const [];

  /// The cached value of [namespace].
  Namespace? _namespace;

  /// Initialize a newly created import element at the given [offset].
  /// The offset may be `-1` if the import is synthetic.
  ImportElementImpl(int offset) : super(null, offset);

  @override
  CompilationUnitElementImpl get enclosingUnit {
    var enclosingLibrary = enclosingElement as LibraryElementImpl;
    return enclosingLibrary._definingCompilationUnit;
  }

  @override
  String get identifier => "${importedLibrary?.identifier}@$nameOffset";

  @override
  bool get isDeferred {
    return hasModifier(Modifier.DEFERRED);
  }

  /// Set whether this import is for a deferred library.
  set isDeferred(bool isDeferred) {
    setModifier(Modifier.DEFERRED, isDeferred);
  }

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  Namespace get namespace {
    return _namespace ??=
        NamespaceBuilder().createImportNamespaceForDirective(this);
  }

  @Deprecated('Use prefix.nameOffset instead')
  @override
  int get prefixOffset => prefix?.nameOffset ?? -1;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitImportElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeImportElement(this);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    prefix?.accept(visitor);
  }
}

/// A concrete implementation of a [LabelElement].
class LabelElementImpl extends ElementImpl implements LabelElement {
  /// A flag indicating whether this label is associated with a `switch`
  /// statement.
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchStatement;

  /// A flag indicating whether this label is associated with a `switch` member
  /// (`case` or `default`).
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchMember;

  /// Initialize a newly created label element to have the given [name].
  /// [onSwitchStatement] should be `true` if this label is associated with a
  /// `switch` statement and [onSwitchMember] should be `true` if this label is
  /// associated with a `switch` member.
  LabelElementImpl(String name, int nameOffset, this._onSwitchStatement,
      this._onSwitchMember)
      : super(name, nameOffset);

  @override
  String get displayName => name;

  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

  /// Return `true` if this label is associated with a `switch` member (`case
  /// ` or`default`).
  bool get isOnSwitchMember => _onSwitchMember;

  /// Return `true` if this label is associated with a `switch` statement.
  bool get isOnSwitchStatement => _onSwitchStatement;

  @override
  ElementKind get kind => ElementKind.LABEL;

  @override
  String get name => super.name!;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitLabelElement(this);
}

/// A concrete implementation of a [LibraryElement].
class LibraryElementImpl extends _ExistingElementImpl
    implements LibraryElement {
  /// The analysis context in which this library is defined.
  @override
  final AnalysisContext context;

  @override
  final AnalysisSession session;

  /// If `true`, then this library is valid in the session.
  ///
  /// A library becomes invalid when one of its files, or one of its
  /// dependencies, changes.
  bool isValid = true;

  /// The language version for the library.
  LibraryLanguageVersion? _languageVersion;

  bool hasTypeProviderSystemSet = false;

  @override
  late TypeProviderImpl typeProvider;

  @override
  late TypeSystemImpl typeSystem;

  LibraryElementLinkedData? linkedData;

  @override
  final FeatureSet featureSet;

  /// The compilation unit that defines this library.
  late CompilationUnitElementImpl _definingCompilationUnit;

  /// The entry point for this library, or `null` if this library does not have
  /// an entry point.
  FunctionElement? _entryPoint;

  /// A list containing specifications of all of the imports defined in this
  /// library.
  List<ImportElement> _imports = _Sentinel.importElement;

  /// A list containing specifications of all of the exports defined in this
  /// library.
  List<ExportElement> _exports = _Sentinel.exportElement;

  /// A list containing all of the compilation units that are included in this
  /// library using a `part` directive.
  List<CompilationUnitElement> _parts = const <CompilationUnitElement>[];

  /// The element representing the synthetic function `loadLibrary` that is
  /// defined for this library, or `null` if the element has not yet been
  /// created.
  late FunctionElement _loadLibraryFunction;

  @override
  int nameLength;

  /// The export [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _exportNamespace;

  /// The public [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _publicNamespace;

  /// The cached list of prefixes.
  List<PrefixElement>? _prefixes;

  /// The scope of this library, `null` if it has not been created yet.
  LibraryScope? _scope;

  /// Initialize a newly created library element in the given [context] to have
  /// the given [name] and [offset].
  LibraryElementImpl(this.context, this.session, String name, int offset,
      this.nameLength, this.featureSet)
      : linkedData = null,
        super(name, offset);

  @override
  List<ExtensionElement> get accessibleExtensions => scope.extensions;

  @override
  CompilationUnitElement get definingCompilationUnit =>
      _definingCompilationUnit;

  /// Set the compilation unit that defines this library to the given
  ///  compilation[unit].
  set definingCompilationUnit(CompilationUnitElement unit) {
    assert((unit as CompilationUnitElementImpl).librarySource == unit.source);
    (unit as CompilationUnitElementImpl).enclosingElement = this;
    _definingCompilationUnit = unit;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  @override
  FunctionElement? get entryPoint {
    linkedData?.read(this);
    return _entryPoint;
  }

  set entryPoint(FunctionElement? entryPoint) {
    _entryPoint = entryPoint;
  }

  @override
  List<LibraryElement> get exportedLibraries {
    HashSet<LibraryElement> libraries = HashSet<LibraryElement>();
    for (ExportElement element in exports) {
      var library = element.exportedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return libraries.toList(growable: false);
  }

  @override
  Namespace get exportNamespace {
    if (_exportNamespace != null) return _exportNamespace!;

    final linkedData = this.linkedData;
    if (linkedData != null) {
      var elements = linkedData.elementFactory;
      return _exportNamespace = elements.buildExportNamespace(source.uri);
    }

    return _exportNamespace!;
  }

  set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
  }

  @override
  List<ExportElement> get exports {
    linkedData?.read(this);
    return _exports;
  }

  /// Set the specifications of all of the exports defined in this library to
  /// the given list of [exports].
  set exports(List<ExportElement> exports) {
    for (ExportElement exportElement in exports) {
      (exportElement as ExportElementImpl).enclosingElement = this;
    }
    _exports = exports;
  }

  List<ExportElement> get exports_unresolved {
    return _exports;
  }

  @Deprecated('Support for dart-ext is replaced with FFI')
  @override
  bool get hasExtUri => false;

  @Deprecated('Not useful for clients')
  @override
  bool get hasLoadLibraryFunction {
    for (int i = 0; i < units.length; i++) {
      if (units[i].hasLoadLibraryFunction) {
        return true;
      }
    }
    return false;
  }

  bool get hasPartOfDirective {
    return hasModifier(Modifier.HAS_PART_OF_DIRECTIVE);
  }

  set hasPartOfDirective(bool hasPartOfDirective) {
    setModifier(Modifier.HAS_PART_OF_DIRECTIVE, hasPartOfDirective);
  }

  @override
  String get identifier => '${_definingCompilationUnit.source.uri}';

  @override
  List<LibraryElement> get importedLibraries {
    HashSet<LibraryElement> libraries = HashSet<LibraryElement>();
    for (ImportElement element in imports) {
      var library = element.importedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return libraries.toList(growable: false);
  }

  @override
  List<ImportElement> get imports {
    linkedData?.read(this);
    return _imports;
  }

  /// Set the specifications of all of the imports defined in this library to
  /// the given list of [imports].
  set imports(List<ImportElement> imports) {
    for (ImportElement importElement in imports) {
      (importElement as ImportElementImpl).enclosingElement = this;
      var prefix = importElement.prefix as PrefixElementImpl?;
      if (prefix != null) {
        prefix.enclosingElement = this;
      }
    }
    _imports = imports;
    _prefixes = null;
  }

  List<ImportElement> get imports_unresolved {
    return _imports;
  }

  @override
  bool get isBrowserApplication =>
      entryPoint != null && isOrImportsBrowserLibrary;

  @override
  bool get isDartAsync => name == "dart.async";

  @override
  bool get isDartCore => name == "dart.core";

  @override
  bool get isInSdk {
    var uri = definingCompilationUnit.source.uri;
    return DartUriResolver.isDartUri(uri);
  }

  @override
  bool get isNonNullableByDefault =>
      ElementTypeProvider.current.isLibraryNonNullableByDefault(this);

  bool get isNonNullableByDefaultInternal {
    return featureSet.isEnabled(Feature.non_nullable);
  }

  /// Return `true` if the receiver directly or indirectly imports the
  /// 'dart:html' libraries.
  bool get isOrImportsBrowserLibrary {
    List<LibraryElement> visited = <LibraryElement>[];
    var htmlLibSource = context.sourceFactory.forUri(DartSdk.DART_HTML);
    visited.add(this);
    for (int index = 0; index < visited.length; index++) {
      LibraryElement library = visited[index];
      var source = library.definingCompilationUnit.source;
      if (source == htmlLibSource) {
        return true;
      }
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!visited.contains(importedLibrary)) {
          visited.add(importedLibrary);
        }
      }
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!visited.contains(exportedLibrary)) {
          visited.add(exportedLibrary);
        }
      }
    }
    return false;
  }

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  LibraryLanguageVersion get languageVersion {
    return _languageVersion ??= LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );
  }

  set languageVersion(LibraryLanguageVersion languageVersion) {
    _languageVersion = languageVersion;
  }

  @override
  LibraryElementImpl get library => this;

  @override
  FunctionElement get loadLibraryFunction {
    return _loadLibraryFunction;
  }

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name => super.name!;

  @override
  List<CompilationUnitElement> get parts => _parts;

  /// Set the compilation units that are included in this library using a `part`
  /// directive to the given list of [parts].
  set parts(List<CompilationUnitElement> parts) {
    for (CompilationUnitElement compilationUnit in parts) {
      assert((compilationUnit as CompilationUnitElementImpl).librarySource ==
          source);
      (compilationUnit as CompilationUnitElementImpl).enclosingElement = this;
    }
    _parts = parts;
  }

  @override
  List<PrefixElement> get prefixes =>
      _prefixes ??= buildPrefixesFromImports(imports);

  @override
  Namespace get publicNamespace {
    return _publicNamespace ??=
        NamespaceBuilder().createPublicNamespaceForLibrary(this);
  }

  set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
  }

  @override
  LibraryScope get scope {
    return _scope ??= LibraryScope(this);
  }

  @override
  Source get source {
    return _definingCompilationUnit.source;
  }

  @override
  Iterable<Element> get topLevelElements sync* {
    for (var unit in units) {
      yield* unit.accessors;
      yield* unit.classes;
      yield* unit.enums;
      yield* unit.extensions;
      yield* unit.functions;
      yield* unit.mixins;
      yield* unit.topLevelVariables;
      yield* unit.typeAliases;
    }
  }

  @override
  List<CompilationUnitElement> get units {
    List<CompilationUnitElement> units = <CompilationUnitElement>[];
    units.add(_definingCompilationUnit);
    units.addAll(_parts);
    return units;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitLibraryElement(this);

  /// Create the [FunctionElement] to be returned by [loadLibraryFunction].
  /// The [typeProvider] must be already set.
  void createLoadLibraryFunction() {
    _loadLibraryFunction =
        FunctionElementImpl(FunctionElement.LOAD_LIBRARY_NAME, -1)
          ..enclosingElement = library
          ..isSynthetic = true
          ..returnType = typeProvider.futureDynamicType;
  }

  ClassElement? getEnum(String name) {
    var element = _definingCompilationUnit.getEnum(name);
    if (element != null) {
      return element;
    }
    for (CompilationUnitElement part in _parts) {
      element = part.getEnum(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) {
    return getImportsWithPrefixFromImports(prefixElement, imports);
  }

  @override
  ClassElement? getType(String className) {
    return getTypeFromParts(className, _definingCompilationUnit, _parts);
  }

  /// Indicates whether it is unnecessary to report an undefined identifier
  /// error for an identifier reference with the given [name] and optional
  /// [prefix].
  ///
  /// This method is intended to reduce spurious errors in circumstances where
  /// an undefined identifier occurs as the result of a missing (most likely
  /// code generated) file.  It will only return `true` in a circumstance where
  /// the current library is guaranteed to have at least one other error (due to
  /// a missing part or import), so there is no risk that ignoring the undefined
  /// identifier would cause an invalid program to be treated as valid.
  bool shouldIgnoreUndefined({
    required String? prefix,
    required String name,
  }) {
    for (var importElement in imports) {
      if (importElement.prefix?.name == prefix &&
          importElement.importedLibrary?.isSynthetic != false) {
        var showCombinators = importElement.combinators
            .whereType<ShowElementCombinator>()
            .toList();
        if (prefix != null && showCombinators.isEmpty) {
          return true;
        }
        for (var combinator in showCombinators) {
          if (combinator.shownNames.contains(name)) {
            return true;
          }
        }
      }
    }

    if (prefix == null && name.startsWith(r'_$')) {
      for (var partElement in parts) {
        if (partElement.isSynthetic && isGeneratedSource(partElement.source)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Convenience wrapper around [shouldIgnoreUndefined] that calls it for a
  /// given (possibly prefixed) identifier [node].
  bool shouldIgnoreUndefinedIdentifier(Identifier node) {
    if (node is PrefixedIdentifier) {
      return shouldIgnoreUndefined(
        prefix: node.prefix.name,
        name: node.identifier.name,
      );
    }

    return shouldIgnoreUndefined(
      prefix: null,
      name: (node as SimpleIdentifier).name,
    );
  }

  @override
  T toLegacyElementIfOptOut<T extends Element>(T element) {
    if (isNonNullableByDefault) return element;
    return Member.legacy(element) as T;
  }

  @override
  DartType toLegacyTypeIfOptOut(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    _definingCompilationUnit.accept(visitor);
    safelyVisitChildren(exports, visitor);
    safelyVisitChildren(imports, visitor);
    safelyVisitChildren(_parts, visitor);
  }

  static List<PrefixElement> buildPrefixesFromImports(
      List<ImportElement> imports) {
    HashSet<PrefixElement> prefixes = HashSet<PrefixElement>();
    for (ImportElement element in imports) {
      var prefix = element.prefix;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toList(growable: false);
  }

  static List<ImportElement> getImportsWithPrefixFromImports(
      PrefixElement prefixElement, List<ImportElement> imports) {
    int count = imports.length;
    List<ImportElement> importList = <ImportElement>[];
    for (int i = 0; i < count; i++) {
      if (identical(imports[i].prefix, prefixElement)) {
        importList.add(imports[i]);
      }
    }
    return importList;
  }

  static ClassElement? getTypeFromParts(
      String className,
      CompilationUnitElement definingCompilationUnit,
      List<CompilationUnitElement> parts) {
    var type = definingCompilationUnit.getType(className);
    if (type != null) {
      return type;
    }
    for (CompilationUnitElement part in parts) {
      type = part.getType(className);
      if (type != null) {
        return type;
      }
    }
    return null;
  }
}

/// A concrete implementation of a [LocalVariableElement].
class LocalVariableElementImpl extends NonParameterVariableElementImpl
    implements LocalVariableElement {
  @override
  late bool hasInitializer;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  LocalVariableElementImpl(String name, int offset) : super(name, offset);

  @override
  String get identifier {
    return '$name$nameOffset';
  }

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitLocalVariableElement(this);
}

/// A concrete implementation of a [MethodElement].
class MethodElementImpl extends ExecutableElementImpl implements MethodElement {
  /// Is `true` if this method is `operator==`, and there is no explicit
  /// type specified for its formal parameter, in this method or in any
  /// overridden methods other than the one declared in `Object`.
  bool isOperatorEqualWithParameterTypeFromObject = false;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  /// If this method is a synthetic element which is based on another method
  /// with some modifications (such as making some parameters covariant),
  /// this field contains the base method.
  MethodElement? prototype;

  /// Initialize a newly created method element to have the given [name] at the
  /// given [offset].
  MethodElementImpl(String name, int offset) : super(name, offset);

  @override
  MethodElement get declaration => prototype ?? this;

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isOperator {
    String name = displayName;
    if (name.isEmpty) {
      return false;
    }
    int first = name.codeUnitAt(0);
    return !((0x61 <= first && first <= 0x7A) ||
        (0x41 <= first && first <= 0x5A) ||
        first == 0x5F ||
        first == 0x24);
  }

  @override
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  /// Set whether this method is static.
  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  String get name {
    String name = super.name;
    if (name == '-' && parametersInternal.isEmpty) {
      return 'unary-';
    }
    return name;
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic && enclosingElement is EnumElementImpl) {
      return enclosingElement;
    }
    return this;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);
}

/// A [ClassElementImpl] representing a mixin declaration.
class MixinElementImpl extends ClassElementImpl {
  // TODO(brianwilkerson) Consider creating an abstract superclass of
  // ClassElementImpl that contains the portions of the API that this class
  // needs, and make this class extend the new class.

  /// A list containing all of the superclass constraints that are defined for
  /// the mixin.
  List<InterfaceType> _superclassConstraints = const [];

  @override
  late List<String> superInvokedNames;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  MixinElementImpl(String name, int offset) : super(name, offset);

  @override
  bool get isAbstract => true;

  @override
  bool get isMixin => true;

  @override
  List<InterfaceType> get mixins => const <InterfaceType>[];

  @override
  List<InterfaceType> get superclassConstraints {
    linkedData?.read(this);
    return _superclassConstraints;
  }

  set superclassConstraints(List<InterfaceType> superclassConstraints) {
    _superclassConstraints = superclassConstraints;
  }

  @override
  InterfaceType? get supertype => null;

  @override
  set supertype(InterfaceType? supertype) {
    throw StateError('Attempt to set a supertype for a mixin declaratio.');
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeMixinElement(this);
  }
}

/// The constants for all of the modifiers defined by the Dart language and for
/// a few additional flags that are useful.
///
/// Clients may not extend, implement or mix-in this class.
class Modifier implements Comparable<Modifier> {
  /// Indicates that the modifier 'abstract' was applied to the element.
  static const Modifier ABSTRACT = Modifier('ABSTRACT', 0);

  /// Indicates that an executable element has a body marked as being
  /// asynchronous.
  static const Modifier ASYNCHRONOUS = Modifier('ASYNCHRONOUS', 1);

  /// Indicates that the modifier 'const' was applied to the element.
  static const Modifier CONST = Modifier('CONST', 2);

  /// Indicates that the modifier 'covariant' was applied to the element.
  static const Modifier COVARIANT = Modifier('COVARIANT', 3);

  /// Indicates that the class is `Object` from `dart:core`.
  static const Modifier DART_CORE_OBJECT = Modifier('DART_CORE_OBJECT', 4);

  /// Indicates that the import element represents a deferred library.
  static const Modifier DEFERRED = Modifier('DEFERRED', 5);

  /// Indicates that a class element was defined by an enum declaration.
  static const Modifier ENUM = Modifier('ENUM', 6);

  /// Indicates that a class element was defined by an enum declaration.
  static const Modifier EXTERNAL = Modifier('EXTERNAL', 7);

  /// Indicates that the modifier 'factory' was applied to the element.
  static const Modifier FACTORY = Modifier('FACTORY', 8);

  /// Indicates that the modifier 'final' was applied to the element.
  static const Modifier FINAL = Modifier('FINAL', 9);

  /// Indicates that an executable element has a body marked as being a
  /// generator.
  static const Modifier GENERATOR = Modifier('GENERATOR', 10);

  /// Indicates that the pseudo-modifier 'get' was applied to the element.
  static const Modifier GETTER = Modifier('GETTER', 11);

  /// A flag used for libraries indicating that the variable has an explicit
  /// initializer.
  static const Modifier HAS_INITIALIZER = Modifier('HAS_INITIALIZER', 12);

  /// A flag used for fields and top-level variables that have implicit type,
  /// and specify when the type has been inferred.
  static const Modifier HAS_TYPE_INFERRED = Modifier('HAS_TYPE_INFERRED', 13);

  /// A flag used for libraries indicating that the defining compilation unit
  /// has a `part of` directive, meaning that this unit should be a part,
  /// but is used as a library.
  static const Modifier HAS_PART_OF_DIRECTIVE =
      Modifier('HAS_PART_OF_DIRECTIVE', 14);

  /// Indicates that the associated element did not have an explicit type
  /// associated with it. If the element is an [ExecutableElement], then the
  /// type being referred to is the return type.
  static const Modifier IMPLICIT_TYPE = Modifier('IMPLICIT_TYPE', 15);

  /// Indicates that modifier 'lazy' was applied to the element.
  static const Modifier LATE = Modifier('LATE', 16);

  /// Indicates that a class is a mixin application.
  static const Modifier MIXIN_APPLICATION = Modifier('MIXIN_APPLICATION', 17);

  /// Indicates that the pseudo-modifier 'set' was applied to the element.
  static const Modifier SETTER = Modifier('SETTER', 18);

  /// Indicates that the modifier 'static' was applied to the element.
  static const Modifier STATIC = Modifier('STATIC', 19);

  /// Indicates that the element does not appear in the source code but was
  /// implicitly created. For example, if a class does not define any
  /// constructors, an implicit zero-argument constructor will be created and it
  /// will be marked as being synthetic.
  static const Modifier SYNTHETIC = Modifier('SYNTHETIC', 20);

  static const List<Modifier> values = [
    ABSTRACT,
    ASYNCHRONOUS,
    CONST,
    COVARIANT,
    DART_CORE_OBJECT,
    DEFERRED,
    ENUM,
    EXTERNAL,
    FACTORY,
    FINAL,
    GENERATOR,
    GETTER,
    HAS_INITIALIZER,
    HAS_PART_OF_DIRECTIVE,
    IMPLICIT_TYPE,
    LATE,
    MIXIN_APPLICATION,
    SETTER,
    STATIC,
    SYNTHETIC
  ];

  /// The name of this modifier.
  final String name;

  /// The ordinal value of the modifier.
  final int ordinal;

  const Modifier(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(Modifier other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// A concrete implementation of a [MultiplyDefinedElement].
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {
  /// The unique integer identifier of this element.
  @override
  final int id = ElementImpl._NEXT_ID++;

  /// The analysis context in which the multiply defined elements are defined.
  @override
  final AnalysisContext context;

  @override
  final AnalysisSession session;

  /// The name of the conflicting elements.
  @override
  final String name;

  @override
  final List<Element> conflictingElements;

  /// Initialize a newly created element in the given [context] to represent
  /// the given non-empty [conflictingElements].
  MultiplyDefinedElementImpl(
      this.context, this.session, this.name, this.conflictingElements);

  @override
  Element? get declaration => null;

  @override
  String get displayName => name;

  @override
  String? get documentationComment => null;

  @override
  Element? get enclosingElement => null;

  @override
  bool get hasAlwaysThrows => false;

  @override
  bool get hasDeprecated => false;

  @override
  bool get hasDoNotStore => false;

  @override
  bool get hasFactory => false;

  @override
  bool get hasInternal => false;

  @override
  bool get hasIsTest => false;

  @override
  bool get hasIsTestGroup => false;

  @override
  bool get hasJS => false;

  @override
  bool get hasLiteral => false;

  @override
  bool get hasMustCallSuper => false;

  @override
  bool get hasNonVirtual => false;

  @override
  bool get hasOptionalTypeArgs => false;

  @override
  bool get hasOverride => false;

  @override
  bool get hasProtected => false;

  @override
  bool get hasRequired => false;

  @override
  bool get hasSealed => false;

  @override
  bool get hasUseResult => false;

  @override
  bool get hasVisibleForOverriding => false;

  @override
  bool get hasVisibleForTemplate => false;

  @override
  bool get hasVisibleForTesting => false;

  @override
  bool get isPrivate {
    throw UnimplementedError();
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic => true;

  bool get isVisibleForTemplate => false;

  @override
  ElementKind get kind => ElementKind.ERROR;

  @override
  LibraryElement? get library => null;

  @override
  Source? get librarySource => null;

  @override
  ElementLocation? get location => null;

  @override
  List<ElementAnnotation> get metadata => const <ElementAnnotation>[];

  @override
  int get nameLength => 0;

  @override
  int get nameOffset => -1;

  @override
  Element get nonSynthetic => this;

  @override
  Source? get source => null;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitMultiplyDefinedElement(this);

  @override
  String getDisplayString({
    required bool withNullability,
    bool multiline = false,
  }) {
    var elementsStr = conflictingElements.map((e) {
      return e.getDisplayString(
        withNullability: withNullability,
      );
    }).join(', ');
    return '[' + elementsStr + ']';
  }

  @override
  String getExtendedDisplayName(String? shortName) {
    if (shortName != null) {
      return shortName;
    }
    return displayName;
  }

  @override
  bool isAccessibleIn(LibraryElement? library) {
    for (Element element in conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }

  @override
  E? thisOrAncestorMatching<E extends Element>(Predicate<Element> predicate) =>
      null;

  @override
  E? thisOrAncestorOfType<E extends Element>() => null;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    bool needsSeparator = false;
    void writeList(List<Element> elements) {
      for (Element element in elements) {
        if (needsSeparator) {
          buffer.write(", ");
        } else {
          needsSeparator = true;
        }
        buffer.write(
          element.getDisplayString(withNullability: true),
        );
      }
    }

    buffer.write("[");
    writeList(conflictingElements);
    buffer.write("]");
    return buffer.toString();
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }
}

/// The synthetic element representing the declaration of the type `Never`.
class NeverElementImpl extends ElementImpl implements TypeDefiningElement {
  /// Return the unique instance of this class.
  static NeverElementImpl get instance => NeverTypeImpl.instance.element;

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  NeverElementImpl() : super('Never', -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.NEVER;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => null;

  DartType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.star:
        return NeverTypeImpl.instanceLegacy;
      case NullabilitySuffix.none:
        return NeverTypeImpl.instance;
    }
  }
}

/// A [VariableElementImpl], which is not a parameter.
abstract class NonParameterVariableElementImpl extends VariableElementImpl
    with _HasLibraryMixin {
  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  NonParameterVariableElementImpl(String name, int offset)
      : super(name, offset);

  @override
  Element get enclosingElement => super.enclosingElement!;

  bool get hasInitializer {
    return hasModifier(Modifier.HAS_INITIALIZER);
  }

  /// Set whether this variable has an initializer.
  set hasInitializer(bool hasInitializer) {
    setModifier(Modifier.HAS_INITIALIZER, hasInitializer);
  }
}

/// A concrete implementation of a [ParameterElement].
class ParameterElementImpl extends VariableElementImpl
    with ParameterElementMixin
    implements ParameterElement {
  /// A list containing all of the parameters defined by this parameter element.
  /// There will only be parameters if this parameter is a function typed
  /// parameter.
  List<ParameterElement> _parameters = const [];

  /// A list containing all of the type parameters defined for this parameter
  /// element. There will only be parameters if this parameter is a function
  /// typed parameter.
  List<TypeParameterElement> _typeParameters = const [];

  @override
  final ParameterKind parameterKind;

  /// The Dart code of the default value.
  String? _defaultValueCode;

  /// True if this parameter inherits from a covariant parameter. This happens
  /// when it overrides a method in a supertype that has a corresponding
  /// covariant parameter.
  bool inheritsCovariant = false;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  ParameterElementImpl({
    required String? name,
    required int nameOffset,
    required this.parameterKind,
  }) : super(name, nameOffset);

  /// Creates a synthetic parameter with [name], [type] and [parameterKind].
  factory ParameterElementImpl.synthetic(
      String? name, DartType type, ParameterKind parameterKind) {
    var element = ParameterElementImpl(
      name: name,
      nameOffset: -1,
      parameterKind: parameterKind,
    );
    element.type = type;
    element.isSynthetic = true;
    return element;
  }

  @override
  ParameterElement get declaration => this;

  @override
  String? get defaultValueCode {
    return _defaultValueCode;
  }

  /// Set Dart code of the default value.
  set defaultValueCode(String? defaultValueCode) {
    _defaultValueCode = defaultValueCode != null
        ? StringUtilities.intern(defaultValueCode)
        : null;
  }

  @override
  bool get hasDefaultValue {
    return defaultValueCode != null;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  /// Return true if this parameter is explicitly marked as being covariant.
  bool get isExplicitlyCovariant {
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this variable parameter is explicitly marked as being
  /// covariant.
  set isExplicitlyCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  bool get isLate => false;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    return _typeParameters;
  }

  /// Set the type parameters defined by this parameter element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameters = typeParameters;
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
}

/// The parameter of an implicit setter.
class ParameterElementImpl_ofImplicitSetter extends ParameterElementImpl {
  final PropertyAccessorElementImpl_ImplicitSetter setter;

  ParameterElementImpl_ofImplicitSetter(
      PropertyAccessorElementImpl_ImplicitSetter setter)
      : setter = setter,
        super(
          name: '_${setter.variable.name}',
          nameOffset: -1,
          parameterKind: ParameterKind.REQUIRED,
        ) {
    enclosingElement = setter;
    isSynthetic = true;
  }

  @override
  bool get inheritsCovariant {
    var variable = setter.variable;
    if (variable is FieldElementImpl) {
      return variable.inheritsCovariant;
    }
    return false;
  }

  @override
  set inheritsCovariant(bool value) {
    var variable = setter.variable;
    if (variable is FieldElementImpl) {
      variable.inheritsCovariant = value;
    }
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  @override
  bool get isExplicitlyCovariant {
    var variable = setter.variable;
    if (variable is FieldElementImpl) {
      return variable.isCovariant;
    }
    return false;
  }

  @override
  Element get nonSynthetic {
    return setter.variable;
  }

  @override
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  @override
  set type(DartType type) {
    assert(false); // Should never be called.
  }

  @override
  DartType get typeInternal => setter.variable.type;
}

/// A mixin that provides a common implementation for methods defined in
/// [ParameterElement].
mixin ParameterElementMixin implements ParameterElement {
  @override
  bool get isNamed => parameterKind.isNamed;

  @override
  bool get isNotOptional => parameterKind.isRequired;

  @override
  bool get isOptional => parameterKind.isOptional;

  @override
  bool get isOptionalNamed => parameterKind.isOptionalNamed;

  @override
  bool get isOptionalPositional => parameterKind.isOptionalPositional;

  @override
  bool get isPositional => parameterKind.isPositional;

  @override
  bool get isRequiredNamed => parameterKind.isRequiredNamed;

  @override
  bool get isRequiredPositional => parameterKind.isRequiredPositional;

  @override
  // Overridden to remove the 'deprecated' annotation.
  ParameterKind get parameterKind;

  @override
  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    bool withNullability = false,
  }) {
    buffer.write(
      type.getDisplayString(
        withNullability: withNullability,
      ),
    );
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }
}

/// A concrete implementation of a [PrefixElement].
class PrefixElementImpl extends _ExistingElementImpl implements PrefixElement {
  /// The scope of this prefix, `null` if it has not been created yet.
  PrefixScope? _scope;

  /// Initialize a newly created method element to have the given [name] and
  /// [nameOffset].
  PrefixElementImpl(String name, int nameOffset, {Reference? reference})
      : super(name, nameOffset, reference: reference);

  @override
  String get displayName => name;

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  String get name {
    return super.name!;
  }

  @override
  Scope get scope => _scope ??= PrefixScope(enclosingElement, this);

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitPrefixElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePrefixElement(this);
  }
}

/// A concrete implementation of a [PropertyAccessorElement].
class PropertyAccessorElementImpl extends ExecutableElementImpl
    implements PropertyAccessorElement {
  /// The variable associated with this accessor.
  @override
  late PropertyInducingElement variable;

  /// If this method is a synthetic element which is based on another method
  /// with some modifications (such as making some parameters covariant),
  /// this field contains the base method.
  PropertyAccessorElement? prototype;

  /// Initialize a newly created property accessor element to have the given
  /// [name] and [offset].
  PropertyAccessorElementImpl(String name, int offset) : super(name, offset);

  /// Initialize a newly created synthetic property accessor element to be
  /// associated with the given [variable].
  PropertyAccessorElementImpl.forVariable(PropertyInducingElementImpl variable,
      {Reference? reference})
      : super(variable.name, -1, reference: reference) {
    this.variable = variable;
    isAbstract = variable is FieldElementImpl && variable.isAbstract;
    isStatic = variable.isStatic;
    isSynthetic = true;
  }

  @override
  PropertyAccessorElement? get correspondingGetter {
    if (isGetter) {
      return null;
    }
    return variable.getter;
  }

  @override
  PropertyAccessorElement? get correspondingSetter {
    if (isSetter) {
      return null;
    }
    return variable.setter;
  }

  @override
  PropertyAccessorElement get declaration => prototype ?? this;

  @override
  String get identifier {
    String name = displayName;
    String suffix = isGetter ? "?" : "=";
    return "$name$suffix";
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isGetter {
    return hasModifier(Modifier.GETTER);
  }

  /// Set whether this accessor is a getter.
  set isGetter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  @override
  bool get isSetter {
    return hasModifier(Modifier.SETTER);
  }

  /// Set whether this accessor is a setter.
  set isSetter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  @override
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  /// Set whether this accessor is static.
  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    if (isSetter) {
      return "${super.name}=";
    }
    return super.name;
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
}

/// Implicit getter for a [PropertyInducingElementImpl].
class PropertyAccessorElementImpl_ImplicitGetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit getter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitGetter(
      PropertyInducingElementImpl property,
      {Reference? reference})
      : super.forVariable(property, reference: reference) {
    property.getter = this;
    reference?.element = this;
  }

  @override
  Element get enclosingElement => variable.enclosingElement!;

  @override
  bool get hasImplicitReturnType => variable.hasImplicitType;

  @override
  bool get isGetter => true;

  @override
  Element get nonSynthetic {
    if (enclosingElement is EnumElementImpl) {
      if (name == 'index' || name == 'values') {
        return enclosingElement;
      }
    }
    return variable;
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  DartType get returnTypeInternal => variable.type;

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get typeInternal {
    return _type ??= FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: const <ParameterElement>[],
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }
}

/// Implicit setter for a [PropertyInducingElementImpl].
class PropertyAccessorElementImpl_ImplicitSetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit setter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitSetter(
      PropertyInducingElementImpl property,
      {Reference? reference})
      : super.forVariable(property, reference: reference) {
    property.setter = this;
  }

  @override
  Element get enclosingElement => variable.enclosingElement!;

  @override
  bool get isSetter => true;

  @override
  Element get nonSynthetic => variable;

  @override
  List<ParameterElement> get parameters =>
      ElementTypeProvider.current.getExecutableParameters(this);

  @override
  List<ParameterElement> get parametersInternal {
    if (_parameters.isNotEmpty) {
      return _parameters;
    }

    return _parameters = <ParameterElement>[
      ParameterElementImpl_ofImplicitSetter(this)
    ];
  }

  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  DartType get returnTypeInternal => VoidTypeImpl.instance;

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get typeInternal {
    return _type ??= FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }
}

/// A concrete implementation of a [PropertyInducingElement].
abstract class PropertyInducingElementImpl
    extends NonParameterVariableElementImpl implements PropertyInducingElement {
  /// The getter associated with this element.
  @override
  PropertyAccessorElement? getter;

  /// The setter associated with this element, or `null` if the element is
  /// effectively `final` and therefore does not have a setter associated with
  /// it.
  @override
  PropertyAccessorElement? setter;

  /// This field is set during linking, and performs type inference for
  /// this property. After linking this field is always `null`.
  PropertyInducingElementTypeInference? typeInference;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  ElementLinkedData? linkedData;

  /// Initialize a newly created synthetic element to have the given [name] and
  /// [offset].
  PropertyInducingElementImpl(String name, int offset) : super(name, offset);

  bool get hasTypeInferred => hasModifier(Modifier.HAS_TYPE_INFERRED);

  set hasTypeInferred(bool value) {
    setModifier(Modifier.HAS_TYPE_INFERRED, value);
  }

  @override
  bool get isConstantEvaluated => true;

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      if (enclosingElement is EnumElementImpl) {
        if (name == 'index' || name == 'values') {
          return enclosingElement;
        }
      }
      return (getter ?? setter)!;
    } else {
      return this;
    }
  }

  @override
  DartType get type => ElementTypeProvider.current.getFieldType(this);

  @override
  set type(DartType type) {
    super.type = type;
    // Reset cached types of synthetic getters and setters.
    // TODO(scheglov) Consider not caching these types.
    if (!isSynthetic) {
      var getter = this.getter;
      if (getter is PropertyAccessorElementImpl_ImplicitGetter) {
        getter._type = null;
      }
      var setter = this.setter;
      if (setter is PropertyAccessorElementImpl_ImplicitSetter) {
        setter._type = null;
      }
    }
  }

  @override
  DartType get typeInternal {
    linkedData?.read(this);
    if (_type != null) return _type!;

    if (isSynthetic && _type == null) {
      if (getter != null) {
        _type = getter!.returnType;
      } else if (setter != null) {
        List<ParameterElement> parameters = setter!.parameters;
        _type = parameters.isNotEmpty
            ? parameters[0].type
            : DynamicTypeImpl.instance;
      } else {
        _type = DynamicTypeImpl.instance;
      }
    }
    return super.typeInternal;
  }

  /// Return `true` if this variable needs the setter.
  bool get _hasSetter {
    if (isConst) {
      return false;
    }

    if (isLate) {
      return !isFinal || !hasInitializer;
    }

    return !isFinal;
  }

  void createImplicitAccessors(Reference enclosingRef, String name) {
    getter = PropertyAccessorElementImpl_ImplicitGetter(
      this,
      reference: enclosingRef.getChild('@getter').getChild(name),
    );

    if (_hasSetter) {
      setter = PropertyAccessorElementImpl_ImplicitSetter(
        this,
        reference: enclosingRef.getChild('@setter').getChild(name),
      );
    }
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

/// Instances of this class are set for fields and top-level variables
/// to perform top-level type inference during linking.
abstract class PropertyInducingElementTypeInference {
  void perform();
}

/// A concrete implementation of a [ShowElementCombinator].
class ShowElementCombinatorImpl implements ShowElementCombinator {
  @override
  List<String> shownNames = const [];

  @override
  int offset = 0;

  @override
  int end = -1;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("show ");
    int count = shownNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(shownNames[i]);
    }
    return buffer.toString();
  }
}

/// A concrete implementation of a [TopLevelVariableElement].
class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    implements TopLevelVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  TopLevelVariableElementImpl(String name, int offset) : super(name, offset);

  @override
  TopLevelVariableElement get declaration => this;

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTopLevelVariableElement(this);
}

/// An element that represents [GenericTypeAlias].
///
/// Clients may not extend, implement or mix-in this class.
class TypeAliasElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements TypeAliasElement {
  /// TODO(scheglov) implement as modifier
  @override
  bool isSimplyBounded = true;

  /// Is `true` if the element has direct or indirect reference to itself
  /// from anywhere except a class element or type parameter bounds.
  bool hasSelfReference = false;

  bool isFunctionTypeAliasBased = false;

  ElementLinkedData? linkedData;

  ElementImpl? _aliasedElement;
  DartType? _aliasedType;

  TypeAliasElementImpl(String name, int nameOffset) : super(name, nameOffset);

  @override
  ElementImpl? get aliasedElement {
    linkedData?.read(this);
    return _aliasedElement;
  }

  set aliasedElement(ElementImpl? aliasedElement) {
    _aliasedElement = aliasedElement;
    aliasedElement?.enclosingElement = this;
  }

  @override
  DartType get aliasedType {
    linkedData?.read(this);
    return _aliasedType!;
  }

  set aliasedType(DartType rawType) {
    _aliasedType = rawType;
  }

  @override
  String get displayName => name;

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  /// Returns whether this alias is a "proper rename" of [aliasedClass], as
  /// defined in the constructor-tearoffs specification.
  bool get isProperRename {
    var aliasedType_ = aliasedType;
    if (aliasedType_ is! InterfaceType) {
      return false;
    }
    var aliasedClass = aliasedType_.element;
    var typeArguments = aliasedType_.typeArguments;
    var typeParameterCount = typeParameters.length;
    if (typeParameterCount != aliasedClass.typeParameters.length) {
      return false;
    }
    for (var i = 0; i < typeParameterCount; i++) {
      var bound = typeParameters[i].bound ?? library.typeProvider.dynamicType;
      var aliasedBound = aliasedClass.typeParameters[i].bound ??
          library.typeProvider.dynamicType;
      if (!library.typeSystem.isSubtypeOf(bound, aliasedBound) ||
          !library.typeSystem.isSubtypeOf(aliasedBound, bound)) {
        return false;
      }
      if (typeParameters[i] != typeArguments[i].element) {
        return false;
      }
    }
    return true;
  }

  @override
  ElementKind get kind {
    if (isNonFunctionTypeAliasesEnabled) {
      return ElementKind.TYPE_ALIAS;
    } else {
      return ElementKind.FUNCTION_TYPE_ALIAS;
    }
  }

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    return super.name!;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return super.typeParameters;
  }

  /// Set the type parameters defined for this type to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTypeAliasElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeAliasElement(this);
  }

  @override
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    if (hasSelfReference) {
      if (isNonFunctionTypeAliasesEnabled) {
        return DynamicTypeImpl.instance;
      } else {
        return _errorFunctionType(nullabilitySuffix);
      }
    }

    var substitution = Substitution.fromPairs(typeParameters, typeArguments);
    var type = substitution.substituteType(aliasedType);

    var resultNullability = type.nullabilitySuffix == NullabilitySuffix.question
        ? NullabilitySuffix.question
        : nullabilitySuffix;

    if (type is FunctionType) {
      return FunctionTypeImpl(
        typeFormals: type.typeFormals,
        parameters: type.parameters,
        returnType: type.returnType,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is InterfaceType) {
      return InterfaceTypeImpl(
        element: type.element,
        typeArguments: type.typeArguments,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is TypeParameterType) {
      return TypeParameterTypeImpl(
        element: type.element,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else {
      return (type as TypeImpl).withNullability(resultNullability);
    }
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  FunctionTypeImpl _errorFunctionType(NullabilitySuffix nullabilitySuffix) {
    return FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// A concrete implementation of a [TypeParameterElement].
class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement {
  /// The default value of the type parameter. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference.
  DartType? defaultType;

  /// The type representing the bound associated with this parameter, or `null`
  /// if this parameter does not have an explicit bound.
  DartType? _bound;

  /// The value representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  Variance? _variance;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  TypeParameterElementImpl(String name, int offset) : super(name, offset);

  /// Initialize a newly created synthetic type parameter element to have the
  /// given [name], and with [synthetic] set to true.
  TypeParameterElementImpl.synthetic(String name) : super(name, -1) {
    isSynthetic = true;
  }

  @override
  DartType? get bound =>
      ElementTypeProvider.current.getTypeParameterBound(this);

  set bound(DartType? bound) {
    _bound = bound;
  }

  DartType? get boundInternal {
    return _bound;
  }

  @override
  TypeParameterElement get declaration => this;

  @override
  String get displayName => name;

  bool get isLegacyCovariant {
    return _variance == null;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  String get name {
    return super.name!;
  }

  Variance get variance {
    return _variance ?? Variance.covariant;
  }

  set variance(Variance? newVariance) => _variance = newVariance;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is TypeParameterElement) {
      if (other.enclosingElement == null || enclosingElement == null) {
        return identical(other, this);
      }
      return other.location == location;
    }
    return false;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTypeParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeParameter(this);
  }

  @override
  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return TypeParameterTypeImpl(
      element: this,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// Mixin representing an element which can have type parameters.
mixin TypeParameterizedElementMixin
    implements _ExistingElementImpl, TypeParameterizedElement {
  /// The type parameters declared by this element directly. This does not
  /// include type parameters that are declared by any enclosing elements.
  List<TypeParameterElement> _typeParameterElements = const [];

  @override
  bool get isSimplyBounded => true;

  @override
  List<TypeParameterElement> get typeParameters {
    return _typeParameterElements;
  }

  List<TypeParameterElement> get typeParameters_unresolved {
    return _typeParameterElements;
  }
}

/// A concrete implementation of a [UriReferencedElement].
abstract class UriReferencedElementImpl extends _ExistingElementImpl
    implements UriReferencedElement {
  /// The offset of the URI in the file, or `-1` if this node is synthetic.
  int _uriOffset = -1;

  /// The offset of the character immediately following the last character of
  /// this node's URI, or `-1` if this node is synthetic.
  int _uriEnd = -1;

  /// The URI that is specified by this directive.
  String? _uri;

  /// Initialize a newly created import element to have the given [name] and
  /// [offset]. The offset may be `-1` if the element is synthetic.
  UriReferencedElementImpl(String? name, int offset) : super(name, offset);

  /// Return the URI that is specified by this directive.
  @override
  String? get uri => _uri;

  /// Set the URI that is specified by this directive to be the given [uri].
  set uri(String? uri) {
    _uri = uri;
  }

  /// Return the offset of the character immediately following the last
  /// character of this node's URI, or `-1` if this node is synthetic.
  @override
  int get uriEnd => _uriEnd;

  /// Set the offset of the character immediately following the last character
  /// of this node's URI to the given [offset].
  set uriEnd(int offset) {
    _uriEnd = offset;
  }

  /// Return the offset of the URI in the file, or `-1` if this node is
  /// synthetic.
  @override
  int get uriOffset => _uriOffset;

  /// Set the offset of the URI in the file to the given [offset].
  set uriOffset(int offset) {
    _uriOffset = offset;
  }
}

/// A concrete implementation of a [VariableElement].
abstract class VariableElementImpl extends ElementImpl
    implements VariableElement {
  /// The type of this variable.
  DartType? _type;

  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  VariableElementImpl(String? name, int offset) : super(name, offset);

  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression? get constantInitializer => null;

  @override
  VariableElement get declaration => this;

  @override
  String get displayName => name;

  /// Return the result of evaluating this variable's initializer as a
  /// compile-time constant expression, or `null` if this variable is not a
  /// 'const' variable, if it does not have an initializer, or if the
  /// compilation unit containing the variable has not been resolved.
  EvaluationResultImpl? get evaluationResult => null;

  /// Set the result of evaluating this variable's initializer as a compile-time
  /// constant expression to the given [result].
  set evaluationResult(EvaluationResultImpl? result) {
    throw StateError("Invalid attempt to set a compile-time constant result");
  }

  @override
  bool get hasImplicitType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this variable element has an implicit type.
  set hasImplicitType(bool hasImplicitType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitType);
  }

  /// Set whether this variable is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this variable is const.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isConstantEvaluated => true;

  /// Set whether this variable is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  /// Set whether this variable is final.
  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  /// Set whether this variable is late.
  set isLate(bool isLate) {
    setModifier(Modifier.LATE, isLate);
  }

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  @override
  String get name => super.name!;

  @override
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  set type(DartType type) {
    _type = type;
  }

  /// Gets the element's type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `returnType` getter should be used instead.
  DartType get typeInternal => _type!;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() => null;
}

abstract class _ExistingElementImpl extends ElementImpl with _HasLibraryMixin {
  _ExistingElementImpl(String? name, int offset, {Reference? reference})
      : super(name, offset, reference: reference);
}

mixin _HasLibraryMixin on ElementImpl {
  @override
  LibraryElementImpl get library => thisOrAncestorOfType()!;

  @override
  Source get librarySource => library.source;

  @override
  Source get source => enclosingElement!.source!;
}

/// Instances of [List]s that are used as "not yet computed" values, they
/// must be not `null`, and not identical to `const <T>[]`.
class _Sentinel {
  static final List<ConstructorElement> constructorElement =
      List.unmodifiable([]);
  static final List<ExportElement> exportElement = List.unmodifiable([]);
  static final List<FieldElement> fieldElement = List.unmodifiable([]);
  static final List<ImportElement> importElement = List.unmodifiable([]);
  static final List<MethodElement> methodElement = List.unmodifiable([]);
  static final List<PropertyAccessorElement> propertyAccessorElement =
      List.unmodifiable([]);
}
