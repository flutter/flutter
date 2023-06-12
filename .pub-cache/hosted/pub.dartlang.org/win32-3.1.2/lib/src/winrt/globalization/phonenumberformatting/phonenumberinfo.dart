// phonenumberinfo.dart

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

import 'iphonenumberinfo.dart';
import '../../foundation/istringable.dart';
import 'iphonenumberinfofactory.dart';
import 'iphonenumberinfostatics.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class PhoneNumberInfo extends IInspectable
    implements IPhoneNumberInfo, IStringable {
  PhoneNumberInfo.fromRawPointer(super.ptr);

  static const _className =
      'Windows.Globalization.PhoneNumberFormatting.PhoneNumberInfo';

  // IPhoneNumberInfoFactory methods
  static PhoneNumberInfo create(String number) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberInfoFactory);

    try {
      return IPhoneNumberInfoFactory.fromRawPointer(activationFactory)
          .create(number);
    } finally {
      free(activationFactory);
    }
  }

  // IPhoneNumberInfoStatics methods
  static PhoneNumberParseResult tryParse(
      String input, PhoneNumberInfo phoneNumber) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberInfoStatics);

    try {
      return IPhoneNumberInfoStatics.fromRawPointer(activationFactory)
          .tryParse(input, phoneNumber);
    } finally {
      free(activationFactory);
    }
  }

  static PhoneNumberParseResult tryParseWithRegion(
      String input, String regionCode, PhoneNumberInfo phoneNumber) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberInfoStatics);

    try {
      return IPhoneNumberInfoStatics.fromRawPointer(activationFactory)
          .tryParseWithRegion(input, regionCode, phoneNumber);
    } finally {
      free(activationFactory);
    }
  }

  // IPhoneNumberInfo methods
  late final _iPhoneNumberInfo = IPhoneNumberInfo.from(this);

  @override
  int get countryCode => _iPhoneNumberInfo.countryCode;

  @override
  String get phoneNumber => _iPhoneNumberInfo.phoneNumber;

  @override
  int getLengthOfGeographicalAreaCode() =>
      _iPhoneNumberInfo.getLengthOfGeographicalAreaCode();

  @override
  String getNationalSignificantNumber() =>
      _iPhoneNumberInfo.getNationalSignificantNumber();

  @override
  int getLengthOfNationalDestinationCode() =>
      _iPhoneNumberInfo.getLengthOfNationalDestinationCode();

  @override
  PredictedPhoneNumberKind predictNumberKind() =>
      _iPhoneNumberInfo.predictNumberKind();

  @override
  String getGeographicRegionCode() =>
      _iPhoneNumberInfo.getGeographicRegionCode();

  @override
  PhoneNumberMatchResult checkNumberMatch(PhoneNumberInfo otherNumber) =>
      _iPhoneNumberInfo.checkNumberMatch(otherNumber);
  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
