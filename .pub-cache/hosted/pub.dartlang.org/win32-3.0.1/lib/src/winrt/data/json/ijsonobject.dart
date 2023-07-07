// ijsonobject.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../winrt/data/json/ijsonvalue.dart';
import '../../../winrt/data/json/jsonarray.dart';
import '../../../winrt/data/json/jsonobject.dart';
import '../../../winrt/data/json/jsonvalue.dart';
import '../../../winrt_helpers.dart';
import 'enums.g.dart';

/// @nodoc
const IID_IJsonObject = '{064E24DD-29C2-4F83-9AC1-9EE11578BEB3}';

/// {@category Interface}
/// {@category winrt}
class IJsonObject extends IInspectable implements IJsonValue {
  // vtable begins at 6, is 7 entries long.
  IJsonObject.fromRawPointer(super.ptr);

  factory IJsonObject.from(IInspectable interface) =>
      IJsonObject.fromRawPointer(interface.toInterface(IID_IJsonObject));

  JsonValue getNamedValue(String name) {
    final retValuePtr = calloc<COMObject>();
    final nameHstring = convertToHString(name);
    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr name, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int name, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, nameHstring, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(nameHstring);
    return JsonValue.fromRawPointer(retValuePtr);
  }

  void setNamedValue(String name, IJsonValue value) {
    final nameHstring = convertToHString(name);

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr name, Pointer<COMObject> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, int name, Pointer<COMObject> value)>()(
        ptr.ref.lpVtbl,
        nameHstring,
        value.ptr.cast<Pointer<COMObject>>().value);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(nameHstring);
  }

  JsonObject getNamedObject(String name) {
    final retValuePtr = calloc<COMObject>();
    final nameHstring = convertToHString(name);
    final hr = ptr.ref.vtable
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr name, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int name, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, nameHstring, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(nameHstring);
    return JsonObject.fromRawPointer(retValuePtr);
  }

  JsonArray getNamedArray(String name) {
    final retValuePtr = calloc<COMObject>();
    final nameHstring = convertToHString(name);
    final hr = ptr.ref.vtable
            .elementAt(9)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr name, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int name, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, nameHstring, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(nameHstring);
    return JsonArray.fromRawPointer(retValuePtr);
  }

  String getNamedString(String name) {
    final retValuePtr = calloc<HSTRING>();
    final nameHstring = convertToHString(name);

    try {
      final hr = ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr name, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int name, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, nameHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  double getNamedNumber(String name) {
    final retValuePtr = calloc<Double>();
    final nameHstring = convertToHString(name);

    try {
      final hr = ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr name, Pointer<Double>)>>>()
              .value
              .asFunction<int Function(Pointer, int name, Pointer<Double>)>()(
          ptr.ref.lpVtbl, nameHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);
      free(retValuePtr);
    }
  }

  bool getNamedBoolean(String name) {
    final retValuePtr = calloc<Bool>();
    final nameHstring = convertToHString(name);

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(12)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, IntPtr name, Pointer<Bool>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int name, Pointer<Bool>)>()(
              ptr.ref.lpVtbl, nameHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);
      free(retValuePtr);
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
}
