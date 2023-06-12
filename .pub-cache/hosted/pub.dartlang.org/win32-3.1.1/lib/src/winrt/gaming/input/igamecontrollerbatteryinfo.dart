// igamecontrollerbatteryinfo.dart

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

import '../../devices/power/batteryreport.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IGameControllerBatteryInfo = '{DCECC681-3963-4DA6-955D-553F3B6F6161}';

/// {@category Interface}
/// {@category winrt}
class IGameControllerBatteryInfo extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IGameControllerBatteryInfo.fromRawPointer(super.ptr);

  factory IGameControllerBatteryInfo.from(IInspectable interface) =>
      IGameControllerBatteryInfo.fromRawPointer(
          interface.toInterface(IID_IGameControllerBatteryInfo));

  BatteryReport tryGetBatteryReport() {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return BatteryReport.fromRawPointer(retValuePtr);
  }
}
