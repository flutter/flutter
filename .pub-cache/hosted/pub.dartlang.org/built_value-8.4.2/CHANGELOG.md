# Changelog

# 8.4.2

- Prepare for breaking analyzer changes.
- Bump version of `analyzer`.

# 8.4.1

- Bump version of `analyzer`.

# 8.4.0

- Fix custom builders in null safe code: allow nested builder fields to be
  nullable.
- Improve custom builders for null safe code: allow abstract setter/getter
  pairs instead of fields. This allows nested builders to have a setter that
  accepts `null` and a getter that guarantees not to return `null`, which is
  what auto instantiation of nested builders already provides.
- Allow use of super field initialization in `EnumClass`.

# 8.3.3

- Fix erroneously generated null check for fields with generic bounds.

# 8.3.2

- Migrate `built_value_test` to null safety.

# 8.3.1

- Fix generation support for optional generic bounds, e.g. 
  `class Foo<T extends Object?>`.
- Fix generation for classes with names starting `$`.
- Ignore lint `unnecessary_lambdas` in generated code.

# 8.3.0

- Change generated `build` methods to return only public types, creating
  `_build` methods that return the generated impl types. This means dartdoc
  will no longer reference the generated types.
- Ignore the `no_leading_underscores_for_local_identifiers` lint in generated
  code.
- Migrated `built_value_generator` to null safety. This is purely an internal
  change, the generator can still generate legacy code as and when needed.

# 8.2.3

- Bug fix: fix a corner case with generics that had incorrect serializer generation.

# 8.2.2

- Bug fix: remove a `print` from the enum generator.

# 8.2.1

- Fix deps: allow `built_value_generator` to use `built_value 8.2.0`.

# 8.2.0

- Allow writing final parameters in EnumClass constructor and valueOf method.
- Make generator output additional explicit null checks so the generated code complies with the `cast_nullable_to_non_nullable` lint.
- Bump version of `analyzer`.

# 8.1.4

- Bump version of `analyzer`.

# 8.1.3

- Bump version of `analyzer`, fix deprecation warnings.

# 8.1.2

- Bump version of `analyzer`.

# 8.1.1

- Bug fix: allow constructors to have annotations. Previously, annotations
  would cause codegen to fail.

# 8.1.0

New features:

- Add `@BuiltValueHook` annotation. It provides the same functionality as
  `_initializeBuilder` and `_finalizeBuilder`, but in a more visible way:
  annotate a static method on the value class with `@BuiltValueHook` to
  have it called on builder creation or finalization.
- Add back `serializeNulls` to `BuiltValueSerializer` annotation. By default
  generated serializers skip null fields instead of writing them; set
  `serializeNulls` to write the nulls.

New minor functionality:

- Support use of nulls in collections when the key or value types are
  explicitly nullable.
- Allow `JsonObject` to be instantiated from a `Map<dynamic, dynamic>`.
- Mark nested builder getters in `instantiable: false` classes not nullable,
  to match the implementations. Use `autoCreateNestedBuilders: false` to get
  the old behaviour.
- Allow explicit nulls in JSON for nullable fields when deserializing.
- Specify annotation targets; the analyzer will now hint if a `built_value`
  annotation is used where it has no effect.
- Support polymorphism with mixed in parent value type: generated builder
  now mixes in parent builder.

Bug fixes:

- Fix support for serializing and deserializing nulls.
- Fix `nestedBuilders: false` with `instantiable: false`.
- Fix enum deserialization fallback for `int`.
- Annotating a wrong type getter with `@SerializersFor` is now an error,
  instead of just generating nothing.

Cleanup:

- Removed Angular mixin from example, as this feature is no longer needed:
  Angular now directly supports using static members in templates.

# 8.0.6

- Bump versions of `build_config` and `build_runner`.

# 8.0.5

- Bump version of `analyzer`.

# 8.0.4

- Bump version of `source_gen`.

# 8.0.3

- Fix error message for builder factory not installed.
- Bump version of `build`.

# 8.0.2

- Bump versions of `analyzer`, `quiver`.

# 8.0.1

- Update `chat` example to webdev.
- Allow nulls when serializing/deserializing for better JSON interop.
- Fix generation bugs around enum wire name and polymorphism.
- Fix generation with generics for analysis with `strict-raw-types`.
- Add test coverage around generation for generic serialization.
- Add test coverage around initialization with generics.

