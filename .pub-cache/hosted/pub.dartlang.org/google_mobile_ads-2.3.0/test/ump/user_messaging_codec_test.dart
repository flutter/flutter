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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ump/consent_form_impl.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserMessagingCodec', () {
    /// Sut.
    final UserMessagingCodec codec = UserMessagingCodec();

    test('encode and decode empty ConsentRequestParameters', () async {
      ConsentRequestParameters params = ConsentRequestParameters();
      final ByteData? byteData = codec.encodeMessage(params);
      ConsentRequestParameters decodedParams = codec.decodeMessage(byteData);
      expect(params, decodedParams);
    });

    test('encode and decode empty ConsentDebugSettings', () async {
      ConsentDebugSettings debugSettings = ConsentDebugSettings();
      ByteData? byteData = codec.encodeMessage(debugSettings);
      ConsentDebugSettings decodedDebugSettings = codec.decodeMessage(byteData);
      expect(debugSettings, decodedDebugSettings);
    });

    test('encode and decode ConsentDebugSettings only geography', () async {
      ConsentDebugSettings debugSettings = ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyDisabled);
      ByteData? byteData = codec.encodeMessage(debugSettings);
      ConsentDebugSettings decodedDebugSettings = codec.decodeMessage(byteData);
      expect(debugSettings, decodedDebugSettings);
    });

    test('encode and decode ConsentDebugSettings only testIds', () async {
      ConsentDebugSettings debugSettings = ConsentDebugSettings(
          testIdentifiers: ['test-identifier1', 'test-identifier2']);
      ByteData? byteData = codec.encodeMessage(debugSettings);
      ConsentDebugSettings decodedDebugSettings = codec.decodeMessage(byteData);
      expect(debugSettings, equals(decodedDebugSettings));
    });

    test('encode and decode ConsentDebugSettings testIds and geo', () async {
      ConsentDebugSettings debugSettings = ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
          testIdentifiers: ['test-identifier1', 'test-identifier2']);
      ByteData? byteData = codec.encodeMessage(debugSettings);
      ConsentDebugSettings decodedDebugSettings = codec.decodeMessage(byteData);
      expect(debugSettings, equals(decodedDebugSettings));
    });

    test('encode and decode ConsentForm', () async {
      ConsentFormImpl consentFormImpl = ConsentFormImpl(1);
      ByteData? byteData = codec.encodeMessage(consentFormImpl);
      ConsentForm decodedConsentForm = codec.decodeMessage(byteData);
      expect(decodedConsentForm, equals(consentFormImpl));
    });
  });
}
