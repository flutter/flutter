// pedometerreading.dart

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

import 'ipedometerreading.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class PedometerReading extends IInspectable implements IPedometerReading {
  PedometerReading.fromRawPointer(super.ptr);

  // IPedometerReading methods
  late final _iPedometerReading = IPedometerReading.from(this);

  @override
  PedometerStepKind get stepKind => _iPedometerReading.stepKind;

  @override
  int get cumulativeSteps => _iPedometerReading.cumulativeSteps;

  @override
  DateTime get timestamp => _iPedometerReading.timestamp;

  @override
  Duration get cumulativeStepsDuration =>
      _iPedometerReading.cumulativeStepsDuration;
}
