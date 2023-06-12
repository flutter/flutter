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

import 'consent_information.dart';
import 'consent_request_parameters.dart';
import 'user_messaging_channel.dart';

/// Implementation for ConsentInformation.
class ConsentInformationImpl extends ConsentInformation {
  /// Constructor for [ConsentInformationImpl].
  ConsentInformationImpl();

  @override
  void requestConsentInfoUpdate(
      ConsentRequestParameters params,
      OnConsentInfoUpdateSuccessListener successListener,
      OnConsentInfoUpdateFailureListener failureListener) {
    UserMessagingChannel.instance
        .requestConsentInfoUpdate(params, successListener, failureListener);
  }

  @override
  Future<bool> isConsentFormAvailable() {
    return UserMessagingChannel.instance.isConsentFormAvailable();
  }

  @override
  Future<ConsentStatus> getConsentStatus() {
    return UserMessagingChannel.instance.getConsentStatus();
  }

  @override
  Future<void> reset() {
    return UserMessagingChannel.instance.reset();
  }
}
