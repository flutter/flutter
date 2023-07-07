// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_identity_services_web/src/js_interop/dom.dart' as dom;
import 'package:js/js_util.dart' as js_util;

/// Injects a `<meta>` tag with the provided [attributes] into the [dom.document].
void injectMetaTag(Map<String, String> attributes) {
  final dom.DomHtmlElement meta = dom.document.createElement('meta');
  for (final MapEntry<String, String> attribute in attributes.entries) {
    js_util.callMethod(
      meta,
      'setAttribute',
      <String>[attribute.key, attribute.value],
    );
  }
  dom.document.head.appendChild(meta);
}
