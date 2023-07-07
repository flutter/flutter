// ijsonvaluestatics.dart

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
import '../../internal/hstring_array.dart';
import 'jsonvalue.dart';

/// @nodoc
const IID_IJsonValueStatics = '{5f6b544a-2f53-48e1-91a3-f78b50a6345c}';

/// {@category Interface}
/// {@category winrt}
class IJsonValueStatics extends IInspectable {
  // vtable begins at 6, is 5 entries long.
  IJsonValueStatics.fromRawPointer(super.ptr);

  factory IJsonValueStatics.from(IInspectable interface) =>
      IJsonValueStatics.fromRawPointer(
          interface.toInterface(IID_IJsonValueStatics));

  JsonValue? parse(String input) {
    final retValuePtr = calloc<COMObject>();
    final inputHstring = convertToHString(input);

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr input, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int input, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, inputHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    WindowsDeleteString(inputHstring);

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return JsonValue.fromRawPointer(retValuePtr);
  }

  bool tryParse(String input, JsonValue result) {
    final retValuePtr = calloc<Bool>();
    final inputHstring = convertToHString(input);

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, IntPtr input,
                              Pointer<COMObject> result, Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int input, Pointer<COMObject> result,
                      Pointer<Bool>)>()(
          ptr.ref.lpVtbl, inputHstring, result.ptr, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(inputHstring);

      free(retValuePtr);
    }
  }

  JsonValue? createBooleanValue(bool input) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, Bool input, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, bool input, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, input, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return JsonValue.fromRawPointer(retValuePtr);
  }

  JsonValue? createNumberValue(double input) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(9)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, Double input, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, double input, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, input, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return JsonValue.fromRawPointer(retValuePtr);
  }

  JsonValue? createStringValue(String input) {
    final retValuePtr = calloc<COMObject>();
    final inputHstring = convertToHString(input);

    final hr = ptr.ref.vtable
            .elementAt(10)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr input, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int input, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, inputHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    WindowsDeleteString(inputHstring);

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return JsonValue.fromRawPointer(retValuePtr);
  }
}
