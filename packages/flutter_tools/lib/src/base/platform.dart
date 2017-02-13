// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:platform/platform.dart';

import 'context.dart';
import 'file_system.dart';

export 'package:platform/platform.dart';

const Platform _kLocalPlatform = const LocalPlatform();
const String _kType = 'platform';

Platform get platform => context == null ? _kLocalPlatform : context[Platform];

/// Enables serialization of the current [platform] to the specified base
/// recording [location].
///
/// Platform metadata will be recorded in a subdirectory of [location] named
/// `"platform"`. It is permissible for [location] to represent an existing
/// non-empty directory as long as there is no collision with the `"platform"`
/// subdirectory.
Future<Null> enableRecordingPlatform(String location) async {
  Directory dir = getRecordingSink(location, _kType);
  File file = _getPlatformManifest(dir);
  await file.writeAsString(platform.toJson(), flush: true);
}

Future<Null> enableReplayPlatform(String location) async {
  Directory dir = getReplaySource(location, _kType);
  File file = _getPlatformManifest(dir);
  String json = await file.readAsString();
  context.setVariable(Platform, new FakePlatform.fromJson(json));
}

File _getPlatformManifest(Directory dir) {
  String path = dir.fileSystem.path.join(dir.path, 'MANIFEST.txt');
  return dir.fileSystem.file(path);
}