# 8.0.0

- Stable null safe release.
- Add `toJson` and `fromJson` convenience methods to `Serializers`.

# 8.0.0-nullsafety.0

- Migrate to NNBD.
- Remove dependency on `package:quiver`.
- Remove support for serializing nulls using
  `BuiltValueSerializer(serializeNulls: true)`.
- Make installed plugins public in `Serializers` as `serializerPlugins`.
- `@memoized` fields can now memoize `null`; previously, nulls would not be
  cached, causing the computation to rerun.

# 7.1.1

- Support analyzer `^0.40.0`.
- Workaround https://github.com/google/built_value.dart/issues/941.

# 7.1.0

- Support private `Built` classes. Note that private classes cannot be made
  serializable.
- Support serializing enums to ints: add `wireNumber` to
  `@BuiltValueEnumConst`.
- Support memoizing `hashCode`, so it's computed lazily once. Write an abstract
  getter `int get hashCode;` then annotate it with `@memoized` to turn this on
  for a `built_value` class.
- Trim `built_value_test` dependencies: depend on `matcher` instead of `test`.
- Fix enum generator error messages when `value` and `valueOf` are missing.

# 7.0.9

- Fix unescaped string usages while generating `ValueSourceClass`.
- Fix analyzer use: don't rely on `toString` on types.

# 7.0.8

- Fix `analyzer` lower bound: was `0.39.0`, needs to be `0.39.3`.

# 7.0.7

- Fix regression in a corner case when determining which fields to generate
  based on mixins.
- Tweak generation changes for `implicit-casts: false` and
  `implicit-dynamic: false`. Relax casts again where possible.

# 7.0.6

- Make generated code comply with analyzer option `strict-raw-types`.
- Allow `Serialiers` declaration to comply with `strict-raw-types`, or to
  continue to use raw types as before.
- Make generated code comply with analyzer options `implicit-casts: false`
  and `implicit-dynamic: false`.

# 7.0.5

- Internal: fix analyzer deprecation warnings.

# 7.0.4

- Split analysis plugin out into new package, `built_value_analyzer_plugin`.
  Bump `built_value_generator` dependency on `analyzer` to `0.39.0` so it
  supports extension methods.

# 7.0.3

- Add `example` folders with `README.md` pointing to examples.

# 7.0.2

- Internal: cleanup for pedantic v1.9.0 lints.

# 7.0.1

- Internal: cleanup for pedantic v1.9.0 lints.

# 7.0.0

- Internal: clean up `built_value_generator` -> `built_value` dependency;
  depend on minor instead of major version so we can in future handle tight
  coupling between the two without a major version bump to `built_value`.

# 6.8.2

- Fix `_finalizeBuilder` generation so it uses the correct class name.

# 6.8.1

- Fix missing `README.md` in `package:built_value`.

# 6.8.0

- Support `_initializeBuilder` hook in value types. If found, it's executed
  when a `Builder` is created and can be used to set defaults.
- Support `_finalizeBuilder` hook in value types. If found, it's executed
  when `build` is called and can be used to apply processing to fields.
- Add `defaultCompare` and `defaultSerialize` to `@BuiltValue`. They
  control the defaults for `compare` and `serialize` in `@BuiltValueField`.
- Add facility to merge `Serializers` instances via `Serializers.merge`,
  `SerializersBuilder.merge` and `SerializersBuilder.mergeAll`.
- Bug fix: fix generated code with polymorphism and more than one level of
  non-instantiable classes.
- Bug fix: fix generated `operator==` when a field is called `other`.
- Fix `num` deserialization so it does not always convert to `double`.
- Bump version of `analyzer`.
- Internal: replace analyzer's `DartType.displayName` with custom code
  generator.

# 6.7.1

- Fix codegen for custom builders when fields use types that have an import
  prefix.
- Bump version of `analyzer_plugin`.

# 6.7.0

- Generate code compatible with 'no raw types'.

# 6.6.0

- Allow providing your own `toString` via a mixin.
- Fix `BuiltValueSerializer(serializeNulls: true)` for non-primitive fields.
- Stop using old analyzer API; require analyzer `0.34.0`.

# 6.5.0

- Add `Iso8601DurationSerializer` for use when you want ISO8601 serialization
  instead of the default microseconds serialization.
- Bump versions of `analyzer`, `analyzer_plugin` and `build_config`.

# 6.4.0

