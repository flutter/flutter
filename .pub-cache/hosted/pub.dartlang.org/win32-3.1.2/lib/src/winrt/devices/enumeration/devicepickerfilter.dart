// devicepickerfilter.dart

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

import '../../../winrt/devices/enumeration/idevicepickerfilter.dart';
import '../../../winrt/foundation/collections/ivector.dart';
import '../../../winrt/devices/enumeration/enums.g.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class DevicePickerFilter extends IInspectable implements IDevicePickerFilter {
  DevicePickerFilter.fromRawPointer(super.ptr);

  // IDevicePickerFilter methods
  late final _iDevicePickerFilter = IDevicePickerFilter.from(this);

  @override
  IVector<DeviceClass> get supportedDeviceClasses =>
      _iDevicePickerFilter.supportedDeviceClasses;

  @override
  IVector<String> get supportedDeviceSelectors =>
      _iDevicePickerFilter.supportedDeviceSelectors;
}
