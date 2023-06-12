// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

final _defaultDependenciesZoneKey = Symbol('buildConfigDefaultDependencies');
final _packageZoneKey = Symbol('buildConfigPackage');

T runInBuildConfigZone<T>(
        T Function() fn, String package, List<String> defaultDependencies) =>
    runZoned(fn, zoneValues: {
      _packageZoneKey: package,
      _defaultDependenciesZoneKey: defaultDependencies,
    });

String get currentPackage {
  var package = Zone.current[_packageZoneKey] as String;
  if (package == null) {
    throw StateError(
        'Must be running inside a build config zone, which can be done using '
        'the `runInBuildConfigZone` function.');
  }
  return package;
}

List<String> get currentPackageDefaultDependencies {
  var defaultDependencies =
      Zone.current[_defaultDependenciesZoneKey] as List<String>;
  if (defaultDependencies == null) {
    throw StateError(
        'Must be running inside a build config zone, which can be done using '
        'the `runInBuildConfigZone` function.');
  }
  return defaultDependencies;
}
