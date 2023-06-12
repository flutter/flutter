// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the type model. The type model is part of the
/// [element model](../dart_element_element/dart_element_element-library.html)
/// in that most types are defined by Dart code (the types `dynamic` and `void`
/// being the notable exceptions). All types are represented by an instance of a
/// subclass of [DartType].
///
/// Other than `dynamic` and `void`, all of the types define either the
/// interface defined by a class (an instance of [InterfaceType]) or the type of
/// a function (an instance of [FunctionType]).
///
/// We make a distinction between the declaration of a class (a [ClassElement])
/// and the type defined by that class (an [InterfaceType]). The biggest reason
/// for the distinction is to allow us to more cleanly represent the distinction
/// between type parameters and type arguments. For example, if we define a
/// class as `class Pair<K, V> {}`, the declarations of `K` and `V` represent
/// type parameters. But if we declare a variable as `Pair<String, int> pair;`
/// the references to `String` and `int` are type arguments.
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart' show InterfaceTypeImpl;

/// The type associated with elements in the element model.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartType {
  /// If this type is an instantiation of a type alias, information about
  /// the alias element, and the type arguments.
  /// Otherwise return `null`.
  InstantiatedTypeAliasElement? get alias;

  /// If this type is an instantiation of a type alias, return the type
  /// arguments used for the instantiation. Otherwise return `null`.
  @Deprecated('Use alias instead')
  List<DartType>? get aliasArguments;

  /// If this type is an instantiation of a type alias, return it.
  /// Otherwise return `null`.
  @Deprecated('Use alias instead')
  TypeAliasElement? get aliasElement;

  /// Return the name of this type as it should appear when presented to users
  /// in contexts such as error messages.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  @Deprecated('Use getDisplayString instead')
  String get displayName;

  /// Return the element representing the declaration of this type, or `null` if
  /// the type has not, or cannot, be associated with an element. The former
  /// case will occur if the element model is not yet complete; the latter case
  /// will occur if this object represents an undefined type.
  Element? get element;

  /// Return `true` if this type represents the bottom type.
  bool get isBottom;

  /// Return `true` if this type represents the type 'Future' defined in the
  /// dart:async library.
  bool get isDartAsyncFuture;

  /// Return `true` if this type represents the type 'FutureOr<T>' defined in
  /// the dart:async library.
  bool get isDartAsyncFutureOr;

  /// Return `true` if this type represents the type 'bool' defined in the
  /// dart:core library.
  bool get isDartCoreBool;

  /// Return `true` if this type represents the type 'double' defined in the
  /// dart:core library.
  bool get isDartCoreDouble;

  /// Return `true` if this type represents the type 'Function' defined in the
  /// dart:core library.
  bool get isDartCoreFunction;

  /// Return `true` if this type represents the type 'int' defined in the
  /// dart:core library.
  bool get isDartCoreInt;

  /// Returns `true` if this type represents the type 'Iterable' defined in the
  /// dart:core library.
  bool get isDartCoreIterable;

  /// Returns `true` if this type represents the type 'List' defined in the
  /// dart:core library.
  bool get isDartCoreList;

  /// Returns `true` if this type represents the type 'Map' defined in the
  /// dart:core library.
  bool get isDartCoreMap;

  /// Return `true` if this type represents the type 'Null' defined in the
  /// dart:core library.
  bool get isDartCoreNull;

  /// Return `true` if this type represents the type 'num' defined in the
  /// dart:core library.
  bool get isDartCoreNum;

  /// Return `true` if this type represents the type `Object` defined in the
  /// dart:core library.
  bool get isDartCoreObject;

  /// Returns `true` if this type represents the type 'Set' defined in the
  /// dart:core library.
  bool get isDartCoreSet;

  /// Return `true` if this type represents the type 'String' defined in the
  /// dart:core library.
  bool get isDartCoreString;

  /// Returns `true` if this type represents the type 'Symbol' defined in the
  /// dart:core library.
  bool get isDartCoreSymbol;

  /// Return `true` if this type represents the type 'dynamic'.
  bool get isDynamic;

  /// Return `true` if this type represents the type 'void'.
  bool get isVoid;

  /// Return the name of this type, or `null` if the type does not have a name,
  /// such as when the type represents the type of an unnamed function.
  @Deprecated('Check element, or use getDisplayString()')
  String? get name;

  /// Return the nullability suffix of this type.
  NullabilitySuffix get nullabilitySuffix;

  /// Use the given [visitor] to visit this type.
  R accept<R>(TypeVisitor<R> visitor);

  /// Use the given [visitor] to visit this type.
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  );

  /// Return the canonical interface that this type implements for [element],
  /// or `null` if such an interface does not exist.
  ///
  /// For example, given the following definitions
  /// ```
  /// class A<E> {}
  /// class B<E> implements A<E> {}
  /// class C implements A<String> {}
  /// ```
  /// Asking the type `B<int>` for the type associated with `A` will return the
  /// type `A<int>`. Asking the type `C` for the type associated with `A` will
  /// return the type `A<String>`.
  ///
  /// For a [TypeParameterType] with a bound (declared or promoted), returns
  /// the interface implemented by the bound.
  InterfaceType? asInstanceOf(ClassElement element);

  /// Return the presentation of this type as it should appear when presented
  /// to users in contexts such as error messages.
  ///
  /// If [withNullability] is `true`, then [NullabilitySuffix.question] and
  /// [NullabilitySuffix.star] will be represented as `?` and `*`.
  /// [NullabilitySuffix.none] does not have any explicit presentation.
  ///
  /// If [withNullability] is `false`, nullability suffixes will not be
  /// included into the presentation.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString({required bool withNullability});

  /// If this type is a [TypeParameterType], returns its bound if it has one, or
  /// [objectType] otherwise.
  ///
  /// For any other type, returns `this`. Applies recursively -- if the bound is
  /// itself a type parameter, that is resolved too.
  DartType resolveToBound(DartType objectType);
}

