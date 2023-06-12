// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/foundation.dart';

/// Parameters sent on updating user consent info.
class ConsentRequestParameters {
  /// Construct a [ConsentRequestParameters].
  ConsentRequestParameters(
      {this.tagForUnderAgeOfConsent, this.consentDebugSettings});

  /// Tag for underage of consent.
  ///
  /// False means users are not underage.
  bool? tagForUnderAgeOfConsent;

  /// Debug settings to hardcode in test requests.
  ConsentDebugSettings? consentDebugSettings;

  @override
  bool operator ==(Object other) {
    return other is ConsentRequestParameters &&
        tagForUnderAgeOfConsent == other.tagForUnderAgeOfConsent &&
        consentDebugSettings == other.consentDebugSettings;
  }
}

/// Debug settings to hardcode in test requests.
class ConsentDebugSettings {
  /// Construct a [ConsentDebugSettings].
  ConsentDebugSettings({this.debugGeography, this.testIdentifiers});

  /// Debug geography for testing geography.
  DebugGeography? debugGeography;

  /// List of device identifier strings.
  ///
  /// Debug features are enabled for devices with these identifiers.
  List<String>? testIdentifiers;

  @override
  bool operator ==(Object other) {
    return other is ConsentDebugSettings &&
        debugGeography == other.debugGeography &&
        listEquals(testIdentifiers, other.testIdentifiers);
  }
}

/// Debug values for testing geography.
enum DebugGeography {
  /// Debug geography disabled.
  debugGeographyDisabled,

  /// Geography appears as in EEA for debug devices.
  debugGeographyEea,

  /// Geography appears as not in EEA for debug devices.
  debugGeographyNotEea
}
