// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:path/path.dart' as p;

/// Which file paths should be printed.
abstract class Show {
  /// No files.
  static const Show none = _NoneShow();

  /// All traversed files.
  static const Show all = _AllShow();

  /// Only files whose formatting changed.
  static const Show changed = _ChangedShow();

  /// The legacy dartfmt output style when not overwriting files.
  static const Show legacy = _LegacyShow();

  /// The legacy dartfmt output style when overwriting files.
  static const Show overwrite = _OverwriteShow();

  /// The legacy dartfmt output style in "--dry-run".
  static const Show dryRun = _DryRunShow();

  const Show._();

  /// The display path to show for [file] which is in [directory].
  ///
  /// In the old CLI, this does not include [directory], since the directory
  /// name is printed separately. The new CLI only prints file paths, so this
  /// includes the root directory to disambiguate which directory the file is
  /// in.
  String displayPath(String directory, String file) => p.normalize(file);

  /// Describes a file that was processed.
  ///
  /// Returns whether or not this file should be displayed.
  bool file(String path, {required bool changed, required bool overwritten}) =>
      true;

  /// Describes the directory whose contents are about to be processed.
  void directory(String path) {}

  /// Describes the symlink at [path] that wasn't followed.
  void skippedLink(String path) {}

  /// Describes the hidden [path] that wasn't processed.
  void hiddenPath(String path) {}

  void _showFileChange(String path, {required bool overwritten}) {
    if (overwritten) {
      print('Formatted $path');
    } else {
      print('Changed $path');
    }
  }
}

mixin _ShowFileMixin on Show {
  @override
  bool file(String path, {required bool changed, required bool overwritten}) {
    if (changed) {
      _showFileChange(path, overwritten: overwritten);
    } else {
      print('Unchanged $path');
    }

    return true;
  }
}

mixin _LegacyMixin on Show {
  @override
  String displayPath(String directory, String file) =>
      p.relative(file, from: directory);

  @override
  void directory(String directory) {
    print('Formatting directory $directory:');
  }

  @override
  void skippedLink(String path) {
    print('Skipping link $path');
  }

  @override
  void hiddenPath(String path) {
    print('Skipping hidden path $path');
  }
}

class _NoneShow extends Show {
  const _NoneShow() : super._();
}

class _AllShow extends Show with _ShowFileMixin {
  const _AllShow() : super._();
}

class _ChangedShow extends Show {
  const _ChangedShow() : super._();

  @override
  bool file(String path, {required bool changed, required bool overwritten}) {
    if (changed) _showFileChange(path, overwritten: overwritten);
    return changed;
  }
}

class _LegacyShow extends Show with _LegacyMixin {
  const _LegacyShow() : super._();
}

class _OverwriteShow extends Show with _ShowFileMixin, _LegacyMixin {
  const _OverwriteShow() : super._();
}

class _DryRunShow extends Show {
  const _DryRunShow() : super._();

  @override
  String displayPath(String directory, String file) =>
      p.relative(file, from: directory);

  @override
  bool file(String path, {required bool changed, required bool overwritten}) {
    if (changed) print(path);
    return true;
  }
}
