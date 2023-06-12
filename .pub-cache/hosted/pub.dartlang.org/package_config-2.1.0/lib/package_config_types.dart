// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A package configuration is a way to assign file paths to package URIs,
/// and vice-versa.
///
/// {@canonicalFor package_config.InvalidLanguageVersion}
/// {@canonicalFor package_config.LanguageVersion}
/// {@canonicalFor package_config.Package}
/// {@canonicalFor package_config.PackageConfig}
/// {@canonicalFor errors.PackageConfigError}
library package_config.package_config_types;

export 'src/package_config.dart'
    show PackageConfig, Package, LanguageVersion, InvalidLanguageVersion;
export 'src/errors.dart' show PackageConfigError;
