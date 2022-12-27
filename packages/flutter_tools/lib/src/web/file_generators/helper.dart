// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import '../../base/platform.dart';
import '../../base/user_messages.dart';
import '../../cache.dart';

String get _flutterRoot => Cache.defaultFlutterRoot(
      platform: const LocalPlatform(),
      fileSystem: const LocalFileSystem(),
      userMessages: UserMessages(),
    );

final String fileGeneratorsRoot = path.join(
  _flutterRoot,
  'packages',
  'flutter_tools',
  'lib',
  'src',
  'web',
  'file_generators',
);
