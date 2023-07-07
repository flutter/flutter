// jsonarray.dart

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
import '../../foundation/collections/ivector.dart';
import '../../foundation/collections/ivectorview.dart';
import '../../foundation/istringable.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'ijsonarray.dart';
import 'ijsonarraystatics.dart';
import 'ijsonvalue.dart';
import 'jsonobject.dart';

/// Represents a JSON array.
///
/// {@category Class}
/// {@category winrt}
class JsonArray extends IInspectable
    implements
        IJsonArray,
        IJsonValue,
        IVector<IJsonValue>,
        IIterable<IJsonValue>,
        IStringable {
  JsonArray() : super(ActivateClass(_className));
  JsonArray.fromRawPointer(super.ptr);

  static const _className = 'Windows.Data.Json.JsonArray';

  // IJsonArrayStatics methods
  static JsonArray? parse(String input) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonArrayStatics);
    final object = IJsonArrayStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.parse(input);
    } finally {
      object.release();
    }
  }

  static bool tryParse(String input, JsonArray result) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IJsonArrayStatics);
    final object = IJsonArrayStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.tryParse(input, result);
    } finally {
      object.release();
    }
  }

  // IJsonArray methods
  late final _iJsonArray = IJsonArray.from(this);

  @override
  JsonObject? getObjectAt(int index) => _iJsonArray.getObjectAt(index);

  @override
  JsonArray? getArrayAt(int index) => _iJsonArray.getArrayAt(index);

  @override
  String getStringAt(int index) => _iJsonArray.getStringAt(index);

  @override
  double getNumberAt(int index) => _iJsonArray.getNumberAt(index);

  @override
  bool getBooleanAt(int index) => _iJsonArray.getBooleanAt(index);

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

  // IVector<IJsonValue> methods
  late final _iVector = IVector<IJsonValue>.fromRawPointer(
      toInterface('{d44662bc-dce3-59a8-9272-4b210f33908b}'),
      creator: IJsonValue.fromRawPointer,
      iterableIid: '{cb0492b6-4113-55cf-b2c5-99eb428ba493}');

  @override
  IJsonValue getAt(int index) => _iVector.getAt(index);

  @override
  int get size => _iVector.size;

  @override
  List<IJsonValue> getView() => _iVector.getView();

  @override
  bool indexOf(IJsonValue value, Pointer<Uint32> index) =>
      _iVector.indexOf(value, index);

  @override
  void setAt(int index, IJsonValue value) => _iVector.setAt(index, value);

  @override
  void insertAt(int index, IJsonValue value) => _iVector.insertAt(index, value);

  @override
  void removeAt(int index) => _iVector.removeAt(index);

  @override
  void append(IJsonValue value) => _iVector.append(value);

  @override
  void removeAtEnd() => _iVector.removeAtEnd();

  @override
  void clear() => _iVector.clear();

  @override
  int getMany(int startIndex, int valueSize, Pointer<NativeType> value) =>
      _iVector.getMany(startIndex, valueSize, value);

  @override
  void replaceAll(List<IJsonValue> value) => _iVector.replaceAll(value);

  @override
  IIterator<IJsonValue> first() => _iVector.first();

  @override
  List<IJsonValue> toList() => _iVector.toList();

  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
