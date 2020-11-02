// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js';
import 'dart:js_util' as js_util;

/// The dart:html implementation of [registerWebServiceExtension].
///
/// Registers Web Service Extension for Flutter Web application.
///
/// window.$flutterDriver will be called by Flutter Web Driver to process
/// Flutter command.
///
/// See also:
///
///  * [_extension_io.dart], which has the dart:io implementation
void registerWebServiceExtension(
    Future<Map<String, dynamic>> Function(Map<String, String>) call) {
  js_util.setProperty(html.window, '\$flutterDriver',
      allowInterop((dynamic message) async {
    // ignore: undefined_function, undefined_identifier
    final Map<String, String> params = Map<String, String>.from(
        jsonDecode(message as String) as Map<String, dynamic>);
    final Map<String, dynamic> result =
        Map<String, dynamic>.from(await call(params));
    context['\$flutterDriverResult'] = json.encode(result);
  }));
}
