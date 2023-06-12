import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

export 'package:collection/collection.dart' show DeepCollectionEquality;
export 'package:json_annotation/json_annotation.dart';
export 'package:meta/meta.dart';

part 'freezed_annotation.g.dart';

/// An [UnmodifiableListView] which overrides ==
class EqualUnmodifiableListView<T> extends UnmodifiableListView<T> {
  /// An [UnmodifiableListView] which overrides ==
  EqualUnmodifiableListView(this._source) : super(_source);

  final Iterable<T> _source;

  @override
  bool operator ==(Object other) {
    return other is EqualUnmodifiableListView<T> &&
        other.runtimeType == runtimeType &&
        other._source == _source;
  }

  @override
  int get hashCode => Object.hash(runtimeType, _source);
}

/// An [UnmodifiableSetView] which overrides ==
class EqualUnmodifiableSetView<T> extends UnmodifiableSetView<T> {
  /// An [UnmodifiableSetView] which overrides ==
  EqualUnmodifiableSetView(this._source) : super(_source);

  final Set<T> _source;

  @override
  bool operator ==(Object other) {
    return other is EqualUnmodifiableSetView<T> &&
        other.runtimeType == runtimeType &&
        other._source == _source;
  }

  @override
  int get hashCode => Object.hash(runtimeType, _source);
}

/// An [UnmodifiableMapView] which overrides ==
class EqualUnmodifiableMapView<Key, Value>
    extends UnmodifiableMapView<Key, Value> {
  /// An [UnmodifiableMapView] which overrides ==
  EqualUnmodifiableMapView(this._source) : super(_source);

  final Map<Key, Value> _source;

  @override
  bool operator ==(Object other) {
    return other is EqualUnmodifiableMapView<Key, Value> &&
        other.runtimeType == runtimeType &&
        other._source == _source;
  }

  @override
  int get hashCode => Object.hash(runtimeType, _source);
}

/// Options for enabling/disabling specific `Union.map` features;
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  anyMap: true,
)
class FreezedMapOptions {
  /// Options for enabling/disabling specific `Union.map` features;
  const FreezedMapOptions({this.map, this.mapOrNull, this.maybeMap});

  /// Decode a [FreezedMapOptions] from a build.yaml
  factory FreezedMapOptions.fromJson(Map json) =>
      _$FreezedMapOptionsFromJson(json);

  /// Enables the generation of all `Union.map` features
  static const all =
      FreezedMapOptions(map: true, mapOrNull: true, maybeMap: true);

  /// Disables the generation of all `Union.map` features
  static const none =
      FreezedMapOptions(map: false, mapOrNull: false, maybeMap: false);

  /// Whether to generate `Union.map`
  ///
  /// If null, will fallback to the build.yaml configs
  /// If that value is null too, defaults to true.
  final bool? map;

  /// Whether to generate `Union.mapOrNull`
  ///
  /// If null, will fallback to the build.yaml configs
  /// If that value is null too, defaults to true.
  final bool? mapOrNull;

  /// Whether to generate `Union.maybeMap`
  ///
  /// If null, will fallback to the build.yaml configs
  /// If that value is null too, defaults to true.
  final bool? maybeMap;
}

/// Options for enabling/disabling specific `Union.when` features;
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  anyMap: true,
)
class FreezedWhenOptions {
  /// Options for enabling/disabling specific `Union.when` features;
  const FreezedWhenOptions({
    this.when,
    this.whenOrNull,
    this.maybeWhen,
  });

  /// Decode a [FreezedWhenOptions] from a build.yaml
  factory FreezedWhenOptions.fromJson(Map json) =>
      _$FreezedWhenOptionsFromJson(json);

  /// Enables the generation of all `Union.when` features
  static const all =
      FreezedWhenOptions(when: true, whenOrNull: true, maybeWhen: true);

  /// Disables the generation of all `Union.when` features
  static const none = FreezedWhenOptions(
    when: false,
    whenOrNull: false,
    maybeWhen: false,
  );

