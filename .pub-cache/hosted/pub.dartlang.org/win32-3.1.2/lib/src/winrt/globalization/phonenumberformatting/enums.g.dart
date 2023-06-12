// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Lists phone number formats supported by this API.
///
/// {@category Enum}
enum PhoneNumberFormat implements WinRTEnum {
  e164(0),
  international(1),
  national(2),
  rfc3966(3);

  @override
  final int value;

  const PhoneNumberFormat(this.value);

  factory PhoneNumberFormat.from(int value) =>
      PhoneNumberFormat.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// The result of calling the PhoneNumberInfo.CheckNumberMatch method.
///
/// {@category Enum}
enum PhoneNumberMatchResult implements WinRTEnum {
  noMatch(0),
  shortNationalSignificantNumberMatch(1),
  nationalSignificantNumberMatch(2),
  exactMatch(3);

  @override
  final int value;

  const PhoneNumberMatchResult(this.value);

  factory PhoneNumberMatchResult.from(int value) =>
      PhoneNumberMatchResult.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Describes the results of trying to parse a string into a phone number.
///
/// {@category Enum}
enum PhoneNumberParseResult implements WinRTEnum {
  valid(0),
  notANumber(1),
  invalidCountryCode(2),
  tooShort(3),
  tooLong(4);

  @override
  final int value;

  const PhoneNumberParseResult(this.value);

  factory PhoneNumberParseResult.from(int value) =>
      PhoneNumberParseResult.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// The kinds of phone numbers returned by
/// PhoneNumberInfo.PredictNumberKind.
///
/// {@category Enum}
enum PredictedPhoneNumberKind implements WinRTEnum {
  fixedLine(0),
  mobile(1),
  fixedLineOrMobile(2),
  tollFree(3),
  premiumRate(4),
  sharedCost(5),
  voip(6),
  personalNumber(7),
  pager(8),
  universalAccountNumber(9),
  voicemail(10),
  unknown(11);

  @override
  final int value;

  const PredictedPhoneNumberKind(this.value);

  factory PredictedPhoneNumberKind.from(int value) =>
      PredictedPhoneNumberKind.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
