// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

/// The annotation `@Deprecated('migration')` marks a feature as deprecated.
///
/// The annotation [deprecated] is a shorthand for deprecating until
/// an unspecified "next release" without migration instructions.
///
/// A feature can be any part of an API, from a full library to a single
/// parameter.
///
/// The intent of the `@Deprecated` annotation is to inform authors
/// who are currently using the feature,
/// that they will soon need to stop using that feature in their code,
/// even if the feature is currently still working correctly.
///
/// Deprecation is an early warning that the deprecated feature
/// is scheduled to be removed at a later time,
/// a time possibly specified in [message].
/// A deprecated feature should no longer be used,
/// code using it will break at some point in the future.
/// If existing code is using the feature,
/// that code should be rewritten to no longer use the deprecated feature.
///
/// A deprecated feature should document how the same effect can be achieved in
/// [message], so the programmer knows how to rewrite the code.
///
/// The `@Deprecated` annotation applies to libraries, top-level declarations
/// (variables, getters, setters, functions, classes, mixins,
/// extension and typedefs),
/// class-level declarations (variables, getters, setters, methods, operators or
/// constructors, whether static or not), named optional parameters and
/// trailing optional positional parameters.
///
/// Deprecation applies transitively to parts of a deprecated feature:
///
///  - If a library is deprecated, so is every member of it.
///  - If a class is deprecated, so is every member of it.
///  - If a variable is deprecated, so are its implicit getter and setter.
///
/// If a feature is deprecated in a superclass, it is *not* automatically
/// deprecated in a subclass as well. It is reasonable to remove a member
/// from a superclass and retain it in a subclass, so it needs to be possible
/// to deprecate the member only in the superclass.
///
/// A tool that processes Dart source code may report when:
///
/// - the code imports a deprecated library.
/// - the code exports a deprecated library, or any deprecated member of
///   a non-deprecated library.
/// - the code refers statically to a deprecated declaration.
/// - the code uses a member of an object with a statically known
///   type, where the member is deprecated on the interface of the static type.
/// - the code calls a method with an argument where the
///   corresponding optional parameter is deprecated on the object's static type.
///
/// If the deprecated use is inside a library, class or method which is itself
/// deprecated, the tool should not bother the user about it.
/// A deprecated feature is expected to use other deprecated features.
class Deprecated {
  /// Message provided to the user when they use the deprecated feature.
  ///
  /// The message should explain how to migrate away from the feature if an
  /// alternative is available, and when the deprecated feature is expected to be
  /// removed.
  final String? message;

  final _DeprecationKind _kind;

  /// Creates a deprecation annotation which specifies the migration path and
  /// expiration of the annotated feature.
  ///
  /// The [message] is displayed as part of the warning. The message should be
  /// aimed at the programmer using the annotated feature, and should recommend
  /// an alternative (if available), and say when this feature is expected to
  /// be removed if that is sooner or later than the next major version.
  const Deprecated(this.message) : _kind = _DeprecationKind.use;

  /// Creates an annotation which deprecates implementing a class or mixin.
  ///
  /// The annotation can be used on `class` or `mixin` declarations whose
  /// interface can currently be implemented, so they are not marked `final`,
  /// `sealed`, or `base`, but where the ability to implement will be removed
  /// in a later release.
  ///
  /// Any existing class, mixin or enum declaration which `implements` the
  /// interface will cause a warning that such use is deprecated. Does not
  /// affect classes which extend or mix in the annotated class or mixin (see
  /// [Deprecated.extend], [Deprecated.mixin], and [Deprecated.subclass]).
  ///
  /// The annotation is not inherited by subclasses. If a public subclass will
  /// also become unimplementable, which it will if the annotated declaration
  /// becomes `final` or `base`, but not if it becomes `sealed`, then the
  /// subclass should deprecate implementation as well.
  ///
  /// The [message], if given, is displayed as part of the warning. The message
  /// should be aimed at the programmer who owns the implementing class, and
  /// should recommend an alternative (if available), and say when this
  /// functionality is expected to be removed if that is sooner or later than
  /// the next major version.
  const Deprecated.implement([this.message])
    : _kind = _DeprecationKind.implement;

