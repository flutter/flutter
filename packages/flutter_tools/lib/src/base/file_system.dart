// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart' as local_fs;
import 'package:meta/meta.dart';

import 'common.dart' show throwToolExit;
import 'io.dart';
import 'platform.dart';
import 'process.dart';
import 'signals.dart';

// package:file/local.dart must not be exported. This exposes LocalFileSystem,
// which we override to ensure that temporary directories are cleaned up when
// the tool is killed by a signal.
export 'package:file/file.dart';

/// Exception indicating that a file that was expected to exist was not found.
class FileNotFoundException implements IOException {
  const FileNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'File not found: $path';
}

/// Various convenience file system methods.
class FileSystemUtils {
  FileSystemUtils({
    @required FileSystem fileSystem,
    @required Platform platform,
  }) : _fileSystem = fileSystem,
       _platform = platform;

  final FileSystem _fileSystem;

  final Platform _platform;

  /// Create the ancestor directories of a file path if they do not already exist.
  void ensureDirectoryExists(String filePath) {
    final String dirPath = _fileSystem.path.dirname(filePath);
    if (_fileSystem.isDirectorySync(dirPath)) {
      return;
    }
    try {
      _fileSystem.directory(dirPath).createSync(recursive: true);
    } on FileSystemException catch (e) {
      throwToolExit('Failed to create directory "$dirPath": ${e.osError.message}');
    }
  }

  /// Creates `destDir` if needed, then recursively copies `srcDir` to
  /// `destDir`, invoking [onFileCopied], if specified, for each
  /// source/destination file pair.
  ///
  /// Skips files if [shouldCopyFile] returns `false`.
  void copyDirectorySync(
    Directory srcDir,
    Directory destDir, {
    bool shouldCopyFile(File srcFile, File destFile),
    void onFileCopied(File srcFile, File destFile),
  }) {
    if (!srcDir.existsSync()) {
      throw Exception('Source directory "${srcDir.path}" does not exist, nothing to copy');
    }

    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    for (final FileSystemEntity entity in srcDir.listSync()) {
      final String newPath = destDir.fileSystem.path.join(destDir.path, entity.basename);
      if (entity is File) {
        final File newFile = destDir.fileSystem.file(newPath);
        if (shouldCopyFile != null && !shouldCopyFile(entity, newFile)) {
          continue;
        }
        newFile.writeAsBytesSync(entity.readAsBytesSync());
        onFileCopied?.call(entity, newFile);
      } else if (entity is Directory) {
        copyDirectorySync(
          entity,
          destDir.fileSystem.directory(newPath),
          shouldCopyFile: shouldCopyFile,
          onFileCopied: onFileCopied,
        );
      } else {
        throw Exception('${entity.path} is neither File nor Directory');
      }
    }
  }

  /// Appends a number to a filename in order to make it unique under a
  /// directory.
  File getUniqueFile(Directory dir, String baseName, String ext) {
    final FileSystem fs = dir.fileSystem;
    int i = 1;

    while (true) {
      final String name = '${baseName}_${i.toString().padLeft(2, '0')}.$ext';
      final File file = fs.file(_fileSystem.path.join(dir.path, name));
      if (!file.existsSync()) {
        return file;
      }
      i += 1;
    }
  }

  /// Appends a number to a directory name in order to make it unique under a
  /// directory.
  Directory getUniqueDirectory(Directory dir, String baseName) {
    final FileSystem fs = dir.fileSystem;
    int i = 1;

    while (true) {
      final String name = '${baseName}_${i.toString().padLeft(2, '0')}';
      final Directory directory = fs.directory(_fileSystem.path.join(dir.path, name));
      if (!directory.existsSync()) {
        return directory;
      }
      i += 1;
    }
  }

  /// Return a relative path if [fullPath] is contained by the cwd, else return an
  /// absolute path.
  String getDisplayPath(String fullPath) {
    final String cwd = _fileSystem.currentDirectory.path + _fileSystem.path.separator;
    return fullPath.startsWith(cwd) ? fullPath.substring(cwd.length) : fullPath;
  }

