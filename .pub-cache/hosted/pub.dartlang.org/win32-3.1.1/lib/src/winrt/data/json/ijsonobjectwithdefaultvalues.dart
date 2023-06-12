// ijsonobjectwithdefaultvalues.dart

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

import 'ijsonobject.dart';
import 'ijsonvalue.dart';
import 'jsonvalue.dart';
import 'jsonobject.dart';
import 'jsonarray.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IJsonObjectWithDefaultValues =
    '{D960D2A2-B7F0-4F00-8E44-D82CF415EA13}';

/// {@category Interface}
/// {@category winrt}
class IJsonObjectWithDefaultValues extends IInspectable
    implements IJsonObject, IJsonValue {
  // vtable begins at 6, is 6 entries long.
  IJsonObjectWithDefaultValues.fromRawPointer(super.ptr);

  factory IJsonObjectWithDefaultValues.from(IInspectable interface) =>
      IJsonObjectWithDefaultValues.fromRawPointer(
          interface.toInterface(IID_IJsonObjectWithDefaultValues));

  JsonValue getNamedValueOrDefault(String name, JsonValue defaultValue) {
    final retValuePtr = calloc<COMObject>();
    final nameHstring = convertToHString(name);

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            IntPtr name,
                            Pointer<COMObject> defaultValue,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int name, Pointer<COMObject> defaultValue,
                    Pointer<COMObject>)>()(ptr.ref.lpVtbl, nameHstring,
        defaultValue.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(nameHstring);

    return JsonValue.fromRawPointer(retValuePtr);
  }

  JsonObject getNamedObjectOrDefault(String name, JsonObject defaultValue) {
    final retValuePtr = calloc<COMObject>();
    final nameHstring = convertToHString(name);

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            IntPtr name,
                            Pointer<COMObject> defaultValue,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int name, Pointer<COMObject> defaultValue,
                    Pointer<COMObject>)>()(ptr.ref.lpVtbl, nameHstring,
        defaultValue.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(nameHstring);

    return JsonObject.fromRawPointer(retValuePtr);
  }

  String getNamedStringOrDefault(String name, String defaultValue) {
    final retValuePtr = calloc<HSTRING>();
    final nameHstring = convertToHString(name);
    final defaultValueHstring = convertToHString(defaultValue);

    try {
      final hr = ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, IntPtr name,
                              IntPtr defaultValue, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int name, int defaultValue, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, nameHstring, defaultValueHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);
      WindowsDeleteString(defaultValueHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  JsonArray getNamedArrayOrDefault(String name, JsonArray defaultValue) {
    final retValuePtr = calloc<COMObject>();
    final nameHstring = convertToHString(name);

    final hr = ptr.ref.vtable
            .elementAt(9)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            IntPtr name,
                            Pointer<COMObject> defaultValue,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int name, Pointer<COMObject> defaultValue,
                    Pointer<COMObject>)>()(ptr.ref.lpVtbl, nameHstring,
        defaultValue.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(nameHstring);

    return JsonArray.fromRawPointer(retValuePtr);
  }

  double getNamedNumberOrDefault(String name, double defaultValue) {
    final retValuePtr = calloc<Double>();
    final nameHstring = convertToHString(name);

    try {
      final hr = ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, IntPtr name,
                              Double defaultValue, Pointer<Double>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int name, double defaultValue,
                      Pointer<Double>)>()(
          ptr.ref.lpVtbl, nameHstring, defaultValue, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);

      free(retValuePtr);
    }
  }

  bool getNamedBooleanOrDefault(String name, bool defaultValue) {
    final retValuePtr = calloc<Bool>();
    final nameHstring = convertToHString(name);

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(11)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, IntPtr name,
                                  Bool defaultValue, Pointer<Bool>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int name, bool defaultValue,
                          Pointer<Bool>)>()(
              ptr.ref.lpVtbl, nameHstring, defaultValue, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);

      free(retValuePtr);
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
}
