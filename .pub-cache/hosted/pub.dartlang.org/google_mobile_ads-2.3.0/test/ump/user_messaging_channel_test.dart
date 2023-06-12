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

import 'package:google_mobile_ads/src/ump/consent_form_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserMessagingChannel', () {
    late MethodChannel methodChannel;
    late UserMessagingChannel channel;
    setUp(() async {
      methodChannel = MethodChannel(
          'test-channel', StandardMethodCodec(UserMessagingCodec()));
      channel = UserMessagingChannel(methodChannel);
    });

    test('requestConsentInfoUpdate() success', () async {
      ConsentRequestParameters params = ConsentRequestParameters(
          tagForUnderAgeOfConsent: true,
          consentDebugSettings: ConsentDebugSettings());

      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(
            call.method, equals('ConsentInformation#requestConsentInfoUpdate'));
        expect(call.arguments, equals({'params': params}));
        return Future<dynamic>.value();
      });

      Completer<void> successCompleter = Completer<void>();
      Completer<FormError> failureCompleter = Completer<FormError>();
      // Test function
      channel.requestConsentInfoUpdate(params, () {
        successCompleter.complete();
      }, (error) {
        failureCompleter.complete(error);
      });
      await successCompleter.future;

      expect(successCompleter.isCompleted, true);
      expect(failureCompleter.isCompleted, false);
    });

    test('requestConsentInfoUpdate() failure', () async {
      ConsentRequestParameters params = ConsentRequestParameters(
          tagForUnderAgeOfConsent: true,
          consentDebugSettings: ConsentDebugSettings());

      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(
            call.method, equals('ConsentInformation#requestConsentInfoUpdate'));
        expect(call.arguments, equals({'params': params}));
        return Future.error(PlatformException(
            code: '1', message: 'message', details: 'details'));
      });

      Completer<void> successCompleter = Completer<void>();
      Completer<FormError> failureCompleter = Completer<FormError>();

      // Test function
      channel.requestConsentInfoUpdate(
        params,
        () {
          successCompleter.complete();
        },
        (error) {
          failureCompleter.complete(error);
        },
      );

      FormError error = await failureCompleter.future;
      expect(successCompleter.isCompleted, false);
      expect(failureCompleter.isCompleted, true);
      FormError expectedError = FormError(errorCode: 1, message: 'message');
      expect(error, equals(expectedError));
    });

    test('isConsentFormAvailable() true', () async {
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(
            call.method, equals('ConsentInformation#isConsentFormAvailable'));
        expect(call.arguments, null);
        return Future<dynamic>.value(true);
      });

      bool isAvailable = await channel.isConsentFormAvailable();

      expect(isAvailable, true);
    });

    test('isConsentFormAvailable() false', () async {
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(
            call.method, equals('ConsentInformation#isConsentFormAvailable'));
        expect(call.arguments, null);
        return Future<dynamic>.value(false);
      });

      bool isAvailable = await channel.isConsentFormAvailable();

      expect(isAvailable, false);
    });

    test('getConsentStatus()', () async {
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(call.method, equals('ConsentInformation#getConsentStatus'));
        expect(call.arguments, null);
        return Future<dynamic>.value(1);
      });

      ConsentStatus status = await channel.getConsentStatus();

      expect(status, ConsentStatus.notRequired);
    });

    test('reset()', () async {
      String? method;
      dynamic arguments;
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        method = call.method;
        arguments = call.arguments;
        return Future<void>.value();
      });

      await channel.reset();

      expect(method, equals('ConsentInformation#reset'));
      expect(arguments, null);
    });

    test('loadConsentForm() success', () async {
      String? method;
      dynamic arguments;
      ConsentForm consentForm = ConsentFormImpl(1);
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        method = call.method;
        arguments = call.arguments;
        return Future<dynamic>.value(consentForm);
      });

      Completer<ConsentForm> successCompleter = Completer<ConsentForm>();
      Completer<FormError> failureCompleter = Completer<FormError>();

      // Test function
      channel.loadConsentForm(
          (consentForm) => successCompleter.complete(consentForm),
          (formError) => failureCompleter.complete(formError));

      ConsentForm response = await successCompleter.future;
      expect(successCompleter.isCompleted, true);
      expect(failureCompleter.isCompleted, false);
      expect(method, equals('UserMessagingPlatform#loadConsentForm'));
      expect(arguments, null);
      expect(response, equals(consentForm));
    });

    test('loadConsentForm() error', () async {
      String? method;
      dynamic arguments;
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        method = call.method;
        arguments = call.arguments;
        return Future.error(PlatformException(code: '2', message: 'message'));
      });

      Completer<ConsentForm> successCompleter = Completer<ConsentForm>();
      Completer<FormError> failureCompleter = Completer<FormError>();

      // Test function
      channel.loadConsentForm(
          (consentForm) => successCompleter.complete(consentForm),
          (formError) => failureCompleter.complete(formError));

      FormError error = await failureCompleter.future;
      expect(successCompleter.isCompleted, false);
      expect(failureCompleter.isCompleted, true);
      expect(method, equals('UserMessagingPlatform#loadConsentForm'));
      expect(arguments, null);
      expect(error, FormError(errorCode: 2, message: 'message'));
    });

    test('show() success', () async {
      String? method;
      dynamic arguments;
      ConsentFormImpl consentForm = ConsentFormImpl(1);
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        method = call.method;
        arguments = call.arguments;
        return Future<void>.value();
      });

      Completer<FormError?> successCompleter = Completer<FormError?>();

      // Test function
      channel.show(consentForm, (error) => successCompleter.complete(error));

      FormError? error = await successCompleter.future;
      expect(successCompleter.isCompleted, true);
      expect(method, equals('ConsentForm#show'));
      expect(arguments, {'consentForm': consentForm});
      expect(error, null);
    });

    test('show() error', () async {
      String? method;
      dynamic arguments;
      ConsentFormImpl consentForm = ConsentFormImpl(1);
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        method = call.method;
        arguments = call.arguments;
        return Future.error(PlatformException(code: '55', message: 'msg'));
      });

      Completer<FormError?> successCompleter = Completer<FormError?>();

      // Test function
      channel.show(consentForm, (error) => successCompleter.complete(error));

      FormError? error = await successCompleter.future;
      expect(successCompleter.isCompleted, true);
      expect(method, equals('ConsentForm#show'));
      expect(arguments, {'consentForm': consentForm});
      expect(error, FormError(errorCode: 55, message: 'msg'));
    });

    test('disposeConsentForm()', () async {
      String? method;
      dynamic arguments;
      methodChannel.setMockMethodCallHandler((MethodCall call) async {
        method = call.method;
        arguments = call.arguments;
        return Future<void>.value();
      });

      ConsentForm consentForm = ConsentFormImpl(1);
      await channel.disposeConsentForm(consentForm);

      expect(method, equals('ConsentForm#dispose'));
      expect(arguments, {'consentForm': consentForm});
    });
  });
}
