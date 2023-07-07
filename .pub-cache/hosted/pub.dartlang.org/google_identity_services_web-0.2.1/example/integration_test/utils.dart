// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:google_identity_services_web/oauth2.dart';
import 'package:google_identity_services_web/src/js_interop/dom.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('window')
external Object get domWindow;

/// Installs mock-gis.js in the page.
/// Returns a future that completes when the 'load' event of the script fires.
Future<void> installGisMock() {
  final Completer<void> completer = Completer<void>();
  final DomHtmlScriptElement script =
      document.createElement('script') as DomHtmlScriptElement;
  script.src = 'mock-gis.js';
  setProperty(script, 'type', 'module');
  callMethod(script, 'addEventListener', <Object>[
    'load',
    allowInterop((_) {
      completer.complete();
    })
  ]);
  document.head.appendChild(script);
  return completer.future;
}

/// Fakes authorization with the given scopes.
Future<TokenResponse> fakeAuthZWithScopes(List<String> scopes) {
  final StreamController<TokenResponse> controller =
      StreamController<TokenResponse>();
  final TokenClient client = oauth2.initTokenClient(TokenClientConfig(
    client_id: 'for-tests',
    callback: allowInterop(controller.add),
    scope: scopes.join(' '),
  ));
  setMockTokenResponse(client, 'some-non-null-auth-token-value');
  client.requestAccessToken();
  return controller.stream.first;
}

/// Sets a mock TokenResponse value in a [client].
void setMockTokenResponse(TokenClient client, [String? authToken]) {
  callMethod(
    client,
    'setMockTokenResponse',
    <Object?>[authToken],
  );
}

/// Sets a mock credential response in `google.accounts.id`.
void setMockCredentialResponse([String value = 'default_value']) {
  callMethod(
    _getGoogleAccountsId(),
    'setMockCredentialResponse',
    <Object>[value, 'auto'],
  );
}

Object _getGoogleAccountsId() {
  return _getDeepProperty<Object>(domWindow, 'google.accounts.id');
}

// Attempts to retrieve a deeply nested property from a jsObject (or die tryin')
T _getDeepProperty<T>(Object jsObject, String deepProperty) {
  final List<String> properties = deepProperty.split('.');
  return properties.fold(
    jsObject,
    (Object jsObj, String prop) => getProperty<Object>(jsObj, prop),
  ) as T;
}
