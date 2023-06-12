// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:path/path.dart' as package_path;

/// Environment for compiling macros to kernels, expecting that we run
/// a test in the Dart SDK repository.
///
/// This is a temporary implementation.
class MacrosEnvironment {
  static final instance = MacrosEnvironment._();

  final _resourceProvider = MemoryResourceProvider(context: package_path.posix);
  late final Folder packageAnalyzerFolder;

  MacrosEnvironment._() {
    var physical = PhysicalResourceProvider.INSTANCE;

    var packageRoot = physical.pathContext.normalize(package_root.packageRoot);
    physical
        .getFolder(packageRoot)
        .getChildAssumingFolder('_fe_analyzer_shared/lib/src/macros')
        .copyTo(
          packageSharedFolder.getChildAssumingFolder('lib/src'),
        );
    packageAnalyzerFolder =
        physical.getFolder(packageRoot).getChildAssumingFolder('analyzer');
  }

  Folder get packageSharedFolder {
    return _resourceProvider.getFolder('/packages/_fe_analyzer_shared');
  }
}
