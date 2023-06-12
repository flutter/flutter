// jsonvalue.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'ijsonvalue.dart';
import '../../foundation/istringable.dart';
import 'ijsonvaluestatics.dart';
import 'ijsonvaluestatics2.dart';
import 'enums.g.dart';
import 'jsonarray.dart';
import 'jsonobject.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class JsonValue extends IInspectable implements IJsonValue, IStringable {
  JsonValue.fromRawPointer(super.ptr);

  static const _className = 'Windows.Data.Json.JsonValue';

  // IJsonValueStatics methods
  static JsonValue parse(String input) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonValueStatics);

    try {
      return IJsonValueStatics.fromRawPointer(activationFactory).parse(input);
    } finally {
      free(activationFactory);
    }
  }

  static bool tryParse(String input, JsonValue result) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonValueStatics);

    try {
      return IJsonValueStatics.fromRawPointer(activationFactory)
          .tryParse(input, result);
    } finally {
      free(activationFactory);
    }
  }

  static JsonValue createBooleanValue(bool input) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonValueStatics);

    try {
      return IJsonValueStatics.fromRawPointer(activationFactory)
          .createBooleanValue(input);
    } finally {
      free(activationFactory);
    }
  }

  static JsonValue createNumberValue(double input) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonValueStatics);

    try {
      return IJsonValueStatics.fromRawPointer(activationFactory)
          .createNumberValue(input);
    } finally {
      free(activationFactory);
    }
  }

  static JsonValue createStringValue(String input) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonValueStatics);

    try {
      return IJsonValueStatics.fromRawPointer(activationFactory)
          .createStringValue(input);
    } finally {
      free(activationFactory);
    }
  }

  // IJsonValueStatics2 methods
  static JsonValue createNullValue() {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonValueStatics2);

    try {
      return IJsonValueStatics2.fromRawPointer(activationFactory)
          .createNullValue();
    } finally {
      free(activationFactory);
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
  JsonArray getArray() => _iJsonValue.getArray();

  @override
  JsonObject getObject() => _iJsonValue.getObject();
  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
