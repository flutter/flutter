// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'build_system.dart';

/// An exception thrown if we detect a cycle in the dependencies of a target.
class CycleException implements Exception {
  CycleException(this.targets);

  final Set<Target> targets;

  @override
  String toString() => 'Dependency cycle detected in build: '
      '${targets.map((Target target) => target.name).join(' -> ')}';
}

/// An exception thrown when a pattern is invalid.
class InvalidPatternException implements Exception {
  InvalidPatternException(this.pattern);

  final String pattern;

  @override
  String toString() => 'The pattern "$pattern" is not valid';
}

/// An exception thrown if a build action is missing a required define.
class MissingDefineException implements Exception {
  MissingDefineException(this.define, this.target);

  final String define;
  final String target;

  @override
  String toString() {
    return 'Target $target required define $define '
        'but it was not provided';
  }
}
