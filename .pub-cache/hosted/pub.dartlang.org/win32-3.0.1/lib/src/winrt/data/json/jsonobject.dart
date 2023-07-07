// jsonobject.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../utils.dart';
import '../../../winrt/data/json/ijsonobject.dart';
import '../../../winrt/data/json/ijsonobjectwithdefaultvalues.dart';
import '../../../winrt/data/json/ijsonvalue.dart';
import '../../../winrt/data/json/jsonarray.dart';
import '../../../winrt/data/json/jsonvalue.dart';
import '../../../winrt/foundation/collections/iiterator.dart';
import '../../../winrt/foundation/collections/ikeyvaluepair.dart';
import '../../../winrt/foundation/collections/imap.dart';
import '../../../winrt/foundation/istringable.dart';
import '../../../winrt_constants.dart';
import '../../../winrt_helpers.dart';
import 'enums.g.dart';
import 'ijsonobjectstatics.dart';

/// {@category Class}
/// {@category winrt}
class JsonObject extends IInspectable
    implements
        IJsonObject,
        IJsonValue,
        IMap<String, IJsonValue?>,
        IJsonObjectWithDefaultValues,
        IStringable {
  JsonObject({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  JsonObject.fromRawPointer(super.ptr);

  static const _className = 'Windows.Data.Json.JsonObject';

  // IJsonObjectStatics methods
  static JsonObject parse(String input) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonObjectStatics);

    try {
      return IJsonObjectStatics.fromRawPointer(activationFactory).parse(input);
    } finally {
      free(activationFactory);
    }
  }

  static bool tryParse(String input, JsonObject result) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonObjectStatics);

    try {
      return IJsonObjectStatics.fromRawPointer(activationFactory)
          .tryParse(input, result);
    } finally {
      free(activationFactory);
    }
  }

  // IJsonObject methods
  late final _iJsonObject = IJsonObject.from(this);

  @override
  JsonValue getNamedValue(String name) => _iJsonObject.getNamedValue(name);

  @override
  void setNamedValue(String name, IJsonValue value) =>
      _iJsonObject.setNamedValue(name, value);

  @override
  JsonObject getNamedObject(String name) => _iJsonObject.getNamedObject(name);

  @override
  JsonArray getNamedArray(String name) => _iJsonObject.getNamedArray(name);

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
  JsonArray getArray() => _iJsonValue.getArray();

  @override
  JsonObject getObject() => _iJsonValue.getObject();
  // IJsonObjectWithDefaultValues methods
  late final _iJsonObjectWithDefaultValues =
      IJsonObjectWithDefaultValues.from(this);

  @override
  JsonValue getNamedValueOrDefault(String name, JsonValue defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedValueOrDefault(name, defaultValue);

  @override
  JsonObject getNamedObjectOrDefault(String name, JsonObject defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedObjectOrDefault(name, defaultValue);

  @override
  String getNamedStringOrDefault(String name, String defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedStringOrDefault(name, defaultValue);

  @override
  JsonArray getNamedArrayOrDefault(String name, JsonArray defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedArrayOrDefault(name, defaultValue);

  @override
  double getNamedNumberOrDefault(String name, double defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedNumberOrDefault(name, defaultValue);

  @override
  bool getNamedBooleanOrDefault(String name, bool defaultValue) =>
      _iJsonObjectWithDefaultValues.getNamedBooleanOrDefault(
          name, defaultValue);

  late final _iMap = IMap<String, IJsonValue?>.fromRawPointer(
      toInterface(IID_IMap_String_IJsonValue),
      creator: IJsonValue.fromRawPointer);

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<String, IJsonValue?>> first() => _iMap.first();

  @override
  Map<String, IJsonValue?> getView() => _iMap.getView();

  @override
  bool hasKey(String value) => _iMap.hasKey(value);

  @override
  bool insert(String key, IJsonValue? value) =>
      _iMap.insert(key, value ?? JsonValue.createNullValue());

  @override
  IJsonValue? lookup(String key) => _iMap.lookup(key);

  @override
  void remove(String key) => _iMap.remove(key);

  @override
  int get size => _iMap.size;

  @override
  Map<String, IJsonValue?> toMap() => _iMap.toMap();

  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
