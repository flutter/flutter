// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
import 'dart:js' as js;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:js/js_util.dart' as js_util;

import 'mock/firebase_mock.dart';

void main() {
  group('no default app', () {
    setUp(() async {
      FirebasePlatform.instance = FirebaseCoreWeb();
    });

    test(
        'should throw exception if no default app is available & no options are provided',
        () async {
      await expectLater(
        Firebase.initializeApp,
        throwsAssertionError,
      );
    });
  });

  group('.initializeApp()', () {
    setUp(() async {
      FirebasePlatform.instance = FirebaseCoreWeb();
    });

    group('secondary apps', () {
      test('should throw exception if no options are provided with a named app',
          () async {
        await expectLater(
          () => Firebase.initializeApp(name: 'foo'),
          throwsAssertionError,
        );
      });
    });
  });

  group('.app()', () {
    setUp(() async {
      firebaseMock = FirebaseMock(app: js.allowInterop((String name) {
        final dynamic error = js_util.newObject();
        js_util.setProperty(error, 'name', 'FirebaseError');
        js_util.setProperty(error, 'code', 'app/no-app');
        throw error;
      }));
      FirebasePlatform.instance = FirebaseCoreWeb();
    });

    test('should throw exception if no named app was found', () async {
      (js.context['firebase_core'] as js.JsObject)['getApp'] =
          js.allowInterop((String name) {
        final dynamic error = js_util.newObject();
        js_util.setProperty(error, 'name', 'FirebaseError');
        js_util.setProperty(error, 'code', 'app/no-app');
        throw error;
      });

      await expectLater(
        () => Firebase.app('foo'),
        throwsA(noAppExists('foo')),
      );
    });
  });
}
