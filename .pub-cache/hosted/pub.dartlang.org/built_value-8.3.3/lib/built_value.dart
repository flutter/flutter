// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

/// Implement this for a Built Value.
///
/// Then use built_value_generator.dart code generation functionality to
/// provide the rest of the implementation.
///
/// See https://github.com/google/built_value.dart/tree/master/example
abstract class Built<V extends Built<V, B>, B extends Builder<V, B>> {
  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.
  V rebuild(Function(B) updates);

  /// Converts the instance to a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.
  B toBuilder();
}

/// Every [Built] class has a corresponding [Builder] class.
///
/// Usually you don't need to create one by hand; it will be generated
/// for you.
///
/// See <https://github.com/google/built_value.dart/tree/master/example>
abstract class Builder<V extends Built<V, B>, B extends Builder<V, B>> {
  /// Replaces the value in the builder with a new one.
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.
  void replace(V value);

  /// Applies updates.
  ///
  /// [updates] is a function that takes a builder [B].
  void update(Function(B)? updates);

  /// Builds.
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.
  V build();
}

/// Optionally, annotate a Built Value with this to specify settings. This is
/// only needed for advanced use.
class BuiltValue {
  /// Whether the Built Value is instantiable. Defaults to `true`.
  ///
  /// A non-instantiable Built Value has no constructor or factory. No
  /// implementation will be generated. But, an abstract builder will be
  /// generated, or you may write one yourself.
  ///
  /// Other Built Values may choose to `implement` a non-instantiable Built
  /// Value, pulling in fields and methods from it. Their generated builders
  /// will automatically `implement` the corresponding builder, so you can
  /// access and modify the common inherited fields without knowing the
  /// concrete type.
  final bool instantiable;

  /// Whether to use nested builders. Defaults to `true`.
  ///
  /// If the builder class is fully generated, controls whether nested builders
  /// are used. This means builder fields are themselves builders if there is a
  /// builder available for each field type.
  ///
  /// If you write the builder class by hand, this has no effect; simply
  /// declare each field as the type you want, either the built type or the
  /// builder.
  final bool nestedBuilders;

  /// Whether to auto create nested builders. Defaults to `true`.
  ///
  /// When this is enabled, accessing a nested builder via a getter causes it
  /// to be instantiated if it's `null`. In most cases this is convenient, but
  /// if you are using builders for data processing then you might need to
  /// check for `null`. If so you should set this to `false`.
  final bool autoCreateNestedBuilders;

  /// Whether builders should implement `operator==` and `hashCode`, making
  /// them comparable.
  ///
  /// May only be used with `nestedBuilders: false` and if the builder class
  /// is fully generated.
  final bool comparableBuilders;

  /// Whether to generate an `onSet` field in the builder.
  ///
  /// Defaults to `false`.
  ///
  /// If generated the `onSet` field will have type `void Function()`, and will
  /// be called after any setter is called. Assign your own function to
  /// `onSet` to respond to changes to the builder.
  final bool generateBuilderOnSetField;

  /// The wire name when the class is serialized. Defaults to `null` which
  /// indicates that the name is to be taken from the literal class name.
  final String? wireName;

  /// The default for [BuiltValueField.compare]. Set to `false` if you want to
  /// ignore most fields when comparing, then mark the ones you do want to
  /// compare on with `@BuiltValueField(compare: true)`.
  final bool defaultCompare;

  /// The default for [BuiltValueField.serialize]. Set to `false` if you want
  /// to ignore most fields when serializing, then mark the ones you do want
  /// to serialize with `@BuiltValueField(serialize: true)`.
  final bool defaultSerialize;

  const BuiltValue(
      {this.instantiable = true,
      this.nestedBuilders = true,
      this.autoCreateNestedBuilders = true,
      this.comparableBuilders = false,
      this.generateBuilderOnSetField = false,
      this.wireName,
      this.defaultCompare = true,
      this.defaultSerialize = true});
}

/// Nullable annotation for Built Value fields.
///
/// Fields marked with this annotation are allowed to be null.
const String nullable = 'nullable';

/// Optionally, annotate a Built Value field with this to specify settings.
/// This is only needed for advanced use.
@Target({TargetKind.getter})
class BuiltValueField {
  /// Whether the field is compared and hashed. Defaults to `null` which means
  /// [BuiltValue.defaultCompare] is used.
  ///
  /// Set to `false` to ignore the field when calculating `hashCode` and when
  /// comparing with `operator==`.
  final bool? compare;