- Add `@BuiltValue(generateBuilderOnSetField: true)` which provides a way to
  listen for `set` calls on generated builders.
- Add `@BuiltValueEnumConst(fallback: true)` as a way to mark an enum const
  as the fallback when `valueOf` or deserialization fails.
- Add `@BuiltValueSerializer(serializeNulls: true` as a way to modify the wire
  format to explicitly contain `null` values.
- Make it possible to merge `Serializers` instances: add a `builderFactories`
  getter that returns installed builder factories.
- Use new `Function` syntax everywhere.
- Bug fix: only generate builder factories for fields that are `Built`
  types or `built_collection` collections.

# 6.3.2

- Allow `analyzer` 0.35.0.

# 6.3.1

- Fix `BuiltList` serialization when using `StandardJsonPlugin` with
  unspecified type and when list length is 1.

# 6.3.0

- Allow custom builders to use setter/getter pairs instead of normal fields.
- Add an option to `@BuiltValue` to turn off auto instantiation of nested
  builders.
- Add `@BuiltValueSerializer` annotation which gives the option to specify a
  custom serializer for a class.
- Make it possible to merge `Serializers` instances: add a `serializers`
  getter that returns the installed serializers.
- Add serializer for `RegExp` fields.
- Allow `analyzer` 0.34.0.

# 6.2.0

New features:

- Add an option to `@BuiltValue` to generate comparable builders.
- Add serializer for `Duration` fields.
- Add `serializerForType` and `serializerForWireName` methods to `Serializers`.

Improvements:

- Add ignore for `avoid_as` lint to generated code.
- Put ignored lints on a single line at the end of the generated output.
- Stop checking for import of `built_value.dart` when `EnumClass` is used; this
  was expensive.

Fixes:

- Fix tests following changes to source_gen error output.
- Fix generation when new `mixin` declarations are used.
- Support dollar signs in enum value names.
- Fix nested collections when using a custom builder.

# 6.1.6

- Switch to new analyzer API in version `0.33.3`.

# 6.1.5

- Bump versions of `analyzer`, `analyzer_plugin`, `build`, `build_runner`.

# 6.1.4

- Allow polymorphic base classes to omit implementing `Built` while still
  implementing any other interface(s).
- Allow the dollar character in `wireName` settings.
- Allow `build` version 1.0.

# 6.1.3

- Add `built_value_test` support for remaining built collections.

# 6.1.2

- Fix generated `operator==` when a type uses generic functions.
- Fix generated code for `curly_braces_in_control_flow` lint.

# 6.1.1

- Allow `build_runner` 0.10.0.

# 6.1.0

- Improve generation for `operator==`, don't use `dynamic`.
- Improve error message and documentation for missing builder factory.
- Allow built_collection 4.0.0.
- Fix code generation stack overflow when there is a loop in serializable
  types.
- Fix library name output in generation error messages.
- Add ignores for lints 'unnecessary_const' and 'unnecessary_new' to generated
  code.

# 6.0.0

- Update to the latest `source_gen`. This generator can now be used with other
  generators that want to write to `.g.dart` files without a manual build
  script.
- Breaking change: The "header" configuration on this builder is now ignored.

# 5.5.5

- Allow SDK 2.0.0.

# 5.5.4

- Add ignores for lints 'lines_longer_than_80_chars' and
  'avoid_catches_without_on_clauses' to generated code.
- Bump version of quiver.

# 5.5.3

- Bump versions of build_runner, build_config and shelf.

# 5.5.2

- Fix violations of `prefer_equal_for_default_values` lint.

# 5.5.1

- Bump versions of `analyzer`, `analyzer_plugin`.

# 5.5.0

- Support serializing `BuiltSet` with `StandardJsonPlugin`. It's serialized to
  a JSON list.
- Add `Iso8601DateTimeSerializer` for use when you want ISO8601 serialization
  instead of microseconds since epoch.
- Fix code generation when inherited generic fields are made non-generic.

# 5.4.5

- Improve error message on failure to deserialize.
- Move check forbidding instantiation with `dynamic` type parameters from
  builder to value class. Previously, you could avoid the check by using the
  generated constructor called `_`.

# 5.4.4

- Removed dependency on `build_config` from `built_value` and added it to
  `built_value_generator`.

# 5.4.3

- Allow source_gen 0.8.0.

# 5.4.2

