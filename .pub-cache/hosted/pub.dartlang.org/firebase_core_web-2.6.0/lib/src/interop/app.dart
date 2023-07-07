// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:firebase_core_web/firebase_core_web_interop.dart';

import 'core.dart' as core_interop;

/// A Firebase App holds the initialization information for a collection
/// of services.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.app>.
class App extends JsObjectWrapper<AppJsImpl> {
  App._fromJsObject(AppJsImpl jsObject) : super.fromJsObject(jsObject);

  static final _expando = Expando<App>();

  /// Name of the app.
  String get name => jsObject.name;

  /// Options used during [firebase.initializeApp()].
  FirebaseOptions get options => jsObject.options;

  /// Creates a new App from a [jsObject].
  static App getInstance(AppJsImpl jsObject) {
    return _expando[jsObject] ??= App._fromJsObject(jsObject);
  }

  /// Deletes the app and frees resources of all App's services.
  Future<void> delete() => handleThenable(core_interop.deleteApp(jsObject));
}
