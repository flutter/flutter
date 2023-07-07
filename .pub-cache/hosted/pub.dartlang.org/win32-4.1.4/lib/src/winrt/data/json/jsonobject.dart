// jsonobject.dart

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
import '../../foundation/collections/iiterable.dart';
import '../../foundation/collections/iiterator.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';
import '../../foundation/collections/imapview.dart';
import '../../foundation/istringable.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'ijsonobject.dart';
import 'ijsonobjectstatics.dart';
import 'ijsonobjectwithdefaultvalues.dart';
import 'ijsonvalue.dart';
import 'jsonarray.dart';
import 'jsonvalue.dart';

/// Represents a JSON object containing a collection of name and [JsonValue]
/// pairs.
///
/// {@category Class}
/// {@category winrt}
class JsonObject extends IInspectable
    implements
        IJsonObject,
        IJsonValue,
        IMap<String, IJsonValue?>,
        IIterable<IKeyValuePair<String, IJsonValue?>>,
        IJsonObjectWithDefaultValues,
        IStringable {
  JsonObject() : super(ActivateClass(_className));
  JsonObject.fromRawPointer(super.ptr);

  static const _className = 'Windows.Data.Json.JsonObject';

  // IJsonObjectStatics methods
  static JsonObject? parse(String input) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonObjectStatics);
    final object = IJsonObjectStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.parse(input);
    } finally {
      object.release();
    }
  }

  static bool tryParse(String input, JsonObject result) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonObjectStatics);
    final object = IJsonObjectStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.tryParse(input, result);
    } finally {
      object.release();
    }
  }

  // IJsonObject methods
  late final _iJsonObject = IJsonObject.from(this);

  @override
  JsonValue? getNamedValue(String name) => _iJsonObject.getNamedValue(name);

  @override
  void setNamedValue(String name, IJsonValue? value) =>
      _iJsonObject.setNamedValue(name, value);

  @override
  JsonObject? getNamedObject(String name) => _iJsonObject.getNamedObject(name);

  @override
  JsonArray? getNamedArray(String name) => _iJsonObject.getNamedArray(name);

  @override
  String getNamedString(String name) => _iJsonObject.getNamedString(name);

  @override
  double getNamedNumber(String name) => _iJsonObject.getNamedNumber(name);

  @override
  bool getNamedBoolean(String name) => _iJsonObject.getNamedBoolean(name);

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

  // IMap<String, IJsonValue?> methods
  late final _iMap = IMap<String, IJsonValue?>.fromRawPointer(
      toInterface('{c9d9a725-786b-5113-b4b7-9b61764c220b}'),
      creator: IJsonValue.fromRawPointer,
      iterableIid: '{dfabb6e1-0411-5a8f-aa87-354e7110f099}');

  @override
  IJsonValue? lookup(String key) => _iMap.lookup(key);

  @override
  int get size => _iMap.size;

  @override
  bool hasKey(String key) => _iMap.hasKey(key);

  @override
  Map<String, IJsonValue?> getView() => _iMap.getView();

  @override
  bool insert(String key, IJsonValue? value) =>
      _iMap.insert(key, value ?? JsonValue.createNullValue());

  @override
  void remove(String key) => _iMap.remove(key);

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<String, IJsonValue?>> first() => _iMap.first();

  @override
  Map<String, IJsonValue?> toMap() => _iMap.toMap();

  // IJsonObjectWithDefaultValues methods
  late final _iJsonObjectWithDefaultValues =
      IJsonObjectWithDefaultValues.from(this);

  @override
  JsonValue? getNamedValueOrDefault(String name, JsonValue? defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedValueOrDefault(name, defaultValue);

  @override
  JsonObject? getNamedObjectOrDefault(String name, JsonObject? defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedObjectOrDefault(name, defaultValue);

  @override
  String getNamedStringOrDefault(String name, String defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedStringOrDefault(name, defaultValue);

  @override
  JsonArray? getNamedArrayOrDefault(String name, JsonArray? defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedArrayOrDefault(name, defaultValue);

  @override
  double getNamedNumberOrDefault(String name, double defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedNumberOrDefault(name, defaultValue);

  @override
  bool getNamedBooleanOrDefault(String name, bool defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedBooleanOrDefault(
          name, defaultValue);

  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
