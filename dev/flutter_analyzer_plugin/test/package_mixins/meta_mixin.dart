// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

extension MetaPackageConfigExtnesion on PackageConfigFileBuilder {
  PackageConfigFileBuilder addMetaPackage(AnalysisRuleTest test) {
    add(
      name: MetaPackage._metaPackageName,
      rootPath: test.convertPath(MetaPackage._metaPackageRoot),
    );
    return this;
  }
}

/// Mixin application that allows for `package:meta` imports in tests.
mixin MetaPackage on AnalysisRuleTest {
  static const String _metaPackageName = 'meta';
  static const String _metaPackageRoot = '/packages/$_metaPackageName';

  @override
  void setUp() {
    super.setUp();
    newFile('$_metaPackageRoot/lib/meta.dart', '''
library meta;

const protected = Object();
const mustCallSuper = Object();
const factory = Object();
const optionalTypeArgs = Object();
''');
  }
}
