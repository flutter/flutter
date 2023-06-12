// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'basic_test.dart' as basic;
import 'bazel_test.dart' as bazel;
import 'bazel_watcher_test.dart' as bazel_watcher;
import 'gn_test.dart' as gn;
import 'package_build_test.dart' as package_build;
import 'pub_test.dart' as pub;

main() {
  defineReflectiveSuite(() {
    basic.main();
    bazel.main();
    bazel_watcher.main();
    gn.main();
    package_build.main();
    pub.main();
  }, name: 'workspace');
}