  /// Creates an annotation which deprecates extending a class.
  ///
  /// The annotation can be used on `class` declarations which can currently be
  /// extended, so they are not marked `final`, `sealed`, or `interface`, but
  /// where the ability to extend will be removed in a later release.
  ///
  /// Any existing class declaration which `extends` the class will cause a
  /// warning that such use is deprecated. Does not affect classes which
  /// implement or mix in the annotated class (see [Deprecated.implement],
  /// [Deprecated.mixin], and [Deprecated.subclass]).
  ///
  /// The annotation is not inherited by subclasses. If a public subclass will
  /// also become unextendable, which it will if the annotated declaration
  /// becomes `final` or `interface`, but not if it becomes `sealed`, then the
  /// subclass should deprecate extendability as well.
  ///
  /// The [message], if given, is displayed as part of the warning. The message
  /// should be aimed at the programmer who owns the extending class, and
  /// should recommend an alternative (if available), and say when this
  /// functionality is expected to be removed if that is sooner or later than
  /// the next major version.
  const Deprecated.extend([this.message]) : _kind = _DeprecationKind.extend;

  /// Creates an annotation which deprecates subclassing (implementing or
  /// extending) a class.
  ///
  /// The annotation can be used on `class` and `mixin` declarations which can
  /// currently be subclassed, so they are not marked `final`, or `sealed`, but
  /// where the ability to subclass will be removed in a later release.
  ///
  /// Any existing class declaration which `extends` or `implements` the
  /// annotated class or mixin will cause a warning that such use is
  /// deprecated. Does not affect classes which mix in the annotated class (see
  /// [Deprecated.extend], [Deprecated.implement] and [Deprecated.mixin]).
  ///
  /// The annotation is not inherited by subclasses. If a public subclass will
  /// also become unsubclassable, which it will if the annotated declaration
  /// becomes `final`, but not if it becomes `sealed`, then the subclass should
  /// deprecate subclassability as well.
  ///
  /// The [message], if given, is displayed as part of the warning. The message
  /// should be aimed at the programmer who owns the subclassing class, and
  /// should recommend an alternative (if available), and say when this
  /// functionality is expected to be removed if that is sooner or later than
  /// the next major version.
  const Deprecated.subclass([this.message]) : _kind = _DeprecationKind.subclass;

  /// Creates an annotation which deprecates instantiating a class.
  ///
  /// The annotation can be used on `class` declarations which can currently be
  /// instantiated, so they are not marked `abstract` or `sealed`, but where
  /// the ability to instantiate will be removed in a later release.
  ///
  /// Any existing code which instantiates the annotated class will cause a
  /// warning that such use is deprecated.
  ///
  /// The [message], if given, is displayed as part of the warning. The message
  /// should be aimed at the programmer who owns the instantiating code, and
  /// should recommend an alternative (if available), and say when this
  /// functionality is expected to be removed if that is sooner or later than
  /// the next major version.
  const Deprecated.instantiate([this.message])
    : _kind = _DeprecationKind.instantiate;

  /// Creates an annotation which deprecates mixing in a class.
  ///
  /// The annotation can be used on `class` declarations which can currently be
  /// mixed in, so they are marked `mixin`, but where the ability to mix in
  /// will be removed in a later release.
  ///
  /// Any existing class declaration which mixes in the annotated class will
  /// cause a warning that such use is deprecated. Does not affect classes
  /// which extend or implement the annotated class (see [Deprecated.extend],
  /// [Deprecated.implement] and [Deprecated.subclass]).
  ///
  /// The [message], if given, is displayed as part of the warning. The message
  /// should be aimed at the programmer who owns the class which mixes in the
  /// annotated class, and should recommend an alternative (if available), and
  /// say when this functionality is expected to be removed if that is sooner
  /// or later than the next major version.
  const Deprecated.mixin([this.message]) : _kind = _DeprecationKind.mixin;

