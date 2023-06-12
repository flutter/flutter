// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations that developers can use to express the intentions that otherwise
/// can't be deduced by statically analyzing the source code.
///
/// See also `@deprecated` and `@override` in the `dart:core` library.
///
/// Annotations provide semantic information that tools can use to provide a
/// better user experience. For example, an IDE might not autocomplete the name
/// of a function that's been marked `@deprecated`, or it might display the
/// function's name differently.
///
/// For information on installing and importing this library, see the [meta
/// package on pub.dev](https://pub.dev/packages/meta). For examples of using
/// annotations, see
/// [Metadata](https://dart.dev/guides/language/language-tour#metadata) in the
/// language tour.
library meta;

import 'meta_meta.dart';

/// Used to annotate a function `f`. Indicates that `f` always throws an
/// exception. Any functions that override `f`, in class inheritance, are also
/// expected to conform to this contract.
///
/// Tools, such as the analyzer, can use this to understand whether a block of
/// code "exits". For example:
///
/// ```dart
/// @alwaysThrows toss() { throw 'Thrown'; }
///
/// int fn(bool b) {
///   if (b) {
///     return 0;
///   } else {
///     toss();
///     print("Hello.");
///   }
/// }
/// ```
///
/// Without the annotation on `toss`, it would look as though `fn` doesn't
/// always return a value. The annotation shows that `fn` does always exit. In
/// addition, the annotation reveals that any statements following a call to
/// `toss` (like the `print` call) are dead code.
///
/// Tools, such as the analyzer, can also expect this contract to be enforced;
/// that is, tools may emit warnings if a function with this annotation
/// _doesn't_ always throw.
const _AlwaysThrows alwaysThrows = _AlwaysThrows();

/// Used to annotate a parameter of an instance method that overrides another
/// method.
///
/// Indicates that this parameter may have a tighter type than the parameter on
/// its superclass. The actual argument will be checked at runtime to ensure it
/// is a subtype of the overridden parameter type.
///
@Deprecated('Use the `covariant` modifier instead')
const _Checked checked = _Checked();

/// Used to annotate a method, getter or top-level getter or function to
/// indicate that the value obtained by invoking it should not be stored in a
/// field or top-level variable. The annotation can also be applied to a class
/// to implicitly annotate all of the valid members of the class, or applied to
/// a library to annotate all of the valid members of the library, including
/// classes. If a value returned by an element marked as `doNotStore` is returned
/// from a function or getter, that function or getter should be similarly
/// annotated.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a library, class,
///   method or getter, top-level getter or function, or
/// * an invocation of a member that has this annotation is returned by a method,
///   getter or function that is not similarly annotated as `doNotStore`, or
/// * an invocation of a member that has this annotation is assigned to a field
///   or top-level variable.
const _DoNotStore doNotStore = _DoNotStore();

/// Used to annotate a library, or any declaration that is part of the public
/// interface of a library (such as top-level members, class members, and
/// function parameters) to indicate that the annotated API is experimental and
/// may be removed or changed at any-time without updating the version of the
/// containing package, despite the fact that it would otherwise be a breaking
/// change.
///
/// If the annotation is applied to a library then it is equivalent to applying
/// the annotation to all of the top-level members of the library. Applying the
/// annotation to a class does *not* apply the annotation to subclasses, but
/// does apply the annotation to members of the class.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration that is not part of the
///   public interface of a library (such as a local variable or a declaration
///   that is private) or a directive other than the first directive in the
///   library, or
/// * the declaration is referenced by a package that has not explicitly
///   indicated its intention to use experimental APIs (details TBD).
const _Experimental experimental = _Experimental();

/// Used to annotate an instance or static method `m`. Indicates that `m` must
/// either be abstract or must return a newly allocated object or `null`. In
/// addition, every method that either implements or overrides `m` is implicitly
/// annotated with this same annotation.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a method, or
/// * a method that has this annotation can return anything other than a newly
///   allocated object or `null`.
const _Factory factory = _Factory();

/// Used to annotate a class `C`. Indicates that `C` and all subtypes of `C`
/// must be immutable.
///
/// A class is immutable if all of the instance fields of the class, whether
/// defined directly or inherited, are `final`.
///
/// Tools, such as the analyzer, can provide feedback if
/// * the annotation is associated with anything other than a class, or
/// * a class that has this annotation or extends, implements or mixes in a
///   class that has this annotation is not immutable.
const Immutable immutable = Immutable();

/// Used to annotate a declaration which should only be used from within the
/// package in which it is declared, and which should not be exposed from said
/// package's public API.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the declaration is declared in a package's public API, or is exposed from
///   a package's public API, or
/// * the declaration is private, an unnamed extension, a static member of a
///   private class, mixin, or extension, a value of a private enum, or a
///   constructor of a private class, or
/// * the declaration is referenced outside the package in which it is declared.
const _Internal internal = _Internal();

