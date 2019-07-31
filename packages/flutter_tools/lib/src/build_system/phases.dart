// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// A Phase is a creator of [Targets].
///
/// A phase doesn't have explicit dependencies on individual targets. Instead,
/// the build system requires all phases in [dependencies] to have run before
/// this phase.
///
/// A phase will always be run, but the targets that constitute it may be
/// skipped.
abstract class BuildPhase {
  const BuildPhase();

  String get name;

  List<String> get dependencies;

  /// Generate one or more targets for this build phase.
  Future<List<Target>> application(Environment environment);

  /// Generate a target graph for this build phase from an [Environment].
  Future<Target> plan(Environment environment) async {
    final List<Target> targets = await application(environment);
    final Target target = _AggregateTarget(targets, name);
    checkCycles(target);
    return target;
  }
}

class _AggregateTarget extends Target {
  const _AggregateTarget(this.dependencies, this.name);

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  final List<Target> dependencies;

  @override
  List<Source> get inputs => const <Source>[];

  @override
  final String name;

  @override
  List<Source> get outputs => const <Source>[];
}

/// Check if there are any dependency cycles in the target.
///
/// Throws a [CycleException] if one is encountered.
void checkCycles(Target initial) {
  void checkInternal(Target target, Set<Target> visited, Set<Target> stack) {
    if (stack.contains(target)) {
      throw CycleException(stack..add(target));
    }
    if (visited.contains(target)) {
      return;
    }
    visited.add(target);
    stack.add(target);
    for (Target dependency in target.dependencies) {
      checkInternal(dependency, visited, stack);
    }
    stack.remove(target);
  }
  checkInternal(initial, <Target>{}, <Target>{});
}
