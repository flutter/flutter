// ijsonarraystatics.dart

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
import '../../../winrt/data/json/jsonarray.dart';

/// @nodoc
const IID_IJsonArrayStatics = '{DB1434A9-E164-499F-93E2-8A8F49BB90BA}';

/// {@category Interface}
/// {@category winrt}
class IJsonArrayStatics extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IJsonArrayStatics.fromRawPointer(super.ptr);

  factory IJsonArrayStatics.from(IInspectable interface) =>
      IJsonArrayStatics.fromRawPointer(
          interface.toInterface(IID_IJsonArrayStatics));

  JsonArray parse(String input) {
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

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(inputHstring);
    return JsonArray.fromRawPointer(retValuePtr);
  }

  bool tryParse(String input, JsonArray result) {
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
}
