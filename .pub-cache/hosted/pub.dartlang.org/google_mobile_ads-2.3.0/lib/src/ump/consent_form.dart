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

import 'form_error.dart';
import 'user_messaging_channel.dart';

/// Callback to be invoked when a consent form is dismissed.
///
/// An optional [FormError] is provided if an error occurred.
typedef OnConsentFormDismissedListener = void Function(FormError? formError);

/// Callback to be invoked when a consent form loads successfully
typedef OnConsentFormLoadSuccessListener = void Function(
    ConsentForm consentForm);

/// Callback to be invoked when a consent form failed to load.
typedef OnConsentFormLoadFailureListener = void Function(FormError formError);

/// A rendered form for collecting consent from a user.
abstract class ConsentForm {
  /// Shows the consent form.
  void show(OnConsentFormDismissedListener onConsentFormDismissedListener);

  /// Free platform resources associated with this object.
  ///
  /// Returns a future that completes when the platform resources are freed.
  Future<void> dispose();

  /// Loads a ConsentForm.
  ///
  /// Check that [ConsentInformation.isConsentFormAvailable()] returns true
  /// prior to calling this method.
  static void loadConsentForm(OnConsentFormLoadSuccessListener successListener,
      OnConsentFormLoadFailureListener failureListener) {
    UserMessagingChannel.instance
        .loadConsentForm(successListener, failureListener);
  }
}
