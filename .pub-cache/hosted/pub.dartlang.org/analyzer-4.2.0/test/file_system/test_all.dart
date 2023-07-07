// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'memory_file_system_test.dart' as memory_file_system;
import 'overlay_file_system_test.dart' as overlay_file_system;
import 'physical_file_system_test.dart' as physical_file_system;
import 'physical_resource_provider_watch_test.dart'
    as physical_resource_provider_watch_test;
import 'resource_uri_resolver_test.dart' as resource_uri_resolver;

main() {
  defineReflectiveSuite(() {
    memory_file_system.main();
    overlay_file_system.main();
    physical_file_system.main();
    physical_resource_provider_watch_test.main();
    resource_uri_resolver.main();
  }, name: 'file system');
}
