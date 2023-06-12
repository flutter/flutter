// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('package:test_core is not intended for general use. '
    'Please use package:test.')
library test_core.backend;

//ignore: deprecated_member_use
export 'package:test_api/backend.dart'
    show Metadata, PlatformSelector, Runtime, SuitePlatform;

export 'src/runner/configuration.dart' show Configuration;
export 'src/runner/configuration/custom_runtime.dart' show CustomRuntime;
export 'src/runner/configuration/runtime_settings.dart' show RuntimeSettings;
export 'src/runner/parse_metadata.dart' show parseMetadata;
export 'src/runner/suite.dart' show SuiteConfiguration;
