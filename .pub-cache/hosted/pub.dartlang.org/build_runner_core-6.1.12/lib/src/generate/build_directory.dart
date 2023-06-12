// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../util/hash.dart';

class BuildDirectory {
  final String directory;
  final OutputLocation outputLocation;
  BuildDirectory(this.directory, {this.outputLocation});

  @override
  bool operator ==(Object other) =>
      other is BuildDirectory &&
      other.directory == directory &&
      other.outputLocation == outputLocation;

  @override
  int get hashCode {
    var hash = 0;
    hash = hashCombine(hash, directory.hashCode);
    hash = hashCombine(hash, outputLocation.hashCode);
    return hashComplete(hash);
  }
}

class OutputLocation {
  final String path;
  final bool useSymlinks;
  final bool hoist;
  OutputLocation(this.path, {bool useSymlinks, bool hoist})
      : useSymlinks = useSymlinks ?? false,
        hoist = hoist ?? true {
    if (path.isEmpty && hoist) {
      throw ArgumentError('Can not build everything and hoist');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OutputLocation &&
      other.path == path &&
      other.useSymlinks == useSymlinks &&
      other.hoist == hoist;

  @override
  int get hashCode {
    var hash = 0;
    hash = hashCombine(hash, path.hashCode);
    hash = hashCombine(hash, useSymlinks.hashCode);
    hash = hashCombine(hash, hoist.hashCode);
    return hashComplete(hash);
  }
}
