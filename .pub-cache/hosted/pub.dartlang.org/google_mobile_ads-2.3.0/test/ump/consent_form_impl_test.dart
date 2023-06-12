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
import 'package:google_mobile_ads/src/ump/form_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'consent_form_impl_test.mocks.dart';

@GenerateMocks([UserMessagingChannel])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsentFormImpl', () {
    late MockUserMessagingChannel mockChannel;

    setUp(() async {
      mockChannel = MockUserMessagingChannel();
      UserMessagingChannel.instance = mockChannel;
    });

    test('show() success', () async {
      when(mockChannel.show(any, any)).thenAnswer((realInvocation) {
        realInvocation.positionalArguments[1](null);
      });
      ConsentFormImpl form = ConsentFormImpl(1);
      Completer<FormError?> errorCompleter = Completer<FormError?>();

      form.show((formError) => errorCompleter.complete(formError));

      FormError? error = await errorCompleter.future;

      expect(errorCompleter.isCompleted, true);
      expect(error, null);
    });

    test('show() failure', () async {
      FormError error = FormError(errorCode: 1, message: 'msg');
      when(mockChannel.show(any, any)).thenAnswer((realInvocation) {
        realInvocation.positionalArguments[1](error);
      });
      ConsentFormImpl form = ConsentFormImpl(1);
      Completer<FormError?> errorCompleter = Completer<FormError?>();

      form.show((formError) => errorCompleter.complete(formError));

      FormError? completedError = await errorCompleter.future;

      expect(errorCompleter.isCompleted, true);
      expect(error, completedError);
    });

    test('dispose()', () async {
      ConsentFormImpl form = ConsentFormImpl(1);

      when(mockChannel.disposeConsentForm(form))
          .thenAnswer((realInvocation) => Future.value());

      await form.dispose();
      verify(mockChannel.disposeConsentForm(form));
    });
  });
}