/// The type `dynamic` is a type which is a supertype of all other types, just
/// like `Object`, with the difference that the static analysis assumes that
/// every member access has a corresponding member with a signature that
/// admits the given access.
abstract class DynamicType implements DartType {}

/// The type of a function, method, constructor, getter, or setter. Function
/// types come in three variations:
///
/// * The types of functions that only have required parameters. These have the
///   general form <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i>.
/// * The types of functions with optional positional parameters. These have the
///   general form <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>
///   &hellip;, T<sub>n+k</sub>]) &rarr; T</i>.
/// * The types of functions with named parameters. These have the general form
///   <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>x1</sub> x1, &hellip;,
///   T<sub>xk</sub> xk}) &rarr; T</i>.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionType implements DartType {
  /// Return a map from the names of named parameters to the types of the named
  /// parameters of this type of function. The entries in the map will be
  /// iterated in the same order as the order in which the named parameters were
  /// defined. If there were no named parameters declared then the map will be
  /// empty.
  Map<String, DartType> get namedParameterTypes;

  /// The names of the required positional parameters of this type of function,
  /// in the order that the parameters appear.
  List<String> get normalParameterNames;

  /// Return a list containing the types of the normal parameters of this type
  /// of function. The parameter types are in the same order as they appear in
  /// the declaration of the function.
  List<DartType> get normalParameterTypes;

  /// The names of the optional positional parameters of this type of function,
  /// in the order that the parameters appear.
  List<String> get optionalParameterNames;

  /// Return a map from the names of optional (positional) parameters to the
  /// types of the optional parameters of this type of function. The entries in
  /// the map will be iterated in the same order as the order in which the
  /// optional parameters were defined. If there were no optional parameters
  /// declared then the map will be empty.
  List<DartType> get optionalParameterTypes;

  /// Return a list containing the parameters elements of this type of function.
  /// The parameter types are in the same order as they appear in the
  /// declaration of the function.
  List<ParameterElement> get parameters;

  /// Return the type of object returned by this type of function.
  DartType get returnType;

  /// The formal type parameters of this generic function.
  /// For example `<T> T -> T`.
  ///
  /// TODO(scheglov) Remove the mention for "typeParameters".
  /// These are distinct from the `typeParameters` list, which contains type
  /// parameters from surrounding contexts, and thus are free type variables
  /// from the perspective of this function type.
  List<TypeParameterElement> get typeFormals;

  /// Produces a new function type by substituting type parameters of this
  /// function type with the given [argumentTypes]. The resulting function
  /// type will have no type parameters.
  FunctionType instantiate(List<DartType> argumentTypes);
}

/// Information about an instantiated [TypeAliasElement] and the type
/// arguments with which it is instantiated.
abstract class InstantiatedTypeAliasElement {
  /// The alias element that is instantiated to produce a [DartType].
  TypeAliasElement get element;

