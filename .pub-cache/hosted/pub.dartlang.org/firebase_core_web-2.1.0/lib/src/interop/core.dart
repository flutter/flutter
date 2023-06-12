// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

import 'app.dart';
import 'core_interop.dart' as firebase_interop;

export 'app.dart';
export 'app_interop.dart';
export 'core_interop.dart';

List<App> get apps => firebase_interop
    .getApps()
    // explicitly typing the param as dynamic to work-around
    // https://github.com/dart-lang/sdk/issues/33537
    // ignore: unnecessary_lambdas
    .map((dynamic e) => App.getInstance(e))
    .toList();

App initializeApp({
  String? apiKey,
  String? authDomain,
  String? databaseURL,
  String? projectId,
  String? storageBucket,
  String? messagingSenderId,
  String? name,
  String? measurementId,
  String? appId,
}) {
  name ??= defaultFirebaseAppName;

  return App.getInstance(
    firebase_interop.initializeApp(
      firebase_interop.FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        databaseURL: databaseURL,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        measurementId: measurementId,
        appId: appId,
      ),
      name,
    ),
  );
}

App app([String? name]) {
  return App.getInstance(
    name != null ? firebase_interop.getApp(name) : firebase_interop.getApp(),
  );
}