- Make `StandardJsonPlugin` return `Map<String, Object>`, as the firebase
  libraries expect, instead of `Map<Object, Object>`.

# 5.4.1

- Fix analyzer plugin loading. It should now work, provided you modify your
  `analysis_options.yaml` as suggested.

# 5.4.0

- Add an experimental analyzer plugin that surfaces compile time generation
  errors as suggestions in your IDE. Turn it on by modifying your
  `analysis_options.yaml` file to add `plugins` entries,
  [example](https://github.com/google/built_value.dart/blob/master/analysis_options.yaml).

# 5.3.0

- Support serializing `BigInt`.
- Add support for setting the generated header in a `build.yaml` file in your
  project. See `example/build.yaml` for an example.
- Explicitly forbid serialization of `Function` and `typedef` types; these
  fields need to be marked `@BuiltValueField(serialize: false)`.
- Fix generation when a field picked up via inheritance is a function type
  defined in another source file.
- Fail with a helpful error message if `@SerializersFor` annotation list
  contains an undefined symbol.

# 5.2.2

- Fix built_value_generator/build.yaml to run generator on self package.
- Fix end_to_end_test/pubspec.yaml to include build_runner.
- Fix internal use of deprecated SDK constants.
- Remove polymorphism examples that no longer work in Dart 2. Proper fix to come.
- Allow quiver 0.29.

# 5.2.1

- Type fixes for DDC.

# 5.2.0

- Upgrade to latest `built_runner`. You no longer need `build.dart` or
  `watch.dart`. Instead, make sure you have a dev dependency on
  `built_value_generator` and `build_runner`, then run
  `pub run build_runner build` or `pub run build_runner watch`.
- Note: this version requires the pre release of the Dart 2 SDK.

# 5.1.3

- Generate simpler deserialization code for `built_collection` instances.

# 5.1.2

- Fix generated serialization code when a manually declared builder causes
  a field to not use a nested builder.

# 5.1.1

- Workaround for analyzer issue when `implement`ing multiple classes that
  use `@BuiltValue(instantiable: false)`.

## 5.1.0

- Relax restriction on `extends` to allow for one special case: sharing of
  code between `built_value` and `const` classes. The base class in question
  must be abstract, have no fields, have no abstract getters and must not
  implement `operator==`, `hashCode` or `toString`.

## 5.0.1

- Allow quiver 0.28.

## 5.0.0

Introduce restrictions on using `built_value` in unsupported ways:

- Prohibit use of `extends` in `built_value` classes. Classes should inherit
  API using `implements` and API+implementation using `extends Object with`.
- Prohibit use of `show` or `as` when importing
  'package:built_value/built_value.dart'. The generated code needs access to
  all symbols in the package with no import prefix.
- Prohibit use of the mutable collection types `List`, `Set`, `Map`,
  `ListMultimap` and `SetMultimap`. Suggest `built_collection` equivalents
  instead.

If any of these restrictions causes problem for you, please file an issue
on github: https://github.com/google/built_value.dart/issues

## 4.6.1

- Allow hand-coded base builders, that is, builders for classes with
  `@BuiltValue(instantaible: false)`. They are now allowed to not
  implement `Builder` (as a workaround for a dart2js issue); they are
  allowed to omit fields; and they must omit constructor and factory.

## 4.6.0

- Add custom `Error` classes: `BuiltValueNullFieldError`,
  `BuiltValueMissingGenericsError` and `BuiltValueNestedFieldError`. These
  provide clearer error messages on failure. In particular, errors in nested
  builders now report the enclosing class and field name, making them much
  more useful.
- Fix serialization when using polymorphism with StandardJsonPlugin.

## 4.5.2

- Allow built_collection 3.0.0.
- Allow quiver 0.27.

## 4.5.1

- Fix generation when analyzing using summaries.

## 4.5.0

New features:

- Add `serialize` field to `@BuiltValueField`. Use this to tag fields to skip
  when serializing.
- Add `wireName` field to `@BuiltValue` and `@BuiltValueField`. Use this to
  override the wire name for classes and fields when serializing.
- Add `@BuiltValueEnum` and `@BuiltValueEnumConst` annotations for specifying
  settings for enums. Add `wireName` field to these to override the wire names
  in enums when serializing.
- Add support for polymorphism to `StandardJsonPlugin`. It will now specify
  type names as needed via a `discriminator` field, which by defualt is
  called `$`. This can be changed in the `StandardJsonPlugin` constructor.
- Add `BuiltListAsyncDeserializer`. It provides a way to deserialize large
  responses without blocking, provided the top level serialized type is
  `BuiltList`.
- Add built in serializer for `Uri`.

Improvements:

- Allow declaration of multiple `Serializers` in the same file.
- Explicitly disallow private fields; fail with an error during generation if
  one is found.
- Improve error message for field without type.

Fixes:

- Fix generated builder when fields hold function types.
- Fix checks and generated builder when manually maintained builder has
  generics.
- Fix name of classes generated from a private class.
- Fix builder and serializer generation when importing with a prefix.

## 4.4.1

- Use build 0.11.1 and build_runner 0.6.0.

## 4.4.0

- New annotation, `BuiltValueField`, for configuring fields. First
  setting available is `compare`. Set to `false` to ignore a particular field
  for `operator==` and `hashCode`.
- Generator now has a `const` constructor.

## 4.3.4

- Fix for built_collection 2.0.0.

## 4.3.3

- Allow quiver 0.26.

## 4.3.2

- Fix generation when a field is found via two levels of inheritance.

## 4.3.1

- Fix generation when a field comes from an interface but is also implemented
  by a mixin.

## 4.3.0

- Support serializing Int64.

## 4.2.1

- Correct handling of import prefixes; fixes some corner cases in
  generation.

## 4.2.0

- Generated code ignores more lints.
- Add a workaround so "polymorphism" features can be used with dart2js.
  See example/lib/polymorphism.dart.
- Deal explicitly with the user defining their own operator==, hashCode
  and/or toString(). Previously, they would just not work. Now, custom
  operator== and hashCode are forbidden at compile time, but custom
  toString() is supported.

## 4.1.1

- Generated code now tells the analyzer to ignore
  prefer_expression_function_bodies and sort_constructors_first.
- Remove an unneeded use of computeNode in generator; improves generator
  performance.

## 4.1.0

- Improved annotation handling for corner cases.
- Pick up field declarations from mixins as well as interfaces.

## 4.0.0

- Fix generated polymorphic builders for the analyzer. Mark the `rebuild`
  method with `covariant` so the analyzer knows that, for example, a
  `CatBuilder` cannot accept an `Animal`.
- Update to build 0.10.0 and build_runner 0.4.0. Please update your
  `build.dart` and `watch.dart` as shown in the examples.

## 3.0.0

- Fix DateTime serialization; include microseconds. This is a breaking change
  to the JSON format.
- Add SerializersFor annotation. Classes to serialize are no longer found by
  scanning all available libraries, as this was slow and hard to control.
  Instead, specify which classes you need to serialize using the new
  annotation on your "serializers" declaration. You only need to specify the
  "root" classes; the classes needed for the fields of classes you specify
  are included, transitively.

## 2.1.0

- Add "nestedBuilders" setting. Defaults to true; set to false to stop
  using nested builders by default in fully generated builders.
- Allow fields to be called 'result'.
- Fix generation when a field is a noninstantiable built value: don't try to
  instantiate the abstract builder.

## 2.0.0

- Update to source_gen 0.7.0.
- Please make the following trivial update to your `build.dart` and
  `watch.dart`: replace the string `GeneratorBuilder` with `PartBuilder`.

## 1.2.1

- Fix generated code when implementing generic non-instantiable Built class.

## 1.2.0

- Fix depending on a fully generated builder from a manually maintained builder.
- Pick up fields on implemented interfaces, so you don't have to @override them.
- Add BuiltValue annotation for specifying settings.
- Add "instantiable" setting. When false, no implementation is generated, only
  a builder interface.
- Polymorphism support: you can now "implement" a non-instantiable Built class.
  The generated builder will implement its builder, so the types all work.

## 1.1.4

- Require SDK 1.21 and use the non-comment syntax for generics again.

## 1.1.3

- Removed dependency on now-unneeded package:meta.
- Fixed a few lints/hints in enum generated code.
- Use comment syntax for generics; using the non-comment syntax requires
  SDK 1.21 which is not specified in pubspec.yaml.

## 1.1.2

- Significantly improve build performance by using @memoized instead of
  precomputed fields.

## 1.1.1

- Update analyzer and build dependencies.

## 1.1.0

- Add "built_value_test" library. It provides a matcher which gives good
  mismatch messages for built_value instances.

## 1.0.1

- Allow quiver 0.25.

## 1.0.0

- Version bump to 1.0.0. Three minor features are marked as experimental and
  may change without a major version increase: BuiltValueToStringHelper,
  JsonObject and SerializerPlugin.
- Made toString() output customizable.
- Made the default toString() output use indentation and omit nulls.
- Sort serializers in generated output.

## 0.5.7

- Ignore nulls when deserializing with StandardJsonPlugin.

## 0.5.6

- Add serializer for "DateTime" fields.
- Add JsonObject class and serializer.
- Add convenience methods Seralizers.serializeWith and deserializeWith.
- Add example for using StandardJsonPlugin.
- Support serializing NaN, INF and -INF for double and num.

## 0.5.5

- Add serializer for "num" fields.
- Better error message for missing serializer.
- Fix generation when there are nested multi-parameter generics.
- Use cascades in generated code as suggested by lint.
- Allow users to define any factory that references the generated
  implementation.
- Add example of a simpler factory for a one-field class.

## 0.5.4

- Enforce that serializer declarations refer to the right generated name.
- Streamline generation for classes with no fields.
- Add identical check to generated operator==.
- Make generated code compatible with strong mode implicit-dynamic:false
  and implicit-cast:false.

## 0.5.3

- Add null check to generated builder "replace" methods.
- Fail with error on abstract enum classes.
- Update to `build` 0.7.0 , `build_runner` 0.3.0, and `build_test` 0.4.0.

## 0.5.2

- Support "import ... as" for field types.

## 0.5.1

- Add @memoized. Annotate getters on built_value classes with @memoized
  to memoize their result. That means it's computed on first access then
  stored in the instance.
- Support generics, in value types and in serialization.
- Add support for "standard" JSON via StandardJsonPlugin.

## 0.5.0

- Update dependency on analyzer, build, quiver.
- Breaking change: your build.dart and watch.dart now need to import
  build_runner/build_runner.dart instead of build/build.dart.

## 0.4.3

- Fix builder getters to be available before a set is used.

## 0.4.2

- Fix lints.
- Allow "updates" in value type factory to have explicit void return type.

## 0.4.1

- Fix some analyzer hints.
- Fix exception from serializer generator if builder field is incorrect.

## 0.4.0

- Add benchmark for updating deeply nested data structures.
- Make builders copy lazily. This makes updates to deeply nested structures
  much faster: only the classes on the path to the update are copied, instead
  of the entire tree.
- Breaking change: if you hand-code the builder then you must mark the fields
  @virtual so they can be overriden in the generated code.
- Auto-create nested nullable builders when they're accessed. Fixes
  deserialization with nested nullable builder.

## 0.3.0

- Merged built_json and built_json_generator into built_value and
  built_value_generator. These are intended to be used together, and make
  more sense as a single package.
- Fix generation when class extends multiple interfaces.
- Add serialization of BuiltListMultimap and BuiltSetMultimap.

## 0.2.0

- Merged enum_class and enum_class_generator into built_value and
  built_value_generator. These are intended to be used together, and make
  more sense as a single package.

## 0.1.6

- Add checking for correct type arguments for Built and Builder interfaces.
- Generate empty constructor with semicolon instead of {}.
- Use ArgumentError.notNull for null errors.
- Reject dynamic fields.
- Add simple benchmark for hashing. Improve hashing performance.

## 0.1.5

- Allow quiver 0.23.

## 0.1.4

- Upgrade analyzer, build and source_gen dependencies.

## 0.1.3

- Generate builder if it's not written by hand.
- Make toString append commas for improved clarity.
- Improve examples and tests.
- Fix double null checking.

## 0.1.2

- Refactor generator to split into logical classes.

## 0.1.1

- Improve error output on failure to generate.

## 0.1.0

- Upgrade to source_gen 0.5.0.
- Breaking change; see example for required changes to build.dart.

## 0.0.6

- Move null checks to "build" method for compatibility with Strong Mode
  analyzer.
- Allow (and ignore) setters.
- Allow custom factories on value classes.

## 0.0.5

- Fix for changes to analyzer library.

## 0.0.4

- Support @nullable for fields using builders.
- Fix constraints for source_gen.

## 0.0.3

- Allow static fields in value class.
- Allow custom setters in builder.

## 0.0.2

- Fix error message for missing builder class.
- Allow non-abstract getters in value class.

## 0.0.1

- Generator, tests and example.
