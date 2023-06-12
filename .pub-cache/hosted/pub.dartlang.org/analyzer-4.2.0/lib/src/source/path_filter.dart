// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/glob.dart';
import 'package:path/path.dart' as path;

/// Filter paths against a set of [_ignorePatterns] relative to a
/// [ignorePatternsRoot] directory. Paths outside of [includedRoot] are also
/// ignored.
class PathFilter {
  /// The path context to use when manipulating paths.
  final path.Context pathContext;

  /// The path in which files are considered to be included.
  final String includedRoot;

  /// Path that all ignore patterns are relative to.
  final String ignorePatternsRoot;

  /// List of ignore patterns that paths are tested against.
  final List<Glob> _ignorePatterns = <Glob>[];

  /// Construct a new path filter rooted at [includedRoot],
  /// with [ignorePatterns] that are relative to [ignorePatternsRoot].
  /// If [pathContext] is not specified, then the system path context is used.
  PathFilter(
      this.includedRoot, this.ignorePatternsRoot, List<String> ignorePatterns,
      [path.Context? pathContext])
      : pathContext = pathContext ?? path.context {
    setIgnorePatterns(ignorePatterns);
  }

  /// Returns true if [path] should be ignored. A path is ignored if it is not
  /// contained in [includedRoot] or matches one of the ignore patterns.
  /// [path] is absolute or relative to [includedRoot].
  bool ignored(String path) {
    path = _canonicalize(path);
    return !_contained(path) || _match(path);
  }

  /// Set the ignore patterns.
  void setIgnorePatterns(List<String>? ignorePatterns) {
    _ignorePatterns.clear();
    if (ignorePatterns != null) {
      for (var ignorePattern in ignorePatterns) {
        _ignorePatterns.add(Glob(pathContext.separator, ignorePattern));
      }
    }
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    for (Glob pattern in _ignorePatterns) {
      sb.write('$pattern ');
    }
    sb.writeln('');
    return sb.toString();
  }

  /// Returns the absolute path of [path], relative to [includedRoot].
  String _canonicalize(String path) =>
      pathContext.normalize(pathContext.join(includedRoot, path));

  /// Returns true when [path] is contained inside [includedRoot].
  bool _contained(String path) => path.startsWith(includedRoot);

  /// Returns true if [path] matches any ignore patterns.
  bool _match(String path) {
    var relative = pathContext.relative(path, from: ignorePatternsRoot);
    for (Glob glob in _ignorePatterns) {
      if (glob.matches(relative)) {
        return true;
      }
    }
    return false;
  }
}
