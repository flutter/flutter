// idevicepicker.dart

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

import '../../../winrt/devices/enumeration/devicepickerfilter.dart';
// import '../../../winrt/devices/enumeration/devicepickerappearance.dart';
import '../../../winrt/foundation/collections/ivector.dart';
import '../../../winrt/devices/enumeration/devicepicker.dart';
// import '../../../winrt/devices/enumeration/deviceselectedeventargs.dart';
// import '../../../winrt/devices/enumeration/devicedisconnectbuttonclickedeventargs.dart';
import '../../../winrt/foundation/structs.g.dart';
import '../../../winrt/ui/popups/enums.g.dart';
import '../../../winrt/foundation/iasyncoperation.dart';
// import '../../../winrt/devices/enumeration/deviceinformation.dart';
import '../../../winrt/devices/enumeration/enums.g.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IDevicePicker = '{84997AA2-034A-4440-8813-7D0BD479BF5A}';

/// {@category Interface}
/// {@category winrt}
class IDevicePicker extends IInspectable {
  // vtable begins at 6, is 15 entries long.
  IDevicePicker.fromRawPointer(super.ptr);

  factory IDevicePicker.from(IInspectable interface) =>
      IDevicePicker.fromRawPointer(interface.toInterface(IID_IDevicePicker));

  DevicePickerFilter get filter {
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

    return DevicePickerFilter.fromRawPointer(retValuePtr);
  }

  Pointer<COMObject> get appearance {
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

    return retValuePtr;
  }

  IVector<String> get requestedProperties {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(8)
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

  int add_DeviceSelected(Pointer<NativeFunction<TypedEventHandler>> handler) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<TypedEventHandler>> handler,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<NativeFunction<TypedEventHandler>> handler,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, handler, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_DeviceSelected(int token) {
    final hr = ptr.ref.vtable
        .elementAt(10)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int add_DisconnectButtonClicked(
      Pointer<NativeFunction<TypedEventHandler>> handler) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<TypedEventHandler>> handler,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<NativeFunction<TypedEventHandler>> handler,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, handler, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_DisconnectButtonClicked(int token) {
    final hr = ptr.ref.vtable
        .elementAt(12)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int add_DevicePickerDismissed(
      Pointer<NativeFunction<TypedEventHandler>> handler) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<TypedEventHandler>> handler,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<NativeFunction<TypedEventHandler>> handler,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, handler, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_DevicePickerDismissed(int token) {
    final hr = ptr.ref.vtable
        .elementAt(14)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void show(Rect selection) {
    final hr = ptr.ref.vtable
        .elementAt(15)
        .cast<
            Pointer<
                NativeFunction<HRESULT Function(Pointer, Rect selection)>>>()
        .value
        .asFunction<
            int Function(Pointer, Rect selection)>()(ptr.ref.lpVtbl, selection);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void showWithPlacement(Rect selection, Placement placement) {
    final hr = ptr.ref.vtable
            .elementAt(16)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, Rect selection, Int32 placement)>>>()
            .value
            .asFunction<int Function(Pointer, Rect selection, int placement)>()(
        ptr.ref.lpVtbl, selection, placement.value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer<COMObject> pickSingleDeviceAsync(Rect selection) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(17)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, Rect selection, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, Rect selection, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, selection, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr;
  }

  Pointer<COMObject> pickSingleDeviceAsyncWithPlacement(
      Rect selection, Placement placement) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.vtable
                .elementAt(18)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(Pointer, Rect selection,
                                Int32 placement, Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Rect selection, int placement,
                        Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, selection, placement.value, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr;
  }

  void hide() {
    final hr = ptr.ref.vtable
        .elementAt(19)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void setDisplayStatus(Pointer<COMObject> device, String status,
      DevicePickerDisplayStatusOptions options) {
    final statusHstring = convertToHString(status);

    final hr = ptr.ref.vtable
            .elementAt(20)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject> device,
                            IntPtr status, Uint32 options)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<COMObject> device, int status,
                    int options)>()(ptr.ref.lpVtbl,
        device.cast<Pointer<COMObject>>().value, statusHstring, options.value);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(statusHstring);
  }
}