  /// Whether to generate `Union.when`
  ///
  /// If null, will fallback to the build.yaml configs
  /// If that value is null too, defaults to true.
  final bool? when;

  /// Whether to generate `Union.whenOrNull`
  ///
  /// If null, will fallback to the build.yaml configs
  /// If that value is null too, defaults to true.
  final bool? whenOrNull;

  /// Whether to generate `Union.maybeWhen`
  ///
  /// If null, will fallback to the build.yaml configs.
  /// If that value is null too, defaults to true.
  final bool? maybeWhen;
}

/// {@template freezed_annotation.freezed}
/// Flags a class as needing to be processed by Freezed and allows passing options.
/// {@endtemplate}
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  anyMap: true,
)
class Freezed {
  /// {@template freezed_annotation.freezed}
  const Freezed({
    this.unionKey,
    this.unionValueCase,
    this.fallbackUnion,
    this.copyWith,
    this.equal,
    this.toStringOverride,
    this.fromJson,
    this.toJson,
    this.map,
    this.when,
    this.makeCollectionsUnmodifiable,
    this.addImplicitFinal = true,
    this.genericArgumentFactories = false,
  });

  /// Decode the options from a build.yaml
  factory Freezed.fromJson(Map json) => _$FreezedFromJson(json);

  /// Whether to assume that all constructor parameters are marked as final.
  ///
  /// This means that:
  ///
  /// ```dart
  /// @Freezed(addImplicitFinal: true) // default to true
  /// class Person with _$Person {
  ///   factory Person(String name, int age) = _Person;
  /// }
  /// ```
  ///
  /// is strictly equivalent to:
  ///
  /// ```dart
  /// @Freezed(addImplicitFinal: false)
  /// class Person with _$Person {
  ///   factory Person(final String name, final int age) = _Person;
  /// }
  /// ```
  final bool addImplicitFinal;

  /// Determines what key should be used to de/serialize union types.
  ///
  /// Consider:
  ///
  /// {@template freezed_annotation.freezed.example}
  /// ```dart
  /// @freezed
  /// class Union with _$Union {
  ///   factory Union.first() = _First;
  ///   factory Union.second() = _Second;
  ///
  ///   factory Union.fromJson(Map<String, Object> json) => _$UnionFromJson(json);
  /// }
  /// ```
  ///
  /// When serializing or deserializing `Union`, Freezed will ask/demand for an
  /// extra json key, which represents which constructor should be used.
  ///
  /// More specifically, when calling `Union.toJson`, we will have:
  ///
  /// ```dart
  /// void main() {
  ///   print(Union.first().toJson()); // { 'runtimeType': 'first' }
  ///   print(Union.second().toJson()); // { 'runtimeType': 'second' }
  /// }
  /// ```
  /// {@endtemplate}
  ///
  /// This variable allows customizing the key used ("runtimeType" by default).
  ///
  /// For example, we could change our previous `Union` implementation to:
  ///
  /// ```dart
  /// @Freezed(unionKey: 'type')
  /// abstract class Union with _$Union {
  ///   // ...
  /// }
  /// ```
  ///
  /// which changes how `fromJson`/`toJson` behaves:
  ///
  /// ```dart
  /// void main() {
  ///   print(Union.first().toJson()); // { 'type': 'first' }
  ///   print(Union.second().toJson()); // { 'type': 'second' }
  /// }
  /// ```
  @JsonKey(defaultValue: 'runtimeType')
  final String? unionKey;

  /// Determines how the value used to de/serialize union types would be
  /// renamed.
  ///
  /// Consider:
  ///
  /// {@macro freezed_annotation.freezed.example}
  ///
  /// This variable allows customizing the value used (constructor name by
  /// default).
  ///
  /// For example, we could change our previous `Union` implementation to:
  ///
  /// ```dart
  /// @Freezed(unionValueCase: FreezedUnionCase.pascal)
  /// class Union with _$Union {
  ///   // ...
  /// }
  /// ```
  ///
  /// which changes how `fromJson`/`toJson` behaves:
  ///
  /// ```dart
  /// void main() {
  ///   print(Union.first().toJson()); // { 'runtimeType': 'First' }
  ///   print(Union.second().toJson()); // { 'runtimeType': 'Second' }
  /// }
  /// ```
  ///
  /// You can also use [FreezedUnionValue] annotation to customize single
  /// union case.
  final FreezedUnionCase? unionValueCase;

