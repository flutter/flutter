// devicepickerfilter.dart

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
import '../../foundation/collections/ivector.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'idevicepickerfilter.dart';

/// Represents the filter used to determine which devices to show in the
/// device picker. The filter parameters are OR-ed together to build the
/// resulting filter.
///
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
