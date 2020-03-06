// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

// A comment used to identify the export line added for Linux and macOS.
const String kExportHeader = '# Added for Flutter & Dart Support';

/// A command to automatically add Flutter to the PATH of users.
class AddToPathCommand extends FlutterCommand {
  AddToPathCommand({
    @required Platform platform,
    @required Logger logger,
    @required FileSystem fileSystem,
  }) : _logger = logger,
       _platform = platform,
       _fileSystem = fileSystem;

  Logger _logger;
  Platform _platform;
  FileSystem _fileSystem;

  @override
  String get description => 'Automatically adds Flutter & Dart to the PATH';

  @override
  String get name => 'add-to-path';

  @override
  Future<FlutterCommandResult> runCommand() async {
    _logger ??= globals.logger;
    _platform ??= globals.platform;
    _fileSystem ??= globals.fs;

    final String flutterBinPath = _fileSystem.path.join(Cache.flutterRoot, 'bin');

    if (_platform.isLinux || _platform.isMacOS) {
      final String homePath = _platform.environment['HOME'];
      final List<File> searchPriority = <File>[
        _fileSystem.file(_fileSystem.path.join(homePath, '.zshrc')),
        _fileSystem.file(_fileSystem.path.join(homePath, '.bashrc')),
        _fileSystem.file(_fileSystem.path.join(homePath, '.bash_profile')),
        _fileSystem.file(_fileSystem.path.join(homePath, '.profile')),
      ];
      bool addedOnce = false;
      for (final File searchFile in searchPriority) {
        if (!searchFile.existsSync()) {
          continue;
        }
        if (searchFile.readAsStringSync().contains(kExportHeader)) {
          _logger.printStatus('Flutter already present in ${searchFile.path}');
          continue;
        }
        try {
          searchFile.writeAsStringSync(
            '\n$kExportHeader\n'
            'export PATH=\$PATH:$flutterBinPath\n',
            mode: FileMode.append,
          );
          addedOnce = true;
        } on FileSystemException catch (err) {
          _logger.printTrace('Failed to append to ${searchFile.path}: $err');
        }
      }
      if (addedOnce) {
          _logger.printStatus(
          'Successfully added Flutter to PATH. You may need to start a '
          'new terminal shell to use it.',
        );
        return FlutterCommandResult.success();
      }
      throwToolExit('Unable to add Flutter to PATH');
    }
    throwToolExit('${_platform.operatingSystem} is not supported by "flutter add-to-path"');
    return null;
  }
}