  /// Whether the field is serialized. Defaults to `null` which means
  /// [BuiltValue.defaultSerialize] is used.
  ///
  /// If a field is not serialized, it must either be `@nullable` or specify a
  /// default for deserialization to succeed.
  final bool? serialize;

  /// The wire name when the field is serialized. Defaults to `null` which
  /// indicates the name is to be taken from the literal field name.
  final String? wireName;

  /// Whether the field overrides the `nestedBuilders` setting from the class. Defaults to `null` which
  /// indicates the setting is to be taken from the `nestedBuilders` setting on the class.
  final bool? nestedBuilder;

  /// Whether the field overrides the `autoCreateNestedBuilders` setting from the class. Defaults to `null` which
  /// indicates the setting is to be taken from the `autoCreateNestedBuilders` setting on the class.
  final bool? autoCreateNestedBuilder;

  const BuiltValueField(
      {this.compare,
      this.serialize,
      this.wireName,
      this.nestedBuilder,
      this.autoCreateNestedBuilder});
}

/// Optionally, annotate a Built Value `Serializer` getters with this to
/// specify settings. This is only needed for advanced use.
@Target({TargetKind.getter})
class BuiltValueSerializer {
  /// Set this to `true` to stop Built Value from generating a serializer for
  /// you. The getter may then return any compatible `Serializer`. Defaults
  /// to `false`.
  final bool custom;

  /// Whether the generated serializer should output `null`s.
  ///
  /// By default this is `false` and nulls are omitted from the output.

  final bool serializeNulls;

  const BuiltValueSerializer(
      {this.custom = false, this.serializeNulls = false});
}

/// Memoized annotation for Built Value getters.
///
/// Getters marked with this annotation are memoized: the result is calculated
/// once on first access and stored in the instance.
const String memoized = 'memoized';

/// Optionally, annotate an `EnumClass` with this to specify settings. This
/// is only needed for advanced use.
@Target({TargetKind.classType})
class BuiltValueEnum {
  /// The wire name when the enum is serialized. Defaults to `null` which
  /// indicates that the name is to be taken from the literal class name.
  final String? wireName;

  const BuiltValueEnum({this.wireName});
}

/// Optionally, annotate an `EnumClass` constant with this to specify settings.
/// This is only needed for advanced use.
@Target({TargetKind.field})
class BuiltValueEnumConst {
  /// The wire name when the constant is serialized. Defaults to `null` which
  /// indicates the name is to be taken from the literal field name.
  ///
  /// Or, set [wireNumber] to serialize to an `int`. Only one of the two may be
  /// used.
  final String? wireName;

  /// The wire name when the constant is serialized. Defaults to `null` which
  /// indicates the name is to be taken from the literal field name.
  ///
  /// Or, set [wireName] to serialize to a `String`. Only one of the two may
  /// be used.
  final int? wireNumber;

  /// Marks a value that is used as a fallback when an unrecognized value
  /// is encountered.
  ///
  /// Defaults to `false`. At most one fallback is allowed per `EnumClass`.
  ///
  /// Applies to the `valueOf` method and to deserialization; both will use
  /// the fallback, if available, rather than throwing an exception.
  final bool fallback;

  const BuiltValueEnumConst(
      {this.wireName, this.wireNumber, this.fallback = false});
}

/// Optionally, annotate methods with this to cause them to be called by
/// generated code.
@Target({TargetKind.method})
class BuiltValueHook {
  /// Marks a static method that will be called when the builder for the
  /// enclosing value type is initialized.
  ///
  /// The method must accept a builder of the enclosing value type.
  ///
  /// This example uses it to set a default value:
  ///
  /// ```
  /// @BuiltValueHook(initializeBuilder: true)
  /// static void _initialize(MyClassBuilder b) =>
  ///    b..name = 'defaultName';
  ///
  /// Defaults to `false`.
  /// ```
  final bool initializeBuilder;

  /// Marks a static method that will be called immediately before the builder
  /// for the enclosing value type is built.
  ///
  /// The method must accept a builder of the enclosing value type.
  ///
  /// This example uses it to make `items` sorted:
  ///
  /// ```
  /// @BuiltValueHook(finalizeBuilder: true)
  /// static void _finalize(MyClassBuilder b) =>
  ///    b..items.sort();
  ///
  /// Defaults to `false`.
  /// ```
  final bool finalizeBuilder;

  const BuiltValueHook(
      {this.initializeBuilder = false, this.finalizeBuilder = false});
}

