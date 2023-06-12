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

import 'consent_form.dart';
import 'user_messaging_channel.dart';

/// Implementation for [ConsentForm],
class ConsentFormImpl extends ConsentForm {
  /// Construct a [ConsentFormImpl].
  ConsentFormImpl(this.platformHash);

  /// Identifier to the underlying platform object.
  final int platformHash;

  @override
  void show(OnConsentFormDismissedListener onConsentFormDismissedListener) {
    UserMessagingChannel.instance.show(this, onConsentFormDismissedListener);
  }

  @override
  Future<void> dispose() {
    return UserMessagingChannel.instance.disposeConsentForm(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConsentFormImpl && platformHash == other.platformHash;
  }
}
