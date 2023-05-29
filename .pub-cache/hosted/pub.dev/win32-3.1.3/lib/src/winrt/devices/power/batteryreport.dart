// batteryreport.dart

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
import '../../foundation/ireference.dart';
import '../../internal/hstring_array.dart';
import '../../internal/ipropertyvalue_helpers.dart';
import '../../system/power/enums.g.dart';
import 'ibatteryreport.dart';

/// Provides properties that indicate the charge, capacity, and status of
/// the battery.
///
/// {@category Class}
/// {@category winrt}
class BatteryReport extends IInspectable implements IBatteryReport {
  BatteryReport.fromRawPointer(super.ptr);

  // IBatteryReport methods
  late final _iBatteryReport = IBatteryReport.from(this);

  @override
  int? get chargeRateInMilliwatts => _iBatteryReport.chargeRateInMilliwatts;

  @override
  int? get designCapacityInMilliwattHours =>
      _iBatteryReport.designCapacityInMilliwattHours;

  @override
  int? get fullChargeCapacityInMilliwattHours =>
      _iBatteryReport.fullChargeCapacityInMilliwattHours;

  @override
  int? get remainingCapacityInMilliwattHours =>
      _iBatteryReport.remainingCapacityInMilliwattHours;

  @override
  BatteryStatus get status => _iBatteryReport.status;
}
