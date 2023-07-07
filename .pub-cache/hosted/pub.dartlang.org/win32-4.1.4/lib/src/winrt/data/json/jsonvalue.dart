// jsonvalue.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/istringable.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'ijsonvalue.dart';
import 'ijsonvaluestatics.dart';
import 'ijsonvaluestatics2.dart';
import 'jsonarray.dart';
import 'jsonobject.dart';

/// Implements the [IJsonValue] interface which represents a JSON value.
///
/// {@category Class}
/// {@category winrt}
class JsonValue extends IInspectable implements IJsonValue, IStringable {
  JsonValue.fromRawPointer(super.ptr);

  static const _className = 'Windows.Data.Json.JsonValue';

  // IJsonValueStatics methods
  static JsonValue? parse(String input) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonValueStatics);
    final object = IJsonValueStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.parse(input);
    } finally {
      object.release();
    }
  }

  static bool tryParse(String input, JsonValue result) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonValueStatics);
    final object = IJsonValueStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.tryParse(input, result);
    } finally {
      object.release();
    }
  }

  static JsonValue? createBooleanValue(bool input) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonValueStatics);
    final object = IJsonValueStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.createBooleanValue(input);
    } finally {
      object.release();
    }
  }

  static JsonValue? createNumberValue(double input) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonValueStatics);
    final object = IJsonValueStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.createNumberValue(input);
    } finally {
      object.release();
    }
  }

  static JsonValue? createStringValue(String input) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonValueStatics);
    final object = IJsonValueStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.createStringValue(input);
    } finally {
      object.release();
    }
  }

  // IJsonValueStatics2 methods
  static JsonValue? createNullValue() {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonValueStatics2);
    final object = IJsonValueStatics2.fromRawPointer(activationFactoryPtr);

    try {
      return object.createNullValue();
    } finally {
      object.release();
    }
  }

  // IJsonValue methods
  late final _iJsonValue = IJsonValue.from(this);

  @override
  JsonValueType get valueType => _iJsonValue.valueType;

  @override
  String stringify() => _iJsonValue.stringify();

  @override
  String getString() => _iJsonValue.getString();

  @override
  double getNumber() => _iJsonValue.getNumber();

  @override
  bool getBoolean() => _iJsonValue.getBoolean();

  @override
  JsonArray? getArray() => _iJsonValue.getArray();

  @override
  JsonObject? getObject() => _iJsonValue.getObject();

  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
