// phonenumberformatter.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../combase.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../utils.dart';
import '../types.dart';
import '../winrt_helpers.dart';

import '../extensions/hstring_array.dart';
import 'ivector.dart';
import 'ivectorview.dart';

import 'iphonenumberformatter.dart';
import 'iphonenumberformatterstatics.dart';
import '../com/iinspectable.dart';

/// @nodoc
const IID_PhoneNumberFormatter = 'null';

/// {@category Interface}
/// {@category winrt}
class PhoneNumberFormatter extends IInspectable
    implements IPhoneNumberFormatter {
  PhoneNumberFormatter({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  PhoneNumberFormatter.fromPointer(super.ptr);

  static const _className =
      'Windows.Globalization.PhoneNumberFormatting.PhoneNumberFormatter';

  // IPhoneNumberFormatterStatics methods
  static void TryCreate(String regionCode, Pointer<COMObject> phoneNumber) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      final result = IPhoneNumberFormatterStatics(activationFactory)
          .TryCreate(regionCode, phoneNumber);
      return result;
    } finally {
      free(activationFactory);
    }
  }

  static int GetCountryCodeForRegion(String regionCode) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      final result = IPhoneNumberFormatterStatics(activationFactory)
          .GetCountryCodeForRegion(regionCode);
      return result;
    } finally {
      free(activationFactory);
    }
  }

  static String GetNationalDirectDialingPrefixForRegion(
      String regionCode, bool stripNonDigit) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      final result = IPhoneNumberFormatterStatics(activationFactory)
          .GetNationalDirectDialingPrefixForRegion(regionCode, stripNonDigit);
      return result;
    } finally {
      free(activationFactory);
    }
  }

  static String WrapWithLeftToRightMarkers(String number) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IPhoneNumberFormatterStatics);

    try {
      final result = IPhoneNumberFormatterStatics(activationFactory)
          .WrapWithLeftToRightMarkers(number);
      return result;
    } finally {
      free(activationFactory);
    }
  }

  // IPhoneNumberFormatter methods
  late final _iPhoneNumberFormatter =
      IPhoneNumberFormatter(toInterface(IID_IPhoneNumberFormatter));

  @override
  String Format(Pointer<COMObject> number) =>
      _iPhoneNumberFormatter.Format(number);

  @override
  String FormatWithOutputFormat(Pointer<COMObject> number, int numberFormat) =>
      _iPhoneNumberFormatter.FormatWithOutputFormat(number, numberFormat);

  @override
  String FormatPartialString(String number) =>
      _iPhoneNumberFormatter.FormatPartialString(number);

  @override
  String FormatString(String number) =>
      _iPhoneNumberFormatter.FormatString(number);

  @override
  String FormatStringWithLeftToRightMarkers(String number) =>
      _iPhoneNumberFormatter.FormatStringWithLeftToRightMarkers(number);
}