  /// Determines which constructor should be used when there is no matching one
  /// through constructor name or using [FreezedUnionValue]
  ///
  /// By default, Freezed generates code that will throw FallThroughError when type
  /// is not matched through constructor name or using [FreezedUnionValue].
  /// You can override this behavior by providing it's name or `default` to use
  /// default constructor
  ///
  /// ```dart
  /// @Freezed(fallbackUnion: 'fallback')
  /// class MyResponse with _$MyResponse {
  ///   const factory MyResponse.special(String a, int b) = MyResponseSpecial;
  ///   const factory MyResponse.fallback(String a, int b) = MyResponseFallback;
  ///
  ///   factory MyResponse.fromJson(Map<String, dynamic> json) => _$MyResponseFromJson(json);
  /// }
  /// ```
  ///
  /// The constructor will be chosen as follows:
  ///
  /// ```json
  /// [
  ///   {
  ///     "runtimeType": "special",
  ///     "a": "This JSON object will use constructor MyResponse.special()"
  ///     "b": 42
  ///   },
  ///   {
  ///     "runtimeType": "surprise",
  ///     "a": "This JSON object will use constructor MyResponse.fallback()",
  ///     "b": 42
  ///   }
  /// ]
  /// ```
  final String? fallbackUnion;

  /// If true, then this converts [List], [Map] and [Set] into respectively
  /// [UnmodifiableListView], [UnmodifiableMapView] or [UnmodifiableSetView].
  @JsonKey(defaultValue: true)
  final bool? makeCollectionsUnmodifiable;

  /// Whether to generate a `toString` or not
  ///
  /// If null, picks up the default values from the project's `build.yaml`.
  /// If that value is null too, generates a `toString` only if the class
  /// has no custom `toString`.
  final bool? toStringOverride;

  /// Whether to generate a `==/hashcode` or not
  ///
  /// If null, picks up the default values from the project's `build.yaml`.
  /// If that value is null too, generates a ==/hashcode only if the class
  /// does not have a custom ==
  final bool? equal;

  /// Whether to generate a `copyWith` or not
  ///
  /// If null, picks up the default values from the project's `build.yaml`.
  /// If that value is null too, defaults to true.
  @JsonKey(defaultValue: true)
  final bool? copyWith;

  /// Whether to generate a `fromJson` or not
  ///
  /// If null, picks up the default values from the project's `build.yaml`.
  ///
  /// If that value is null too, will be inferred based on whether the Freezed
  /// class has a `fromJson` constructor`, such that
  ///
  /// ```dart
  /// @freezed
  /// class Example with _$Example {
  ///   factory Example(int a) = _Example;
  ///
  ///   factory Example.fromJson(Map<String, Object?> json) => _$ExampleFromJson(json);
  /// }
  /// ```
  ///
  /// generates a `fromJson`.
  ///
  /// On the other hand, changing `fromJson(Map json) => _$ExampleFromJson(json)`
  /// to no-longer  use `=>` and instead use `{ return }`  will disable the
  /// generation of `fromJson`,
  ///
  /// ```dart
  /// @freezed
  /// class Example with _$Example {
  ///   factory Example(int a) = _Example;
  ///
  ///   factory Example.fromJson(Map<String, Object?> json) {
  ///     // Will not generate a _$ExampleFromJson class as we are using `{ return }`
  ///     return {...};
  ///   }
  /// }
  /// ```
  final bool? fromJson;

