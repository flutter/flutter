// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show File;

import 'package:path/path.dart' as path;

import '../utils.dart';

Future<void> realmCheckerTestRunner() async {
  final String engineRealmFile = path.join(flutterRoot, 'bin', 'internal', 'engine.realm');

  final String engineRealm = File(engineRealmFile).readAsStringSync().trim();
  if (engineRealm.isNotEmpty) {
    foundError(<String>['The checked-in engine.realm file must be empty.']);
  }
}
