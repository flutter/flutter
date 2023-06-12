// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  group('$RecaptchaVerifierFactoryPlatform()', () {
    late TestRecaptchaVerifierFactoryPlatform recaptchaVerifierFactoryPlatform;

    setUpAll(() async {
      recaptchaVerifierFactoryPlatform = TestRecaptchaVerifierFactoryPlatform();
    });

    test('Constructor', () {
      expect(recaptchaVerifierFactoryPlatform,
          isA<RecaptchaVerifierFactoryPlatform>());
      expect(recaptchaVerifierFactoryPlatform, isA<PlatformInterface>());
    });

    group('set.instance', () {
      test('sets current instance', () {
        try {
          RecaptchaVerifierFactoryPlatform.instance =
              recaptchaVerifierFactoryPlatform;
        } catch (_) {
          fail('thrown an unexpected error');
        }
      });
    });

    test('get.instance', () {
      try {
        RecaptchaVerifierFactoryPlatform.instance =
            recaptchaVerifierFactoryPlatform;
        final result = RecaptchaVerifierFactoryPlatform.instance;
        expect(result, isA<RecaptchaVerifierFactoryPlatform>());
      } catch (_) {
        fail('thrown an unexpected error');
      }
    });

    group('verify()', () {
      test('calls successfully', () {
        try {
          RecaptchaVerifierFactoryPlatform.verifyExtends(
              recaptchaVerifierFactoryPlatform);
          return;
        } catch (_) {
          fail('thrown an unexpected exception');
        }
      });
    });

    test('throws if delegate', () async {
      try {
        await recaptchaVerifierFactoryPlatform.delegate;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('delegate is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    group('delegateFor()', () {
      test('throws UnimplementedError error', () async {
        try {
          recaptchaVerifierFactoryPlatform.delegateFor(
            auth: FirebaseAuthPlatform.instance,
          );
        } on UnimplementedError catch (e) {
          expect(e.message, equals('delegateFor() is not implemented'));
          return;
        }
        fail('Should have thrown an [UnimplementedError]');
      });
    });

    test('throws if type', () async {
      try {
        recaptchaVerifierFactoryPlatform.type;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('type is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if clear()', () async {
      try {
        recaptchaVerifierFactoryPlatform.clear();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('clear() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if render()', () async {
      try {
        await recaptchaVerifierFactoryPlatform.render();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('render() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if verify()', () async {
      try {
        await recaptchaVerifierFactoryPlatform.verify();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('verify() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}

class TestRecaptchaVerifierFactoryPlatform
    extends RecaptchaVerifierFactoryPlatform {
  TestRecaptchaVerifierFactoryPlatform() : super();
}
