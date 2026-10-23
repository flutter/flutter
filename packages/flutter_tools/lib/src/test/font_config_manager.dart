// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../context/tool_context.dart';

/// Manages a Font configuration that can be shared across multiple tests.
class FontConfigManager with ToolContextMixin {
  FontConfigManager({required this.toolContext});

  @override
  @protected
  final ToolContext toolContext;
  Directory? _fontsDirectory;

  /// Returns a Font configuration that limits font fallback to the artifact
  /// cache directory.
  late final File fontConfigFile = () {
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
      logger.printTrace('Deleting ${_fontsDirectory!.path}...');
      try {
        await _fontsDirectory!.delete(recursive: true);
      } on FileSystemException {
        // Silently exit
      }
      _fontsDirectory = null;
    }
  }
}