  /// Escapes [path].
  ///
  /// On Windows it replaces all '\' with '\\'. On other platforms, it returns the
  /// path unchanged.
  String escapePath(String path) => _platform.isWindows ? path.replaceAll(r'\', r'\\') : path;

  /// Returns true if the file system [entity] has not been modified since the
  /// latest modification to [referenceFile].
  ///
  /// Returns true, if [entity] does not exist.
  ///
  /// Returns false, if [entity] exists, but [referenceFile] does not.
  bool isOlderThanReference({
    @required FileSystemEntity entity,
    @required File referenceFile,
  }) {
    if (!entity.existsSync()) {
      return true;
    }
    return referenceFile.existsSync()
        && referenceFile.statSync().modified.isAfter(entity.statSync().modified);
  }

  /// Return the absolute path of the user's home directory.
  String get homeDirPath {
    String path = _platform.isWindows
      ? _platform.environment['USERPROFILE']
      : _platform.environment['HOME'];
    if (path != null) {
      path = _fileSystem.path.absolute(path);
    }
    return path;
  }
}

/// This class extends [local_fs.LocalFileSystem] in order to clean up
/// directories and files that the tool creates under the system temporary
/// directory when the tool exits either normally or when killed by a signal.
class LocalFileSystem extends local_fs.LocalFileSystem {
  LocalFileSystem._(Signals signals, List<ProcessSignal> fatalSignals) :
    _signals = signals, _fatalSignals = fatalSignals;

  @visibleForTesting
  LocalFileSystem.test({
    @required Signals signals,
    List<ProcessSignal> fatalSignals = Signals.defaultExitSignals,
  }) : this._(signals, fatalSignals);

  // Unless we're in a test of this class's signal hanlding features, we must
  // have only one instance created with the singleton LocalSignals instance
  // and the catchable signals it considers to be fatal.
  static LocalFileSystem _instance;
  static LocalFileSystem get instance => _instance ??= LocalFileSystem._(
    LocalSignals.instance,
    Signals.defaultExitSignals,
  );

  Directory _systemTemp;
  final Map<ProcessSignal, Object> _signalTokens = <ProcessSignal, Object>{};

  @visibleForTesting
  static Future<void> dispose() => LocalFileSystem.instance?._dispose();

  Future<void> _dispose() async {
    _tryToDeleteTemp();
    for (final MapEntry<ProcessSignal, Object> signalToken in _signalTokens.entries) {
      await _signals.removeHandler(signalToken.key, signalToken.value);
    }
    _signalTokens.clear();
  }

  final Signals _signals;
  final List<ProcessSignal> _fatalSignals;

  void _tryToDeleteTemp() {
    try {
      if (_systemTemp?.existsSync() ?? false) {
        _systemTemp.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // ignore.
    }
    _systemTemp = null;
  }

  // This getter returns a fresh entry under /tmp, like
  // /tmp/flutter_tools.abcxyz, then the rest of the tool creates /tmp entries
  // under that, like /tmp/flutter_tools.abcxyz/flutter_build_stuff.123456.
  // Right before exiting because of a signal or otherwise, we delete
  // /tmp/flutter_tools.abcxyz, not the whole of /tmp.
  @override
  Directory get systemTempDirectory {
    if (_systemTemp == null) {
      _systemTemp = super.systemTempDirectory.createTempSync(
        'flutter_tools.',
      )..createSync(recursive: true);
      // Make sure that the temporary directory is cleaned up if the tool is
      // killed by a signal.
      for (final ProcessSignal signal in _fatalSignals) {
        final Object token = _signals.addHandler(
          signal,
          (ProcessSignal _) {
            _tryToDeleteTemp();
          },
        );
        _signalTokens[signal] = token;
      }
      // Make sure that the temporary directory is cleaned up when the tool
      // exits normally.
      shutdownHooks?.addShutdownHook(
        _tryToDeleteTemp,
        ShutdownStage.CLEANUP,
      );
    }
    return _systemTemp;
  }
}