/// Used to annotate a test framework function that runs a single test.
///
/// Tools, such as IDEs, can show invocations of such function in a file
/// structure view to help the user navigating in large test files.
///
/// The first parameter of the function must be the description of the test.
const _IsTest isTest = _IsTest();

/// Used to annotate a test framework function that runs a group of tests.
///
/// Tools, such as IDEs, can show invocations of such function in a file
/// structure view to help the user navigating in large test files.
///
/// The first parameter of the function must be the description of the group.
const _IsTestGroup isTestGroup = _IsTestGroup();

/// Used to annotate a const constructor `c`. Indicates that any invocation of
/// the constructor must use the keyword `const` unless one or more of the
/// arguments to the constructor is not a compile-time constant.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a const constructor,
///   or
/// * an invocation of a constructor that has this annotation is not invoked
///   using the `const` keyword unless one or more of the arguments to the
///   constructor is not a compile-time constant.
const _Literal literal = _Literal();

/// Used to annotate an instance method `m`. Indicates that every invocation of
/// a method that overrides `m` must also invoke `m`. In addition, every method
/// that overrides `m` is implicitly annotated with this same annotation.
///
/// Note that private methods with this annotation cannot be validly overridden
/// outside of the library that defines the annotated method.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance method,
///   or
/// * a method that overrides a method that has this annotation can return
///   without invoking the overridden method.
const _MustCallSuper mustCallSuper = _MustCallSuper();

/// Used to annotate an instance member (method, getter, setter, operator, or
/// field) `m` in a class `C` or mixin `M`. Indicates that `m` should not be
/// overridden in any classes that extend or mixin `C` or `M`.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
/// * the annotation is associated with an abstract member (because subclasses
///   are required to override the member),
/// * the annotation is associated with an extension method,
/// * the annotation is associated with a member `m` in class `C`, and there is
///   a class `D` or mixin `M`, that extends or mixes in `C`, that declares an
///   overriding member `m`.
const _NonVirtual nonVirtual = _NonVirtual();

/// Used to annotate a class, mixin, extension, function, method, or typedef
/// declaration `C`. Indicates that any type arguments declared on `C` are to
/// be treated as optional.
///
/// Tools such as the analyzer and linter can use this information to suppress
/// warnings that would otherwise require type arguments on `C` to be provided.
const _OptionalTypeArgs optionalTypeArgs = _OptionalTypeArgs();

/// Used to annotate an instance member in a class or mixin which is meant to
/// be visible only within the declaring library, and to other instance members
/// of the class or mixin, and their subtypes.
///
/// If the annotation is on a field it applies to the getter, and setter if
/// appropriate, that are induced by the field.
///
/// Indicates that the annotated instance member (method, getter, setter,
/// operator, or field) `m` in a class or mixin `C` should only be referenced
/// in specific locations. A reference from within the library in which `C` is
/// declared is valid. Additionally, a reference from within an instance member
/// in `C`, or a class that extends, implements, or mixes in `C` (either
/// directly or indirectly) or a mixin that uses `C` as a superclass constraint
/// is valid. Additionally a reference from within an instance member in an
/// extension that applies to `C` is valid.
///
/// Additionally restricts the instance of `C` on which `m` is referenced: a
/// reference to `m` should either be in the same library in which `C` is
/// declared, or should refer to `this.m` (explicitly or implicitly), and not
/// `m` on any other instance of `C`.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
///   or
/// * a reference to a member `m` which has this annotation, declared in a
///   class or mixin `C`, is found outside of the declaring library and outside
///   of an instance member in any class that extends, implements, or mixes in
///   `C` or any mixin that uses `C` as a superclass constraint, or
/// * a reference to a member `m` which has this annotation, declared in a
///   class or mixin `C`, is found outside of the declaring library and the
///   receiver is something other than `this`.
// TODO(srawlins): Add a sentence which defines "referencing" and explicitly
// mentions tearing off, here and on the other annotations which use the word
// "referenced."
const _Protected protected = _Protected();

/// Used to annotate a named parameter `p` in a method or function `f`.
/// Indicates that every invocation of `f` must include an argument
/// corresponding to `p`, despite the fact that `p` would otherwise be an
/// optional parameter.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a named parameter,
/// * the annotation is associated with a named parameter in a method `m1` that
///   overrides a method `m0` and `m0` defines a named parameter with the same
///   name that does not have this annotation, or
/// * an invocation of a method or function does not include an argument
///   corresponding to a named parameter that has this annotation.
const Required required = Required();

/// Annotation marking a class as not allowed as a super-type.
///
/// Classes in the same package as the marked class may extend, implement or
/// mix-in the annotated class.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a class,
/// * the annotation is associated with a class `C`, and there is a class or
///   mixin `D`, which extends, implements, mixes in, or constrains to `C`, and
///   `C` and `D` are declared in different packages.
const _Sealed sealed = _Sealed();

