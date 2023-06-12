// idevicepickerfilter.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../../winrt/internal/hstring_array.dart';

import '../../../winrt/foundation/collections/ivector.dart';
import '../../../winrt/devices/enumeration/enums.g.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IDevicePickerFilter = '{91DB92A2-57CB-48F1-9B59-A59B7A1F02A2}';

/// {@category Interface}
/// {@category winrt}
class IDevicePickerFilter extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IDevicePickerFilter.fromRawPointer(super.ptr);

  factory IDevicePickerFilter.from(IInspectable interface) =>
      IDevicePickerFilter.fromRawPointer(
          interface.toInterface(IID_IDevicePickerFilter));

  IVector<DeviceClass> get supportedDeviceClasses {
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

    if (FAILED(hr)) throw WindowsException(hr);

    return IVector.fromRawPointer(retValuePtr,
        enumCreator: DeviceClass.from, intType: Int32);
  }

  IVector<String> get supportedDeviceSelectors {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return IVector.fromRawPointer(retValuePtr);
  }
}