  /// The type arguments with which the [element] was instantiated.
  /// This list will be empty if the [element] is not generic.
  List<DartType> get typeArguments;
}

/// The type introduced by either a class or an interface, or a reference to
/// such a type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterfaceType implements ParameterizedType {
  /// Return a list containing all of the accessors (getters and setters)
  /// declared in this type.
  List<PropertyAccessorElement> get accessors;

  /// Return all the super-interfaces implemented by this interface. This
  /// includes superclasses, mixins, interfaces, and superclass constraints.
  List<InterfaceType> get allSupertypes;

  /// Return a list containing all of the constructors declared in this type.
  List<ConstructorElement> get constructors;

  @override
  ClassElement get element;

  /// Return a list containing all of the interfaces that are implemented by
  /// this interface. Note that this is <b>not</b>, in general, equivalent to
  /// getting the interfaces from this type's element because the types returned
  /// by this method will have had their type parameters replaced.
  List<InterfaceType> get interfaces;

  /// Return a list containing all of the methods declared in this type.
  List<MethodElement> get methods;

  /// Return a list containing all of the mixins that are applied to the class
  /// being extended in order to derive the superclass of this class. Note that
  /// this is <b>not</b>, in general, equivalent to getting the mixins from this
  /// type's element because the types returned by this method will have had
  /// their type parameters replaced.
  List<InterfaceType> get mixins;

  /// Return the type representing the superclass of this type, or null if this
  /// type represents the class 'Object'. Note that this is <b>not</b>, in
  /// general, equivalent to getting the superclass from this type's element
  /// because the type returned by this method will have had it's type
  /// parameters replaced.
  InterfaceType? get superclass;

  /// Return a list containing all of the super-class constraints that this
  /// mixin declaration declares. The list will be empty if this class does not
  /// represent a mixin declaration.
  List<InterfaceType> get superclassConstraints;

  /// Return the element representing the getter with the given [name] that is
  /// declared in this class, or `null` if this class does not declare a getter
  /// with the given name.
  PropertyAccessorElement? getGetter(String name);

  /// Return the element representing the method with the given [name] that is
  /// declared in this class, or `null` if this class does not declare a method
  /// with the given name.
  MethodElement? getMethod(String name);

  /// Return the element representing the setter with the given [name] that is
  /// declared in this class, or `null` if this class does not declare a setter
  /// with the given name.
  PropertyAccessorElement? getSetter(String name);

  /// Return the element representing the constructor that results from looking
  /// up the constructor with the given [name] in this class with respect to the
  /// given [library], or `null` if the look up fails. The behavior of this
  /// method is defined by the Dart Language Specification in section 12.11.1:
  /// <blockquote>
  /// If <i>e</i> is of the form <b>new</b> <i>T.id()</i> then let <i>q<i> be
  /// the constructor <i>T.id</i>, otherwise let <i>q<i> be the constructor
  /// <i>T<i>. Otherwise, if <i>q</i> is not defined or not accessible, a
  /// NoSuchMethodException is thrown.
  /// </blockquote>
  ConstructorElement? lookUpConstructor(String? name, LibraryElement library);

  /// Return the element representing the getter that results from looking up
  /// the getter with the given [name] in this class with respect to the given
  /// [library], or `null` if the look up fails. The behavior of this method is
  /// defined by the Dart Language Specification in section 12.15.1:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is:
  /// * If <i>C</i> declares an instance getter (respectively setter) named
  ///   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
  ///   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
  ///   superclass <i>S</i>, then the result of the lookup is the result of
  ///   looking up getter (respectively setter) <i>m</i> in <i>S</i> with
  ///   respect to <i>L</i>. Otherwise, we say that the lookup has failed.
  /// </blockquote>
  @Deprecated('Use lookupGetter2 instead')
  PropertyAccessorElement? lookUpGetter(String name, LibraryElement library);

  /// Return the getter with the given [name].
  ///
  /// If [concrete] is `true`, then the concrete implementation is returned,
  /// from this type, or its superclass.
  ///
  /// If [inherited] is `true`, then only getters from the superclass are
  /// considered.
  ///
  /// If [recoveryStatic] is `true`, then static getters of the class,
  /// and its superclasses are considered. Clients should not use it.
  PropertyAccessorElement? lookUpGetter2(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  });

  /// Return the element representing the getter that results from looking up
  /// the getter with the given [name] in the superclass of this class with
  /// respect to the given [library], or `null` if the look up fails. The
  /// behavior of this method is defined by the Dart Language Specification in
  /// section 12.15.1:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is:
  /// * If <i>C</i> declares an instance getter (respectively setter) named
  ///   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
  ///   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
  ///   superclass <i>S</i>, then the result of the lookup is the result of
  ///   looking up getter (respectively setter) <i>m</i> in <i>S</i> with
  ///   respect to <i>L</i>. Otherwise, we say that the lookup has failed.
  /// </blockquote>
  @Deprecated('Use lookupGetter2 instead')
  PropertyAccessorElement? lookUpGetterInSuperclass(
      String name, LibraryElement? library);

  /// Look up the member with the given [name] in this type and all extended
  /// and mixed in classes, and by default including [thisType]. If the search
  /// fails, this will then search interfaces.
  ///
  /// Return the element representing the member that was found, or `null` if
  /// there is no getter with the given name.
  ///
  /// The [library] determines if a private member name is visible, and does not
  /// need to be supplied for public names.
  @Deprecated('Use lookupGetter2 instead')
  PropertyAccessorElement? lookUpInheritedGetter(String name,
      {LibraryElement? library, bool thisType = true});

  /// Look up the member with the given [name] in this type and all extended
  /// and mixed in classes, starting from this type. If the search fails,
  /// search interfaces.
  ///
  /// Return the element representing the member that was found, or `null` if
  /// there is no getter with the given name.
  ///
  /// The [library] determines if a private member name is visible, and does not
  /// need to be supplied for public names.
  @Deprecated('Use lookupGetter2 and/or lookupMethod2 instead')
  ExecutableElement? lookUpInheritedGetterOrMethod(String name,
      {LibraryElement? library});

  /// Look up the member with the given [name] in this type and all extended
  /// and mixed in classes, and by default including [thisType]. If the search
  /// fails, this will then search interfaces.
  ///
  /// Return the element representing the member that was found, or `null` if
  /// there is no getter with the given name.
  ///
  /// The [library] determines if a private member name is visible, and does not
  /// need to be supplied for public names.
  @Deprecated('Use lookupMethod2 instead')
  MethodElement? lookUpInheritedMethod(String name,
      {LibraryElement? library, bool thisType = true});

  /// Look up the member with the given [name] in this type and all extended
  /// and mixed in classes, and by default including [thisType]. If the search
  /// fails, this will then search interfaces.
  ///
  /// Return the element representing the member that was found, or `null` if
  /// there is no getter with the given name.
  ///
  /// The [library] determines if a private member name is visible, and does not
  /// need to be supplied for public names.
  @Deprecated('Use lookupSetter2 instead')
  PropertyAccessorElement? lookUpInheritedSetter(String name,
      {LibraryElement? library, bool thisType = true});

  /// Return the element representing the method that results from looking up
  /// the method with the given [name] in this class with respect to the given
  /// [library], or `null` if the look up fails. The behavior of this method is
  /// defined by the Dart Language Specification in section 12.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:
  /// * If <i>C</i> declares an instance method named <i>m</i> that is
  ///   accessible to <i>L</i>, then that method is the result of the lookup.
  ///   Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the
  ///   lookup is the result of looking up method <i>m</i> in <i>S</i> with
  ///   respect to <i>L</i> Otherwise, we say that the lookup has failed.
  /// </blockquote>
  @Deprecated('Use lookupMethod2 instead')
  MethodElement? lookUpMethod(String name, LibraryElement library);

  /// Return the method with the given [name].
  ///
  /// If [concrete] is `true`, then the concrete implementation is returned,
  /// from this type, or its superclass.
  ///
  /// If [inherited] is `true`, then only methods from the superclass are
  /// considered.
  ///
  /// If [recoveryStatic] is `true`, then static methods of the class,
  /// and its superclasses are considered. Clients should not use it.
  MethodElement? lookUpMethod2(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  });

  /// Return the element representing the method that results from looking up
  /// the method with the given [name] in the superclass of this class with
  /// respect to the given [library], or `null` if the look up fails. The
  /// behavior of this method is defined by the Dart Language Specification in
  /// section 12.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:
  /// * If <i>C</i> declares an instance method named <i>m</i> that is
  ///   accessible to <i>L</i>, then that method is the result of the lookup.
  ///   Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the
  /// * lookup is the result of looking up method <i>m</i> in <i>S</i> with
  ///   respect to <i>L</i>.
  /// * Otherwise, we say that the lookup has failed.
  /// </blockquote>
  @Deprecated('Use lookupMethod2 instead')
  MethodElement? lookUpMethodInSuperclass(String name, LibraryElement library);

  /// Return the element representing the setter that results from looking up
  /// the setter with the given [name] in this class with respect to the given
  /// [library], or `null` if the look up fails. The behavior of this method is
  /// defined by the Dart Language Specification in section 12.16:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is:
  /// * If <i>C</i> declares an instance getter (respectively setter) named
  ///   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
  ///   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
  ///   superclass <i>S</i>, then the result of the lookup is the result of
  ///   looking up getter (respectively setter) <i>m</i> in <i>S</i> with
  ///   respect to <i>L</i>. Otherwise, we say that the lookup has failed.
  /// </blockquote>
  @Deprecated('Use lookupSetter2 instead')
  PropertyAccessorElement? lookUpSetter(String name, LibraryElement library);

  /// Return the setter with the given [name].
  ///
  /// If [concrete] is `true`, then the concrete implementation is returned,
  /// from this type, or its superclass.
  ///
  /// If [inherited] is `true`, then only setters from the superclass are
  /// considered.
  ///
  /// If [recoveryStatic] is `true`, then static setters of the class,
  /// and its superclasses are considered. Clients should not use it.
  PropertyAccessorElement? lookUpSetter2(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  });

  /// Return the element representing the setter that results from looking up
  /// the setter with the given [name] in the superclass of this class with
  /// respect to the given [library], or `null` if the look up fails. The
  /// behavior of this method is defined by the Dart Language Specification in
  /// section 12.16:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is:
  /// * If <i>C</i> declares an instance getter (respectively setter) named
  ///   <i>m</i> that is accessible to <i>L</i>, then that getter (respectively
  ///   setter) is the result of the lookup. Otherwise, if <i>C</i> has a
  ///   superclass <i>S</i>, then the result of the lookup is the result of
  ///   looking up getter (respectively setter) <i>m</i> in <i>S</i> with
  ///   respect to <i>L</i>. Otherwise, we say that the lookup has failed.
  /// </blockquote>
  @Deprecated('Use lookupSetter2 instead')
  PropertyAccessorElement? lookUpSetterInSuperclass(
      String name, LibraryElement library);

  /// Returns a "smart" version of the "least upper bound" of the given types.
  ///
  /// If these types have the same element and differ only in terms of the type
  /// arguments, attempts to find a compatible set of type arguments.
  ///
  /// Otherwise, returns the same result as [DartType.getLeastUpperBound].
  @Deprecated('Use TypeSystem.leastUpperBound instead')
  static InterfaceType getSmartLeastUpperBound(
          InterfaceType first, InterfaceType second) =>
      InterfaceTypeImpl.getSmartLeastUpperBound(first, second);
}

