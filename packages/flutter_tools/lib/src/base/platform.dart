// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';

import 'context.dart';
import 'file_system.dart';

export 'package:platform/platform.dart';

const Platform _kLocalPlatform = LocalPlatform();
const String _kRecordingType = 'platform';

Platform get platform => context.get<Platform>() ?? _kLocalPlatform;

/// Serializes the current [platform] to the specified base recording
/// [location].
///
/// Platform metadata will be recorded in a subdirectory of [location] named
/// `"platform"`. It is permissible for [location] to represent an existing
/// non-empty directory as long as there is no collision with the `"platform"`
/// subdirectory.
///
/// Returns the existing platform.
Platform getRecordingPlatform(String location) {
  final Directory dir = getRecordingSink(location, _kRecordingType);
  final File file = _getPlatformManifest(dir);
  file.writeAsStringSync(platform.toJson(), flush: true);
  return platform;
}

FakePlatform getReplayPlatform(String location) {
  final Directory dir = getReplaySource(location, _kRecordingType);
  final File file = _getPlatformManifest(dir);
  final String json = file.readAsStringSync();
  return FakePlatform.fromJson(json);
}

File _getPlatformManifest(Directory dir) {
  final String path = dir.fileSystem.path.join(dir.path, 'MANIFEST.txt');
  return dir.fileSystem.file(path);
}