/// Enum Class base class.
///
/// Extend this class then use the built_value.dart code generation
/// functionality to provide the rest of the implementation.
///
/// See https://github.com/google/built_value.dart/tree/master/example
class EnumClass {
  final String name;

  const EnumClass(this.name);

  @override
  String toString() => name;
}

/// For use by generated code in calculating hash codes. Do not use directly.
int $jc(int hash, int value) {
  // Jenkins hash "combine".
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// For use by generated code in calculating hash codes. Do not use directly.
int $jf(int hash) {
  // Jenkins hash "finish".
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

/// Function that returns a [BuiltValueToStringHelper].
typedef BuiltValueToStringHelperProvider = BuiltValueToStringHelper Function(
    String className);

/// Function used by generated code to get a [BuiltValueToStringHelper].
/// Set this to change built_value class toString() output. Built-in examples
/// are [IndentingBuiltValueToStringHelper], which is the default, and
/// [FlatBuiltValueToStringHelper].
BuiltValueToStringHelperProvider newBuiltValueToStringHelper =
    (String className) => IndentingBuiltValueToStringHelper(className);

/// Interface for built_value toString() output helpers.
///
/// Note: this is an experimental feature. API may change without a major
/// version increase.
abstract class BuiltValueToStringHelper {
  /// Add a field and its value.
  void add(String field, Object? value);

  /// Returns to completed toString(). The helper may not be used after this
  /// method is called.
  @override
  String toString();
}

/// A [BuiltValueToStringHelper] that produces multi-line indented output.
class IndentingBuiltValueToStringHelper implements BuiltValueToStringHelper {
  StringBuffer? _result = StringBuffer();

  IndentingBuiltValueToStringHelper(String className) {
    _result!
      ..write(className)
      ..write(' {\n');
    _indentingBuiltValueToStringHelperIndent += 2;
  }

  @override
  void add(String field, Object? value) {
    if (value != null) {
      _result!
        ..write(' ' * _indentingBuiltValueToStringHelperIndent)
        ..write(field)
        ..write('=')
        ..write(value)
        ..write(',\n');
    }
  }

  @override
  String toString() {
    _indentingBuiltValueToStringHelperIndent -= 2;
    _result!
      ..write(' ' * _indentingBuiltValueToStringHelperIndent)
      ..write('}');
    var stringResult = _result.toString();
    _result = null;
    return stringResult;
  }
}

int _indentingBuiltValueToStringHelperIndent = 0;

/// A [BuiltValueToStringHelper] that produces single line output.
class FlatBuiltValueToStringHelper implements BuiltValueToStringHelper {
  StringBuffer? _result = StringBuffer();
  bool _previousField = false;

  FlatBuiltValueToStringHelper(String className) {
    _result!
      ..write(className)
      ..write(' {');
  }

  @override
  void add(String field, Object? value) {
    if (value != null) {
      if (_previousField) _result!.write(',');
      _result!
        ..write(field)
        ..write('=')
        ..write(value);
      _previousField = true;
    }
  }

  @override
  String toString() {
    _result!.write('}');
    var stringResult = _result.toString();
    _result = null;
    return stringResult;
  }
}

/// [Error] indicating that a built_value class constructor was called with
/// a `null` value for a field not marked `@nullable`.
class BuiltValueNullFieldError extends Error {
  final String type;
  final String field;

  BuiltValueNullFieldError(this.type, this.field);

  /// Throws a [BuiltValueNullFieldError] if [value] is `null`.
  static T checkNotNull<T>(T? value, String type, String field) {
    if (value == null) {
      throw BuiltValueNullFieldError(type, field);
    }
    return value;
  }

  @override
  String toString() =>
      'Tried to construct class "$type" with null field "$field". '
      'This is forbidden; to allow it, mark "$field" with @nullable.';
}

/// [Error] indicating that a built_value class constructor was called with
/// a missing or `dynamic` type parameter.
class BuiltValueMissingGenericsError extends Error {
  final String type;
  final String parameter;

  BuiltValueMissingGenericsError(this.type, this.parameter);

  @override
  String toString() =>
      'Tried to construct class "$type" with missing or dynamic '
      'type argument "$parameter". All type arguments must be specified.';
}

/// [Error] indicating that a built_value `build` method failed because a
/// nested field builder failed.
class BuiltValueNestedFieldError extends Error {
  final String type;
  final String field;
  final String error;

  BuiltValueNestedFieldError(this.type, this.field, this.error);

  @override
  String toString() =>
      'Tried to build class "$type" but nested builder for field "$field" '
      'threw: $error';
}
