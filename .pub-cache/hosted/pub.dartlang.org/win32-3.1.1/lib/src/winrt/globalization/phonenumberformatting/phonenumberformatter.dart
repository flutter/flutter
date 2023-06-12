// phonenumberformatter.dart

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

import 'iphonenumberformatter.dart';
import 'iphonenumberformatterstatics.dart';
import 'phonenumberinfo.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class PhoneNumberFormatter extends IInspectable
    implements IPhoneNumberFormatter {
  PhoneNumberFormatter({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  PhoneNumberFormatter.fromRawPointer(super.ptr);

  static const _className =
      'Windows.Globalization.PhoneNumberFormatting.PhoneNumberFormatter';

  // IPhoneNumberFormatterStatics methods
  static void tryCreate(String regionCode, PhoneNumberFormatter phoneNumber) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      return IPhoneNumberFormatterStatics.fromRawPointer(activationFactory)
          .tryCreate(regionCode, phoneNumber);
    } finally {
      free(activationFactory);
    }
  }

  static int getCountryCodeForRegion(String regionCode) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      return IPhoneNumberFormatterStatics.fromRawPointer(activationFactory)
          .getCountryCodeForRegion(regionCode);
    } finally {
      free(activationFactory);
    }
  }

  static String getNationalDirectDialingPrefixForRegion(
      String regionCode, bool stripNonDigit) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      return IPhoneNumberFormatterStatics.fromRawPointer(activationFactory)
          .getNationalDirectDialingPrefixForRegion(regionCode, stripNonDigit);
    } finally {
      free(activationFactory);
    }
  }

  static String wrapWithLeftToRightMarkers(String number) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      return IPhoneNumberFormatterStatics.fromRawPointer(activationFactory)
          .wrapWithLeftToRightMarkers(number);
    } finally {
      free(activationFactory);
    }
  }

  // IPhoneNumberFormatter methods
  late final _iPhoneNumberFormatter = IPhoneNumberFormatter.from(this);

  @override
  String format(PhoneNumberInfo number) =>
      _iPhoneNumberFormatter.format(number);

  @override
  String formatWithOutputFormat(
          PhoneNumberInfo number, PhoneNumberFormat numberFormat) =>
      _iPhoneNumberFormatter.formatWithOutputFormat(number, numberFormat);

  @override
  String formatPartialString(String number) =>
      _iPhoneNumberFormatter.formatPartialString(number);

  @override
  String formatString(String number) =>
      _iPhoneNumberFormatter.formatString(number);

  @override
  String formatStringWithLeftToRightMarkers(String number) =>
      _iPhoneNumberFormatter.formatStringWithLeftToRightMarkers(number);
}