/// The type `Never` represents the uninhabited bottom type.
abstract class NeverType implements DartType {}

/// A type that can track substituted type parameters, either for itself after
/// instantiation, or from a surrounding context.
///
/// For example, given a class `Foo<T>`, after instantiation with S for T, it
/// will track the substitution `{S/T}`.
///
/// This substitution will be propagated to its members. For example, say our
/// `Foo<T>` class has a field `T bar;`. When we look up this field, we will get
/// back a [FieldElement] that tracks the substituted type as `{S/T}T`, so when
/// we ask for the field type we will get `S`.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParameterizedType implements DartType {
  /// Return the type arguments used to instantiate this type.
  ///
  /// An [InterfaceType] always has type arguments.
  ///
  /// A [FunctionType] has type arguments only if it is a result of a typedef
  /// instantiation, otherwise the result is `null`.
  List<DartType> get typeArguments;
}

/// The type introduced by a type parameter.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterType implements DartType {
  /// Return the type representing the bound associated with this parameter,
  /// or `dynamic` if there was no explicit bound.
  DartType get bound;

  /// An object that can be used to identify this type parameter with `==`.
  ///
  /// Depending on the use, [bound] may also need to be taken into account.
  /// A given type parameter, it may have different bounds in different scopes.
  /// Always consult the bound if that could be relevant.
  ElementLocation get definition;

  @override
  TypeParameterElement get element;
}

/// The special type `void` is used to indicate that the value of an
/// expression is meaningless, and intended to be discarded.
abstract class VoidType implements DartType {}
