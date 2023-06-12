// jsonarray.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../utils.dart';
import '../../../winrt/data/json/ijsonarray.dart';
import '../../../winrt/data/json/ijsonvalue.dart';
import '../../../winrt/data/json/jsonobject.dart';
import '../../../winrt/foundation/collections/iiterator.dart';
import '../../../winrt/foundation/istringable.dart';
import '../../../winrt_constants.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/collections/ivector.dart';
import 'enums.g.dart';
import 'ijsonarraystatics.dart';

/// {@category Class}
/// {@category winrt}
class JsonArray extends IInspectable
    implements IJsonArray, IJsonValue, IVector<IJsonValue>, IStringable {
  JsonArray({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  JsonArray.fromRawPointer(super.ptr);

  static const _className = 'Windows.Data.Json.JsonArray';

  // IJsonArrayStatics methods
  static JsonArray parse(String input) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonArrayStatics);

    try {
      return IJsonArrayStatics.fromRawPointer(activationFactory).parse(input);
    } finally {
      free(activationFactory);
    }
  }

  static bool tryParse(String input, JsonArray result) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IJsonArrayStatics);

    try {
      return IJsonArrayStatics.fromRawPointer(activationFactory)
          .tryParse(input, result);
    } finally {
      free(activationFactory);
    }
  }

  // IJsonArray methods
  late final _iJsonArray = IJsonArray.from(this);

  @override
  JsonObject getObjectAt(int index) => _iJsonArray.getObjectAt(index);

  @override
  JsonArray getArrayAt(int index) => _iJsonArray.getArrayAt(index);

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
  JsonArray getArray() => _iJsonValue.getArray();

  @override
  JsonObject getObject() => _iJsonValue.getObject();

  late final _iVector = IVector<IJsonValue>.fromRawPointer(
      toInterface(IID_IVector_IJsonValue),
      creator: IJsonValue.fromRawPointer);

  @override
  void append(IJsonValue value) => _iVector.append(value);

  @override
  void clear() => _iVector.clear();

  @override
  IIterator<IJsonValue> first() => _iVector.first();

  @override
  IJsonValue getAt(int index) => _iVector.getAt(index);

  @override
  int getMany(int startIndex, int capacity, Pointer<NativeType> value) =>
      _iVector.getMany(startIndex, capacity, value);

  @override
  List<IJsonValue> getView() => _iVector.getView();

  @override
  bool indexOf(IJsonValue value, Pointer<Uint32> index) =>
      _iVector.indexOf(value, index);

  @override
  void insertAt(int index, IJsonValue value) => _iVector.insertAt(index, value);

  @override
  void removeAt(int index) => _iVector.removeAt(index);

  @override
  void removeAtEnd() => _iVector.removeAtEnd();

  @override
  void replaceAll(List<IJsonValue> value) => _iVector.replaceAll(value);

  @override
  void setAt(int index, IJsonValue value) => _iVector.setAt(index, value);

  @override
  int get size => _iVector.size;

  @override
  List<IJsonValue> toList() => _iVector.toList();

  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
