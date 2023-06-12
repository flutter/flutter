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
import 'package:flutter/services.dart';

import 'consent_form.dart';
import 'consent_information.dart';
import 'consent_request_parameters.dart';
import 'form_error.dart';
import 'user_messaging_codec.dart';

/// Platform channel for UMP SDK.
class UserMessagingChannel {
  static const _methodChannelName = 'plugins.flutter.io/google_mobile_ads/ump';

  /// Create a [UserMessagingChannel] with the [channel].
  UserMessagingChannel(MethodChannel channel) : _methodChannel = channel;

  /// The shared [UserMessagingChannel] instance.
  static UserMessagingChannel instance = UserMessagingChannel(MethodChannel(
      _methodChannelName, StandardMethodCodec(UserMessagingCodec())));

  final MethodChannel _methodChannel;

  /// Request a consent information update with [params].
  ///
  /// Invokes [successListener] or [failureListener] depending on if there was
  /// an error.
  void requestConsentInfoUpdate(
      ConsentRequestParameters params,
      OnConsentInfoUpdateSuccessListener successListener,
      OnConsentInfoUpdateFailureListener failureListener) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'ConsentInformation#requestConsentInfoUpdate',
        <dynamic, dynamic>{
          'params': params,
        },
      );
      successListener();
    } on PlatformException catch (e) {
      failureListener(_formErrorFromPlatformException(e));
    }
  }

  /// Returns a future indicating whether a consent form is available.
  Future<bool> isConsentFormAvailable() async {
    return (await _methodChannel
        .invokeMethod<bool>('ConsentInformation#isConsentFormAvailable'))!;
  }

  /// Gets the consent status.
  Future<ConsentStatus> getConsentStatus() async {
    int consentStatus = (await _methodChannel
        .invokeMethod<int>('ConsentInformation#getConsentStatus'))!;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      switch (consentStatus) {
        case 0:
          return ConsentStatus.unknown;
        case 1:
          return ConsentStatus.required;
        case 2:
          return ConsentStatus.notRequired;
        case 3:
          return ConsentStatus.obtained;
        default:
          debugPrint('Error: unknown ConsentStatus value: $consentStatus');
          return ConsentStatus.unknown;
      }
    } else {
      switch (consentStatus) {
        case 0:
          return ConsentStatus.unknown;
        case 1:
          return ConsentStatus.notRequired;
        case 2:
          return ConsentStatus.required;
        case 3:
          return ConsentStatus.obtained;
        default:
          debugPrint('Error: unknown ConsentStatus value: $consentStatus');
          return ConsentStatus.unknown;
      }
    }
  }

  /// Invokes reset API,
  Future<void> reset() async {
    return _methodChannel.invokeMethod<void>('ConsentInformation#reset');
  }

  /// Loads a consent form and calls the corresponding listener.
  void loadConsentForm(OnConsentFormLoadSuccessListener successListener,
      OnConsentFormLoadFailureListener failureListener) async {
    try {
      ConsentForm form = (await _methodChannel
          .invokeMethod<ConsentForm>('UserMessagingPlatform#loadConsentForm'))!;
      successListener(form);
    } on PlatformException catch (e) {
      failureListener(_formErrorFromPlatformException(e));
    }
  }

  /// Show the consent form.
  void show(ConsentForm consentForm,
      OnConsentFormDismissedListener onConsentFormDismissedListener) async {
    try {
      await _methodChannel.invokeMethod<FormError?>(
        'ConsentForm#show',
        <dynamic, dynamic>{
          'consentForm': consentForm,
        },
      );
      onConsentFormDismissedListener(null);
    } on PlatformException catch (e) {
      onConsentFormDismissedListener(_formErrorFromPlatformException(e));
    }
  }

  FormError _formErrorFromPlatformException(PlatformException e) {
    return FormError(
        errorCode: int.tryParse(e.code) ?? -1, message: e.message ?? '');
  }

  /// Free platform resources associated with the [ConsentForm].
  Future<void> disposeConsentForm(ConsentForm consentForm) {
    return _methodChannel.invokeMethod<void>(
      'ConsentForm#dispose',
      <dynamic, dynamic>{
        'consentForm': consentForm,
      },
    );
  }
}
