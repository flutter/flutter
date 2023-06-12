// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

/// Creates a script that will run properly when strict CSP is enforced.
///
/// More specifically, the script has the correct `nonce` value set.
final ScriptElement Function() _createScript = (() {
  final nonce = _findNonce();
  if (nonce == null) return () => ScriptElement();

  return () => ScriptElement()..setAttribute('nonce', nonce);
})();

// According to the CSP3 spec a nonce must be a valid base64 string.
final _noncePattern = RegExp('^[\\w+/_-]+[=]{0,2}\$');

/// Returns CSP nonce, if set for any script tag.
String? _findNonce() {
  final elements = window.document.querySelectorAll('script');
  for (final element in elements) {
    final nonceValue =
        (element as HtmlElement).nonce ?? element.attributes['nonce'];
    if (nonceValue != null && _noncePattern.hasMatch(nonceValue)) {
      return nonceValue;
    }
  }
  return null;
}

/// Runs `window.$dartRunMain()` by injecting a script tag.
///
/// We do this so that we don't see user exceptions bubble up in our own error
/// handling zone.
void runMain() {
  final scriptElement = _createScript()..innerHtml = r'window.$dartRunMain();';
  document.body!.append(scriptElement);
  Future.microtask(scriptElement.remove);
}
