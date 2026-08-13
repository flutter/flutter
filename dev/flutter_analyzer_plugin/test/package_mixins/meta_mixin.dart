// ignore_for_file: specify_nonobvious_local_variable_types, omit_obvious_local_variable_types, always_put_control_body_on_new_line, sort_constructors_first, inference_failure_on_function_return_type, directives_ordering
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

extension MetaPackageConfigExtension on PackageConfigFileBuilder {
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