  /// Creates an annotation which deprecates omitting an argument for the
  /// annotated parameter.
  ///
  /// The annotation can be used on optional parameters of methods,
  /// constructors, or top-level functions, indicating the parameter will be
  /// required in a later release.
  ///
  /// Any call to a function which does not pass a value for the annotated
  /// parameter will cause a warning that such omission is deprecated.
  ///
  /// The annotation is not inherited in method overrides.
  ///
  /// The [message], if given, is displayed as part of the warning. The message
  /// should be aimed at the programmer who is calling the function with the
  /// annotated parameter, and should recommend an alternative (if available),
  /// and say when this functionality is expected to be removed if that is
  /// sooner or later than the next major version.
  const Deprecated.optional([this.message]) : _kind = _DeprecationKind.optional;

  String toString() => "Deprecated feature: $message";
}

/// Marks a feature as [Deprecated] until the next release.
const Deprecated deprecated = Deprecated("next release");

/// The various kinds of deprecations with which a feature can be annotated.
///
/// Each deprecation kind is paired directly with a [Deprecated] constructor.
/// [_DeprecationKind.use] is used by the unnamed [Deprecated.new] constructor
/// and the [deprecated] constant.
///
/// This enum can be private because the information is only intended for
/// static tooling, such as the analyzer. Values may be added.
enum _DeprecationKind {
  use,
  implement,
  extend,
  subclass,
  instantiate,
  mixin,
  optional,
}

class _Override {
  const _Override();
}

/// Annotation on instance members which override an interface member.
///
/// Annotations have no effect on the meaning of a Dart program.
/// This annotation is recognized by the Dart analyzer, and it allows the
/// analyzer to provide hints or warnings for some potential problems of an
/// otherwise valid program.
/// As such, the meaning of this annotation is defined by the Dart analyzer.
///
/// The `@override` annotation expresses the intent
/// that a declaration *should* override an interface method,
/// something which is not visible from the declaration itself.
/// This extra information allows the analyzer to provide a warning
/// when that intent is not satisfied,
/// where a member is intended to override a superclass member or
/// implement an interface member, but fails to do so.
/// Such a situation can arise if a member name is mistyped,
/// or if the superclass renames the member.
///
/// The `@override` annotation applies to instance methods, instance getters,
/// instance setters and instance variables (fields).
/// When applied to an instance variable,
/// it means that the variable's implicit getter and setter (if any)
/// are marked as overriding. It has no effect on the variable itself.
///
/// Further [lints](https://dart.dev/lints)
/// can be used to enable more warnings based on `@override` annotations.
const Object override = _Override();

/// A hint to tools.
///
/// Tools that work with Dart programs may accept hints to guide their behavior
/// as `pragma` annotations on declarations.
/// Each tool decides which hints it accepts, what they mean, and whether and
/// how they apply to sub-parts of the annotated entity.
///
/// Tools that recognize pragma hints should pick a pragma prefix to identify
/// the tool. They should recognize any hint with a [name] starting with their
/// prefix followed by `:` as if it was intended for that tool. A hint with a
/// prefix for another tool should be ignored (unless compatibility with that
/// other tool is a goal).
///
/// A tool may recognize unprefixed names as well, if they would recognize that
/// name with their own prefix in front.
///
/// If the hint can be parameterized,
/// an extra [options] object can be added as well.
///
/// For example:
///
/// ```dart template:top
/// @pragma('Tool:pragma-name', [param1, param2, ...])
/// class Foo { }
///
/// @pragma('OtherTool:other-pragma')
/// void foo() { }
/// ```
///
/// Here class `Foo` is annotated with a Tool specific pragma 'pragma-name' and
/// function `foo` is annotated with a pragma 'other-pragma'
/// specific to OtherTool.
@pragma('vm:entry-point')
final class pragma {
  /// The name of the hint.
  ///
  /// A string that is recognized by one or more tools, or such a string prefixed
  /// by a tool identifier and a colon, which is only recognized by that
  /// particular tool.
  final String name;

  /// Optional extra data parameterizing the hint.
  final Object? options;

  /// Creates a hint named [name] with optional [options].
  const factory pragma(String name, [Object? options]) = pragma._;

  @pragma('dyn-module:language-impl:callable')
  const pragma._(this.name, [this.options]);
}
