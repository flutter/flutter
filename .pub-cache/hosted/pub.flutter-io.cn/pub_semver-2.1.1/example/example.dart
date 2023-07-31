// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

void main() {
  final range = VersionConstraint.parse('^2.0.0');

  for (var version in [
    Version.parse('1.2.3-pre'),
    Version.parse('2.0.0+123'),
    Version.parse('3.0.0-dev'),
  ]) {
    print('$version ${version.isPreRelease} ${range.allows(version)}');
  }
}
