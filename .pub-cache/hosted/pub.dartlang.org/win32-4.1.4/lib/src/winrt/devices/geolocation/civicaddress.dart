// civicaddress.dart

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
import '../../internal/hstring_array.dart';
import 'icivicaddress.dart';

/// Unsupported API.
///
/// {@category Class}
/// {@category winrt}
class CivicAddress extends IInspectable implements ICivicAddress {
  CivicAddress.fromRawPointer(super.ptr);

  // ICivicAddress methods
  late final _iCivicAddress = ICivicAddress.from(this);

  @override
  String get country => _iCivicAddress.country;

  @override
  String get state => _iCivicAddress.state;

  @override
  String get city => _iCivicAddress.city;

  @override
  String get postalCode => _iCivicAddress.postalCode;

  @override
  DateTime get timestamp => _iCivicAddress.timestamp;
}
