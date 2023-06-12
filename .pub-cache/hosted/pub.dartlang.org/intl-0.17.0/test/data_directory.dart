// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A utility function for test and tools that compensates (at least for very
/// simple cases) for file-dependent programs being run from different
/// directories. The important cases are
///   - running in the directory that contains the test itself, i.e.
///    test/ or a sub-directory.
///   - running in root of this package, which is where the editor and bots will
///   run things by default
library data_directory;

import 'dart:io';
import 'package:path/path.dart' as path;

String get dataDirectory {
  return path.join(intlDirectory, datesRelativeToIntl);
}

/// Returns whether [dir] is the root of the `intl` package. We validate that it
/// is by looking for a pubspec file with the entry `name: intl`.
bool _isIntlRoot(String dir) {
  var file = File(path.join(dir, 'pubspec.yaml'));
  if (!file.existsSync()) return false;
  return file.readAsStringSync().contains('name: intl\n');
}

String get intlDirectory {
  // Try the current directory.
  if (_isIntlRoot(Directory.current.path)) return Directory.current.path;

  // Search upwards from the script location.
  var dir = path.fromUri(Platform.script);
  var root = path.rootPrefix(dir);

  while (dir != root) {
    if (_isIntlRoot(dir)) return dir;
    dir = path.dirname(dir);
  }

  throw UnsupportedError(
      'Cannot find the root directory of the `intl` package.');
}

String get datesRelativeToIntl => path.join('lib', 'src', 'data', 'dates');
