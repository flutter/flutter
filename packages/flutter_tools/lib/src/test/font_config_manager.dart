// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';

/// Manages a Font configuration that can be shared across multiple tests.
class FontConfigManager {
  FontConfigManager({required this._cache, required this._fileSystem, required this._logger});

  final Cache _cache;
  final FileSystem _fileSystem;
  final Logger _logger;
  Directory? _fontsDirectory;

  /// Returns a Font configuration that limits font fallback to the artifact
  /// cache directory.
  late final File fontConfigFile = () {
    if (_fontsDirectory == null) {
      _fontsDirectory = _fileSystem.systemTempDirectory.createTempSync('flutter_test_fonts.');
      _logger.printTrace('Using this directory for fonts configuration: ${_fontsDirectory!.path}');
    }

    final File cachedFontConfig = _fileSystem.file('${_fontsDirectory!.path}/fonts.conf');
    cachedFontConfig.createSync();
    cachedFontConfig.writeAsStringSync('''
<fontconfig>
  <dir>${_cache.getCacheArtifacts().path}</dir>
  <cachedir>/var/cache/fontconfig</cachedir>
</fontconfig>
''');
    return cachedFontConfig;
  }();

  Future<void> dispose() async {
    if (_fontsDirectory != null) {
      _logger.printTrace('Deleting ${_fontsDirectory!.path}...');
      try {
        await _fontsDirectory!.delete(recursive: true);
      } on FileSystemException {
        // Silently exit
      }
      _fontsDirectory = null;
    }
  }
}
