// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:js/js.dart' show allowInterop;

import 'js_interop/dom.dart';
import 'js_interop/load_callback.dart';

// The URL from which the script should be downloaded.
const String _url = 'https://accounts.google.com/gsi/client';

// The default TrustedPolicy name that will be used to inject the script.
const String _defaultTrustedPolicyName = 'gis-dart';

/// Loads the GIS SDK for web, using Trusted Types API when available.
Future<void> loadWebSdk({
  DomHtmlElement? target,
  String trustedTypePolicyName = _defaultTrustedPolicyName,
}) {
  final Completer<void> completer = Completer<void>();
  onGoogleLibraryLoad = allowInterop(() => completer.complete());

  // If TrustedTypes are available, prepare a trusted URL.
  DomTrustedScriptUrl? trustedUrl;
  if (trustedTypes != null) {
    console.debug(
      'TrustedTypes available. Creating policy:',
      trustedTypePolicyName,
    );
    final DomTrustedTypePolicyFactory factory = trustedTypes!;
    try {
      final DomTrustedTypePolicy policy = factory.createPolicy(
          trustedTypePolicyName,
          DomTrustedTypePolicyOptions(
            createScriptURL: allowInterop((String url) => _url),
          ));
      trustedUrl = policy.createScriptURL(_url);
    } catch (e) {
      throw TrustedTypesException(e.toString());
    }
  }

  final DomHtmlScriptElement script =
      document.createElement('script') as DomHtmlScriptElement
        ..src = trustedUrl ?? _url
        ..async = true
        ..defer = true;

  (target ?? document.head).appendChild(script);

  return completer.future;
}

/// Exception thrown if the Trusted Types feature is supported, enabled, and it
/// has prevented this loader from injecting the JS SDK.
class TrustedTypesException implements Exception {
  ///
  TrustedTypesException(this.message);

  /// The message of the exception
  final String message;
  @override
  String toString() => 'TrustedTypesException: $message';
}
