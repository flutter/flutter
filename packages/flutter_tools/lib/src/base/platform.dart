// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:platform/platform.dart';

import 'context.dart';
import 'file_system.dart';

export 'package:platform/platform.dart';

const Platform _kLocalPlatform = LocalPlatform();
const String _kRecordingType = 'platform';

Platform get platform => context[Platform] ?? _kLocalPlatform;

/// Serializes the current [platform] to the specified base recording
/// [location].
///
/// Platform metadata will be recorded in a subdirectory of [location] named
/// `"platform"`. It is permissible for [location] to represent an existing
/// non-empty directory as long as there is no collision with the `"platform"`
/// subdirectory.
///
/// Returns the existing platform.
Future<Platform> getRecordingPlatform(String location) async {
  final Directory dir = getRecordingSink(location, _kRecordingType);
  final File file = _getPlatformManifest(dir);
  await file.writeAsString(platform.toJson(), flush: true);
  return platform;
}

Future<FakePlatform> getReplayPlatform(String location) async {
  final Directory dir = getReplaySource(location, _kRecordingType);
  final File file = _getPlatformManifest(dir);
  final String json = await file.readAsString();
  return FakePlatform.fromJson(json);
}

File _getPlatformManifest(Directory dir) {
  final String path = dir.fileSystem.path.join(dir.path, 'MANIFEST.txt');
  return dir.fileSystem.file(path);
}
