// Copyright 2021 Google LLC
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

/// Contains targeting information that can be applied to all ad requests.
///
/// See relevant documentation at
/// https://developers.google.com/ad-manager/mobile-ads-sdk/android/targeting#requestconfiguration.
class RequestConfiguration {
  /// Maximum content rating that will be shown.
  final String? maxAdContentRating;

  /// Whether to tag as child directed.
  final int? tagForChildDirectedTreatment;

  /// Whether to tag as under age of consent.
  final int? tagForUnderAgeOfConsent;

  /// List of test device ids to set.
  final List<String>? testDeviceIds;

  /// Creates a [RequestConfiguration].
  RequestConfiguration(
      {this.maxAdContentRating,
      this.tagForChildDirectedTreatment,
      this.tagForUnderAgeOfConsent,
      this.testDeviceIds});
}

/// Values for [RequestConfiguration.maxAdContentRating].
class MaxAdContentRating {
  /// No specified content rating.
  static final String unspecified = '';

  /// Content suitable for general audiences, including families.
  static final String g = 'G';

  /// Content suitable for most audiences with parental guidance.
  static final String pg = 'PG';

  /// Content suitable for most audiences with parental guidance.
  static final String t = 'T';

  /// Content suitable only for mature audiences.
  static final String ma = 'MA';
}

/// Values for [RequestConfiguration.tagForUnderAgeOfConsent].
class TagForUnderAgeOfConsent {
  /// Tag as under age of consent.
  ///
  /// Indicates the publisher specified that the ad request should receive
  /// treatment for users in the European Economic Area (EEA) under the age
  /// of consent.
  static final int yes = 1;

  /// Tag as NOT under age of consent.
  ///
  /// Indicates the publisher specified that the ad request should not receive
  /// treatment for users in the European Economic Area (EEA) under the age of
  /// consent.
  static final int no = 0;

  /// Do not specify tag for under age of consent.
  ///
  /// Indicates that the publisher has not specified whether the ad request
  /// should receive treatment for users in the European Economic Area (EEA)
  /// under the age of consent.
  static final int unspecified = -1;
}

/// Values for [RequestConfiguration.tagForChildDirectedTreatment].
class TagForChildDirectedTreatment {
  /// Tag for child directed treatment.
  ///
  /// Indicates the publisher specified that the ad request should receive
  /// treatment for users in the European Economic Area (EEA) under the age
  /// of consent.
  static final int yes = 1;

  /// Tag for NOT child directed treatment.
  ///
  /// Indicates the publisher specified that the ad request should not receive
  /// treatment for users in the European Economic Area (EEA) under the age
  /// of consent.
  static final int no = 0;

  /// Do not specify tag for child directed treatment.
  ///
  /// Indicates that the publisher has not specified whether the ad request
  /// should receive treatment for users in the European Economic Area (EEA)
  /// under the age of consent.
  static final int unspecified = -1;
}
