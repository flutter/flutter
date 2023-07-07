// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import '../util/detaching_future.dart';
import '../util/package_config.dart';

/// A comment which forces the language version to be that of the current
/// packages default.
///
/// If the cwd is not a package, this returns an empty string which ends up
/// defaulting to the current sdk version.
Future<String> get rootPackageLanguageVersionComment =>
    _rootPackageLanguageVersionComment.asFuture;
final _rootPackageLanguageVersionComment = DetachingFuture(() async {
  var packageConfig = await loadPackageConfigUri(await packageConfigUri);
  var rootPackage = packageConfig.packageOf(Uri.file(p.absolute('foo.dart')));
  if (rootPackage == null) return '';
  return '// @dart=${rootPackage.languageVersion}';
}());
