// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
@Timeout.factor(4)
import 'dart:html';
import 'dart:js' as js;

import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:googleapis_auth/src/oauth2_flows/implicit.dart' as impl;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('gapi-load-failure', () {
    impl.gapiUrl = resource('non_existent.js');
    expect(
      auth.createImplicitBrowserFlow(_clientId, _scopes),
      throwsStateError,
    );
  });

  test('gapi-load-failure--syntax-error', () async {
    impl.gapiUrl = resource('gapi_load_failure.js');

    // Reset test_controller.js's window.onerror registration.
    // This makes sure we can catch the onError callback when the syntax error
    // is produced.
    js.context['onerror'] = null;

    window.onError.listen(expectAsync1((error) {
      error.preventDefault();
    }));

    final sw = Stopwatch()..start();
    try {
      await auth.createImplicitBrowserFlow(_clientId, _scopes);
      fail('expected error');
    } catch (error) {
      final elapsed =
          (sw.elapsed - impl.ImplicitFlow.callbackTimeout).inSeconds;
      expect(elapsed, inInclusiveRange(-3, 3));
    }
  });
}

final _clientId = auth.ClientId('a', 'b');
const _scopes = ['scope1', 'scope2'];
