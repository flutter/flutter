// headset.dart

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

import 'iheadset.dart';
import 'igamecontrollerbatteryinfo.dart';
import '../../devices/power/batteryreport.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class Headset extends IInspectable
    implements IHeadset, IGameControllerBatteryInfo {
  Headset.fromRawPointer(super.ptr);

  // IHeadset methods
  late final _iHeadset = IHeadset.from(this);

  @override
  String get captureDeviceId => _iHeadset.captureDeviceId;

  @override
  String get renderDeviceId => _iHeadset.renderDeviceId;
  // IGameControllerBatteryInfo methods
  late final _iGameControllerBatteryInfo =
      IGameControllerBatteryInfo.from(this);

  @override
  BatteryReport tryGetBatteryReport() =>
      _iGameControllerBatteryInfo.tryGetBatteryReport();
}