  /// Whether to generate a `toJson` or not
  ///
  /// If null, picks up the default values from the project's `build.yaml`.
  ///
  /// If that value is null too, will be inferred based on whether the Freezed
  /// class has a `fromJson` constructor`, such that
  ///
  /// ```dart
  /// @freezed
  /// class Example with _$Example {
  ///   factory Example(int a) = _Example;
  ///
  ///   factory Example.fromJson(Map<String, Object?> json) => _$ExampleFromJson(json);
  /// }
  /// ```
  ///
  /// generates a `toJson`.
  ///
  /// On the other hand, changing `fromJson(Map json) => _$ExampleFromJson(json)`
  /// to no-longer  use `=>` and instead use `{ return }`  will disable the
  /// generation of `toJson`,
  ///
  /// ```dart
  /// @freezed
  /// class Example with _$Example {
  ///   factory Example(int a) = _Example;
  ///
  ///   factory Example.fromJson(Map<String, Object?> json) {
  ///     // Will not generate a _$ExampleFromJson class as we are using `{ return }`
  ///     return {...};
  ///   }
  /// }
  /// ```
  final bool? toJson;

  /// Whether to enable the genericArgumentFactories feature of JsonSerializable
  ///
  /// Defaults to false.
  ///
  /// This changes `fromJson(Map json) => _$ExampleFromJson(json)`
  /// to have an additional parameter for each type parameter for the class
  ///
  /// ```dart
  /// @freezed
  /// class Example<T> with _$Example<T> {
  ///   factory Example<T>(T a) = _Example;
  ///
  ///   factory Example.fromJson(Map<String, Object?> json, T Function(Object?) fromJsonT) => _$ExampleFromJson(json, fromJsonT)`
  /// }
  /// ```
  final bool genericArgumentFactories;

  /// Options for customizing the generation of `map` functions
  ///
  /// If null, picks up the default values from the project's `build.yaml`.
  /// If that value is null too, defaults to [FreezedMapOptions.all].
  final FreezedMapOptions? map;

  /// Options for customizing the generation of `when` functions
  ///
  /// If null, picks up the default values from the project's `build.yaml`
  /// If that value is null too, defaults to [FreezedWhenOptions.all].
  final FreezedWhenOptions? when;
}

/// Defines an immutable data-class.
///
/// This will consider all properties of the object as immutable.
const freezed = Freezed();

/// Defines a potentially mutable data-class.
///
/// As opposed to [freezed], properties of the object can be mutable.
/// On the other hand, a data class will not implement ==.
const unfreezed = Freezed(
  equal: false,
  addImplicitFinal: false,
  makeCollectionsUnmodifiable: false,
);

/// {@template freezed_annotation.assert}
/// A decorator that allows adding `assert(...)` on the generated classes.
///
/// Usage example:
///
/// ```dart
/// abstract class Person with _$Person {
///   @Assert('name.trim().isNotEmpty', 'name cannot be empty')
///   @Assert('age >= 0')
///   factory Person({
///     String name,
///     int age,
///   }) = _Person;
/// }
/// ```
/// {@endtemplate}
class Assert {
  /// {@macro freezed_annotation.assert}
  const Assert(this.eval, [this.message]);

  /// A string representation of the source code that will be executed by the assert.
  final String eval;

  /// An optional message to show if the assertion failed.
  final String? message;
}

/// Allows passing default values to a constructor:
///
/// ```dart
/// abstract class Example with _$Example {
///   factory Example(@Default(42) int value) = _Example;
/// }
/// ```
///
/// is equivalent to:
///
/// ```dart
/// abstract class Example with _$Example {
///   factory Example(@JsonKey(defaultValue: 42) int value = 42) = _Example;
/// }
/// ```
class Default {
  const Default(this.defaultValue);

  final Object? defaultValue;
}

