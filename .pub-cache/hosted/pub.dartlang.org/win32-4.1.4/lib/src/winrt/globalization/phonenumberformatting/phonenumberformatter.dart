// phonenumberformatter.dart

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
import 'enums.g.dart';
import 'iphonenumberformatter.dart';
import 'iphonenumberformatterstatics.dart';
import 'phonenumberinfo.dart';

/// Formats phone numbers.
///
/// {@category Class}
/// {@category winrt}
class PhoneNumberFormatter extends IInspectable
    implements IPhoneNumberFormatter {
  PhoneNumberFormatter() : super(ActivateClass(_className));
  PhoneNumberFormatter.fromRawPointer(super.ptr);

  static const _className =
      'Windows.Globalization.PhoneNumberFormatting.PhoneNumberFormatter';

  // IPhoneNumberFormatterStatics methods
  static void tryCreate(String regionCode, PhoneNumberFormatter phoneNumber) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);
    final object =
        IPhoneNumberFormatterStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.tryCreate(regionCode, phoneNumber);
    } finally {
      object.release();
    }
  }

  static int getCountryCodeForRegion(String regionCode) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);
    final object =
        IPhoneNumberFormatterStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getCountryCodeForRegion(regionCode);
    } finally {
      object.release();
    }
  }

  static String getNationalDirectDialingPrefixForRegion(
      String regionCode, bool stripNonDigit) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);
    final object =
        IPhoneNumberFormatterStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getNationalDirectDialingPrefixForRegion(
          regionCode, stripNonDigit);
    } finally {
      object.release();
    }
  }

  static String wrapWithLeftToRightMarkers(String number) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);
    final object =
        IPhoneNumberFormatterStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.wrapWithLeftToRightMarkers(number);
    } finally {
      object.release();
    }
  }

  // IPhoneNumberFormatter methods
  late final _iPhoneNumberFormatter = IPhoneNumberFormatter.from(this);

  @override
  String format(PhoneNumberInfo? number) =>
      _iPhoneNumberFormatter.format(number);

  @override
  String formatWithOutputFormat(
          PhoneNumberInfo? number, PhoneNumberFormat numberFormat) =>
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
