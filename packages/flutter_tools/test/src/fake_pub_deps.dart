// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';

/// A fake implementation of [Pub] with a pre-primed [deps] response.
final class FakePubWithPrimedDeps implements Pub {
  /// Creates an implementation of [Pub] with a pre-primed [Pub.deps] response.
  ///
  /// It is expected that every [FlutterProject] that is provided to the
  /// [Pub.deps] call is represented by [rootPackageName].
  ///
  /// Optionally, provide [devDependencies] (of [rootPackageName]), and non
  /// dev-dependencies ([dependencies]) of any package to a set of any other
  /// packages. A resulting valid `dart pub deps --json` response is implicitly
  /// created.
  const FakePubWithPrimedDeps({
    required String rootPackageName,
    Set<String> devDependencies = const <String>{},
    Map<String, Set<String>> dependencies = const <String, Set<String>>{},
  })  : _rootPackage = rootPackageName,
        _devDependencies = devDependencies,
        _dependencies = dependencies;

  final String _rootPackage;
  final Set<String> _devDependencies;
  final Map<String, Set<String>> _dependencies;

  List<String> _getDeps(String name) {
    return _dependencies[_rootPackage]?.toList() ?? const <String>[];
  }

  @override
  Future<Map<String, Object?>> deps(FlutterProject project) async {
    throw UnimplementedError();
  }

  @override
  Never noSuchMethod(Invocation invocation) {
    throw UnsupportedError('Only Pub.deps is expected to be called');
  }
}
