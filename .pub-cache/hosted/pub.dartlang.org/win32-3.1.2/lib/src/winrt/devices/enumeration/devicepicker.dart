// devicepicker.dart

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

import '../../../winrt/devices/enumeration/idevicepicker.dart';
import '../../../winrt/devices/enumeration/devicepickerfilter.dart';
// import '../../../winrt/devices/enumeration/devicepickerappearance.dart';
import '../../../winrt/foundation/collections/ivector.dart';
// import '../../../winrt/devices/enumeration/deviceselectedeventargs.dart';
// import '../../../winrt/devices/enumeration/devicedisconnectbuttonclickedeventargs.dart';
import '../../../winrt/foundation/structs.g.dart';
import '../../../winrt/ui/popups/enums.g.dart';
import '../../../winrt/foundation/iasyncoperation.dart';
// import '../../../winrt/devices/enumeration/deviceinformation.dart';
import '../../../winrt/devices/enumeration/enums.g.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class DevicePicker extends IInspectable implements IDevicePicker {
  DevicePicker({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  DevicePicker.fromRawPointer(super.ptr);

  static const _className = 'Windows.Devices.Enumeration.DevicePicker';

  // IDevicePicker methods
  late final _iDevicePicker = IDevicePicker.from(this);

  @override
  DevicePickerFilter get filter => _iDevicePicker.filter;

  @override
  Pointer<COMObject> get appearance => _iDevicePicker.appearance;

  @override
  IVector<String> get requestedProperties => _iDevicePicker.requestedProperties;

  @override
  int add_DeviceSelected(Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iDevicePicker.add_DeviceSelected(handler);

  @override
  void remove_DeviceSelected(int token) =>
      _iDevicePicker.remove_DeviceSelected(token);

  @override
  int add_DisconnectButtonClicked(
          Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iDevicePicker.add_DisconnectButtonClicked(handler);

  @override
  void remove_DisconnectButtonClicked(int token) =>
      _iDevicePicker.remove_DisconnectButtonClicked(token);

  @override
  int add_DevicePickerDismissed(
          Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iDevicePicker.add_DevicePickerDismissed(handler);

  @override
  void remove_DevicePickerDismissed(int token) =>
      _iDevicePicker.remove_DevicePickerDismissed(token);

  @override
  void show(Rect selection) => _iDevicePicker.show(selection);

  @override
  void showWithPlacement(Rect selection, Placement placement) =>
      _iDevicePicker.showWithPlacement(selection, placement);

  @override
  Pointer<COMObject> pickSingleDeviceAsync(Rect selection) =>
      _iDevicePicker.pickSingleDeviceAsync(selection);

  @override
  Pointer<COMObject> pickSingleDeviceAsyncWithPlacement(
          Rect selection, Placement placement) =>
      _iDevicePicker.pickSingleDeviceAsyncWithPlacement(selection, placement);

  @override
  void hide() => _iDevicePicker.hide();

  @override
  void setDisplayStatus(Pointer<COMObject> device, String status,
          DevicePickerDisplayStatusOptions options) =>
      _iDevicePicker.setDisplayStatus(device, status, options);
}
