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

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ump/consent_information_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'consent_information_impl_test.mocks.dart';

@GenerateMocks([UserMessagingChannel])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsentInformationImpl', () {
    late MockUserMessagingChannel mockChannel;
    late ConsentInformationImpl consentInfo;

    setUp(() async {
      mockChannel = MockUserMessagingChannel();
      UserMessagingChannel.instance = mockChannel;
      consentInfo = ConsentInformationImpl();
    });

    test('reset()', () async {
      when(mockChannel.reset()).thenAnswer((_) => Future<void>.value());

      await consentInfo.reset();

      verify(mockChannel.reset());
    });

    test('getConsentStatus()', () async {
      ConsentStatus status = ConsentStatus.required;
      when(mockChannel.getConsentStatus())
          .thenAnswer((_) => Future.value(status));

      ConsentStatus responseStatus = await consentInfo.getConsentStatus();

      verify(mockChannel.getConsentStatus());
      expect(responseStatus, status);
    });

    test('isConsentFormAvailable()', () async {
      when(mockChannel.isConsentFormAvailable())
          .thenAnswer((_) => Future.value(false));

      bool isConsentFormAvailable = await consentInfo.isConsentFormAvailable();

      verify(mockChannel.isConsentFormAvailable());
      expect(isConsentFormAvailable, false);
    });

    test('requestConsentInfoUpdate() success', () async {
      when(mockChannel.requestConsentInfoUpdate(any, any, any))
          .thenAnswer((invocation) {
        invocation.positionalArguments[1]();
      });

      ConsentRequestParameters params = ConsentRequestParameters();
      Completer<void> successCompleter = Completer<void>();
      Completer<FormError> errorCompleter = Completer<FormError>();

      consentInfo.requestConsentInfoUpdate(
          params,
          () => successCompleter.complete(),
          (error) => errorCompleter.complete(error));

      await successCompleter.future;
      verify(mockChannel.requestConsentInfoUpdate(params, any, any));
      expect(successCompleter.isCompleted, true);
      expect(errorCompleter.isCompleted, false);
    });

    test('requestConsentInfoUpdate() failure', () async {
      FormError formError = FormError(errorCode: 1, message: 'msg');
      when(mockChannel.requestConsentInfoUpdate(any, any, any))
          .thenAnswer((invocation) {
        invocation.positionalArguments[2](formError);
      });

      ConsentRequestParameters params = ConsentRequestParameters();
      Completer<void> successCompleter = Completer<void>();
      Completer<FormError> errorCompleter = Completer<FormError>();

      consentInfo.requestConsentInfoUpdate(
          params,
          () => successCompleter.complete(),
          (error) => errorCompleter.complete(error));

      FormError responseError = await errorCompleter.future;
      verify(mockChannel.requestConsentInfoUpdate(params, any, any));
      expect(successCompleter.isCompleted, false);
      expect(errorCompleter.isCompleted, true);
      expect(responseError, formError);
    });
  });
}