/// Marks a union type to implement the interface [stringType] or type T.
/// In the case below `City` will implement `AdministrativeArea<Hoouse>`.
/// ```dart
/// @freezed
/// abstract class Example with _$Example {
///   const factory Example.person(String name, int age) = Person;
///
///   @Implements<AdministrativeArea<House>>()
///   const factory Example.city(String name, int population) = City;
/// }
/// ```
///
/// If interface is generic the `Implements.fromString` constructor must be used
/// otherwise freezed will generate correct codee but dart will throw a load
/// error on the annotation declaration.
///
/// Note: You need to make sure that you comply with the interface requirements
/// by implementing all the abstract members. If the interface has no members or
/// just fields you can fulfil the interface contract by adding them in the
/// constructor of the union type. Keep in mind that if the interface defines a
/// method or a getter, that you implement in the class, you need to use the
/// [Custom getters and methods](#custom-getters-and-methods) instructions.
class Implements<T> {
  /// Marks a union type to implement the interface T.
  const Implements() : stringType = null;

  /// Marks a union type to implement the interface [stringType]. This
  /// constructor must be used when implementing a generic class with a generic
  /// type parameter e.g. `AdministrativeArea<T>` otherwise dart will throw a
  /// load error when compiling the annotation.
  const Implements.fromString(this.stringType);

  final String? stringType;
}

/// Marks a union type to mixin the interface [stringType] or type T.
/// In the case below `City` will mixin with `AdministrativeArea<House>`.
/// ```dart
/// @freezed
/// abstract class Example with _$Example {
///   const factory Example.person(String name, int age) = Person;
///
///   @With<AdministrativeArea<House>>()
///   const factory Example.city(String name, int population) = City;
/// }
/// ```
///
/// If interface is generic the `With.fromString` constructor must be used
/// otherwise freezed will generate correct code but dart will throw a load
/// error on the annotation declaration.
///
/// Note: You need to make sure that you comply with the interface requirements
/// by implementing all the abstract members. If the mixin has no members or
/// just fields, you can fulfil the interface contract by adding them in the
/// constructor of the union type. Keep in mind that if the mixin defines a
/// method or a getter, that you implement in the class, you need to use the
/// [Custom getters and methods](#custom-getters-and-methods) instructions.
class With<T> {
  /// Marks a union type to mixin the interface T.
  const With() : stringType = null;

  /// Marks a union type to mixin the interface [stringType]. This constructor
  /// must be used when mixing in a generic class with a generic type parameter
  /// e.g. `AdministrativeArea<T>` otherwise dart will throw a load error when
  /// compiling the annotation.
  const With.fromString(this.stringType);

  final String? stringType;
}

/// An annotation used to specify how a union type will be serialized.
///
/// By default, Freezed generates the value based on the name of the
/// constructor. You can override this behavior by annotating constructor and
/// providing custom value.
///
/// ```dart
/// @freezed
/// class MyResponse with _$MyResponse {
///   const factory MyResponse(String a) = MyResponseData;
///
///   @FreezedUnionValue('SpecialCase')
///   const factory MyResponse.special(String a, int b) = MyResponseSpecial;
///
///   factory MyResponse.fromJson(Map<String, dynamic> json) => _$MyResponseFromJson(json);
/// }
/// ```
///
/// The constructor will be chosen as follows:
///
/// ```json
/// [
///   {
///     "runtimeType": "default",
///     "a": "This JSON object will use constructor MyResponse()"
///   },
///   {
///     "runtimeType": "SpecialCase",
///     "a": "This JSON object will use constructor MyResponse.special()",
///     "b": 42
///   }
/// ]
/// ```
class FreezedUnionValue {
  const FreezedUnionValue(this.value);

  final String value;
}

/// Options for automatic union values renaming.
@JsonEnum(fieldRename: FieldRename.snake)
enum FreezedUnionCase {
  /// Use the name without changes.
  none,

  /// Encodes a constructor named `kebabCase` with a JSON value `kebab-case`.
  kebab,

  /// Encodes a constructor named `pascalCase` with a JSON value `PascalCase`.
  pascal,

  /// Encodes a constructor named `snakeCase` with a JSON value `snake_case`.
  snake,

  /// Encodes a constructor named `screamingSnakeCase` with a JSON value `SCREAMING_SNAKE_CASE`.
  screamingSnake,
}
