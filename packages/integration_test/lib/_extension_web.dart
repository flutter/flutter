// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js';
import 'dart:js_util' as js_util;

/// The web implementation of [registerWebServiceExtension].
///
/// Adds a hidden `window.$flutterDriver` JavaScript function that's called by
/// `FlutterWebDriver` to fulfill FlutterDriver commands.
///
/// See also:
///
///  * `_extension_io.dart`, which has the dart:io implementation
void registerWebServiceExtension(
    Future<Map<String, dynamic>> Function(Map<String, String>) callback) {
  js_util.setProperty(html.window, r'$flutterDriver',
      allowInterop((dynamic message) async {
    try {
      final Map<String, dynamic> messageJson = jsonDecode(message as String) as Map<String, dynamic>;
      final Map<String, String> params = messageJson.cast<String, String>();
      final Map<String, dynamic> result = await callback(params);
      context[r'$flutterDriverResult'] = json.encode(result);
    } catch (error, stackTrace) {
      // Encode the error in the same format the FlutterDriver extension uses.
      //
      // See:
      //   * packages\flutter_driver\lib\src\extension\extension.dart
      context[r'$flutterDriverResult'] = json.encode(<String, dynamic>{
        'isError': true,
        'response': '$error\n$stackTrace',
      });
    }
  }));
}
