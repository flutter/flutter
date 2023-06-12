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

import 'package:google_mobile_ads/src/ump/consent_information_impl.dart';

import 'consent_request_parameters.dart';
import 'form_error.dart';

/// Callback to be invoked when consent info is successfully updated.
typedef OnConsentInfoUpdateSuccessListener = void Function();

/// Callback to be invoked when consent info failed to update.
typedef OnConsentInfoUpdateFailureListener = void Function(FormError error);

/// Consent status values.
enum ConsentStatus {
  /// User consent not required.
  notRequired,

  /// User consent obtained.
  obtained,

  /// User consent required but not yet obtained.
  required,

  /// Consent status is unknown.
  unknown,
}

/// Utility methods for collecting consent from users.
abstract class ConsentInformation {
  /// Requests a consent information update.
  void requestConsentInfoUpdate(
      ConsentRequestParameters params,
      OnConsentInfoUpdateSuccessListener successListener,
      OnConsentInfoUpdateFailureListener failureListener);

  /// Returns true if a ConsentForm is available, false otherwise.
  Future<bool> isConsentFormAvailable();

  /// Get the user’s consent status.
  ///
  /// This value is cached between app sessions and can be read before
  /// requesting updated parameters.
  Future<ConsentStatus> getConsentStatus();

  /// Resets the consent information to initialized status.
  ///
  /// Should only be used for testing. Returns a [Future] that completes when
  /// the platform API has been called.
  Future<void> reset();

  /// The static [ConsentInformation] instance.
  static ConsentInformation instance = ConsentInformationImpl();
}
