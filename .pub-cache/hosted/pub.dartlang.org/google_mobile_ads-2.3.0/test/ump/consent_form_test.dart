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

import 'package:google_mobile_ads/src/ump/consent_form.dart';
import 'package:google_mobile_ads/src/ump/consent_form_impl.dart';
import 'package:google_mobile_ads/src/ump/form_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'consent_form_test.mocks.dart';

@GenerateMocks([UserMessagingChannel])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsentForm', () {
    late MockUserMessagingChannel mockChannel;

    setUp(() async {
      mockChannel = MockUserMessagingChannel();
      UserMessagingChannel.instance = mockChannel;
    });

    test('loadConsentForm() success', () async {
      ConsentForm form = ConsentFormImpl(2);

      when(mockChannel.loadConsentForm(any, any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0](form));

      Completer<ConsentForm> successCompleter = Completer<ConsentForm>();
      Completer<FormError> errorCompleter = Completer<FormError>();

      ConsentForm.loadConsentForm(
          (consentForm) => successCompleter.complete(consentForm),
          (formError) => errorCompleter.complete(formError));

      ConsentForm responseForm = await successCompleter.future;
      expect(successCompleter.isCompleted, true);
      expect(errorCompleter.isCompleted, false);
      expect(form, responseForm);
    });

    test('loadConsentForm() failure', () async {
      FormError formError = FormError(errorCode: 1, message: 'message');

      when(mockChannel.loadConsentForm(any, any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[1](formError));

      Completer<ConsentForm> successCompleter = Completer<ConsentForm>();
      Completer<FormError> errorCompleter = Completer<FormError>();

      ConsentForm.loadConsentForm(
          (consentForm) => successCompleter.complete(consentForm),
          (formError) => errorCompleter.complete(formError));

      FormError responseError = await errorCompleter.future;
      expect(formError, responseError);
      expect(successCompleter.isCompleted, false);
      expect(errorCompleter.isCompleted, true);
    });
  });
}