/// Used to annotate a method, field, or getter within a class, mixin, or
/// extension, or a or top-level getter, variable or function to indicate that
/// the value obtained by invoking it should be used. A value is considered used
/// if it is assigned to a variable, passed to a function, or used as the target
/// of an invocation, or invoked (if the result is itself a function).
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a method, field or
///   getter, top-level variable, getter or function or
/// * the value obtained by a method, field, getter or top-level getter,
///   variable or function annotated with `@useResult` is not used.
const UseResult useResult = UseResult();

/// Used to annotate a field that is allowed to be overridden in Strong Mode.
///
/// Deprecated: Most of strong mode is now the default in 2.0, but the notion of
/// virtual fields was dropped, so this annotation no longer has any meaning.
/// Uses of the annotation should be removed.
@Deprecated('No longer has meaning')
const _Virtual virtual = _Virtual();

/// Used to annotate an instance member that was made public so that it could be
/// overridden but that is not intended to be referenced from outside the
/// defining library.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration other than a public
///   instance member in a class or mixin, or
/// * the member is referenced outside of the defining library.
const _VisibleForOverriding visibleForOverriding = _VisibleForOverriding();

/// Used to annotate a declaration that was made public, so that it is more
/// visible than otherwise necessary, to make code testable.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration not in the `lib` folder
///   of a package, or a private declaration, or a declaration in an unnamed
///   static extension, or
/// * the declaration is referenced outside of its defining library or a
///   library which is in the `test` folder of the defining package.
const _VisibleForTesting visibleForTesting = _VisibleForTesting();

/// Used to annotate a class.
///
/// See [immutable] for more details.
class Immutable {
  /// A human-readable explanation of the reason why the class is immutable.
  final String reason;

  /// Initialize a newly created instance to have the given [reason].
  const Immutable([this.reason = '']);
}

/// Used to annotate a named parameter `p` in a method or function `f`.
///
/// See [required] for more details.
class Required {
  /// A human-readable explanation of the reason why the annotated parameter is
  /// required. For example, the annotation might look like:
  ///
  ///     ButtonWidget({
  ///         Function onHover,
  ///         @Required('Buttons must do something when pressed')
  ///         Function onPressed,
  ///         ...
  ///     }) ...
  final String reason;

  /// Initialize a newly created instance to have the given [reason].
  const Required([this.reason = '']);
}

/// See [useResult] for more details.
@Target({
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.topLevelVariable,
})
class UseResult {
  /// A human-readable explanation of the reason why the value returned by
  /// accessing this member should be used.
  final String reason;

  /// Names a parameter of a method or function that, when present, signals that
  /// the annotated member's value is used by that method or function and does
  /// not need to be further checked.
  final String? parameterDefined;

  /// Initialize a newly created instance to have the given [reason].
  const UseResult([this.reason = '']) : parameterDefined = null;

  /// Initialize a newly created instance to annotate a function or method that
  /// identifies a parameter [parameterDefined] that when present signals that
  /// the result is used by the annotated member and does not need to be further
  /// checked.  For values that need to be used unconditionally, use the unnamed
  /// `UseResult` constructor, or if no reason is specified, the [useResult]
  /// constant.
  ///
  /// Tools, such as the analyzer, can provide feedback if
  ///
  /// * a parameter named by [parameterDefined] is not declared by the annotated
  ///   method or function.
  const UseResult.unless({required this.parameterDefined, this.reason = ''});
}

class _AlwaysThrows {
  const _AlwaysThrows();
}

class _Checked {
  const _Checked();
}

@Target({
  TargetKind.classType,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.library,
  TargetKind.method,
})
class _DoNotStore {
  const _DoNotStore();
}

class _Experimental {
  const _Experimental();
}

class _Factory {
  const _Factory();
}

class _Internal {
  const _Internal();
}

class _IsTest {
  const _IsTest();
}

class _IsTestGroup {
  const _IsTestGroup();
}

class _Literal {
  const _Literal();
}

class _MustCallSuper {
  const _MustCallSuper();
}

class _NonVirtual {
  const _NonVirtual();
}

@Target({
  TargetKind.classType,
  TargetKind.extension,
  TargetKind.function,
  TargetKind.method,
  TargetKind.mixinType,
  TargetKind.typedefType,
})
class _OptionalTypeArgs {
  const _OptionalTypeArgs();
}

class _Protected {
  const _Protected();
}

class _Sealed {
  const _Sealed();
}

@Deprecated('No longer has meaning')
class _Virtual {
  const _Virtual();
}

class _VisibleForOverriding {
  const _VisibleForOverriding();
}

class _VisibleForTesting {
  const _VisibleForTesting();
}
