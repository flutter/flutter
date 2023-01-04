// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/platform.dart';
import '../../base/user_messages.dart';
import '../../cache.dart';
import '../../globals.dart' as globals;

String get _flutterRoot => Cache.defaultFlutterRoot(
      fileSystem: globals.localFileSystem,
      platform: const LocalPlatform(),
      userMessages: UserMessages(),
    );

final String fileGeneratorsRoot = globals.localFileSystem.path.join(
  _flutterRoot,
  'packages',
  'flutter_tools',
  'lib',
  'src',
  'web',
  'file_generators',
);
