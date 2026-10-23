// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../context/tool_context.dart';

/// Manages a Font configuration that can be shared across multiple tests.
class FontConfigManager {
  FontConfigManager({required this._toolContext});

  final ToolContext _toolContext;
  Directory? _fontsDirectory;

  /// Returns a Font configuration that limits font fallback to the artifact
  /// cache directory.
  late final File fontConfigFile = () {
    final ToolContext(:Cache cache, :FileSystem fs, :Logger logger) = _toolContext;
    if (_fontsDirectory == null) {
      _fontsDirectory = fs.systemTempDirectory.createTempSync('flutter_test_fonts.');
      logger.printTrace('Using this directory for fonts configuration: ${_fontsDirectory!.path}');
    }

    final File cachedFontConfig = fs.file('${_fontsDirectory!.path}/fonts.conf');
    cachedFontConfig.createSync();
    cachedFontConfig.writeAsStringSync('''
<fontconfig>
  <dir>${cache.getCacheArtifacts().path}</dir>
  <cachedir>/var/cache/fontconfig</cachedir>
</fontconfig>
''');
    return cachedFontConfig;
  }();

  Future<void> dispose() async {
    if (_fontsDirectory != null) {
      _toolContext.logger.printTrace('Deleting ${_fontsDirectory!.path}...');
      try {
        await _fontsDirectory!.delete(recursive: true);
      } on FileSystemException {
        // Silently exit
      }
      _fontsDirectory = null;
    }
  }
}
