// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// An build that produces artifacts that can be built.
///
/// A [BuildDefinition] can be executed via `flutter assemble`.
class BuildDefinition {
  /// Create a new [BuildDefinition].
  ///
  /// Both [name] and [phases] must not be null. Phases must not be empty
  /// or [createBuild] will throw a [StateError].
  const BuildDefinition({
    @required this.name,
    @required this.phases,
  }) : assert(name != null && name != ''),
       assert(phases != null);

  final String name;
  final List<BuildPhase> phases;

  /// Create the root [Target] to be invoked via the [BuildSystem].
  ///
  /// This method is also responsible for validating the target graph, including
  /// checking for cycles and naming collisions.
  ///
  /// Throws a [StateError] if [phases] is empty.
  // TODO(jonahwilliams): add output file collision detection.
  Future<Target> createBuild(Environment environment) async {
    if (phases.isEmpty) {
      throw StateError('A BuildDefinition was created with no phases.');
    }
    // First create an aggregate target for each phase and store then by.
    // phase name.
    final Map<String, _AggregateTarget> aggregates = <String, _AggregateTarget>{};
    for (BuildPhase buildPhase in phases) {
      final List<Target> targets = await buildPhase.plan(environment);
      final _AggregateTarget target = _AggregateTarget(targets, buildPhase);
      aggregates[target.name] = target;
    }
    // Then order the aggregate targets such that dependencies are inserted into
    // the target graph in order. This is by traversing the list of aggregate
    // nodes and inserting the dependant aggregate targets into the list of
    // dependencies. This is validated by the call to [checkCycles] later.
    final _RootTarget result = _RootTarget(aggregates.values.toList(), this);
    for (_AggregateTarget target in aggregates.values) {
      for (String phaseDependency in target.phase.dependencies) {
        final _AggregateTarget dependency = aggregates[phaseDependency];
        target.dependencies.add(dependency);
      }
    }
    checkCycles(result);
    return result;
  }
}

// A synthetic target created from a List of [BuildPhase] aggregate targets.
class _RootTarget extends Target {
  _RootTarget(this.dependencies, this.definition);

  final BuildDefinition definition;

  @override
  final List<Target> dependencies;

  @override
  String get name => definition.name;

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];
}

// A synthetic target created from the result of a [BuildPhase.plan].
class _AggregateTarget extends Target {
  _AggregateTarget(this.dependencies, this.phase);

  final BuildPhase phase;

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  final List<Target> dependencies;

  @override
  List<Source> get inputs => const <Source>[];

  @override
  String get name => phase.name;

  @override
  List<Source> get outputs => const <Source>[];
}

/// A Phase is a creator of [Targets].
///
/// A phase doesn't have explicit dependencies on individual targets. Instead,
/// the build system requires all phases in [dependencies] to have run before
/// this phase.
///
/// A phase will always be run, but the targets that constitute it may be
/// skipped. The [plan] method of a build's phases are always invoked before
/// any targets are run.
abstract class BuildPhase {
  const BuildPhase();

  /// A build phase that consists entirely of static targets.
  ///
  /// All of [name], [target], and [dependencies] must not be null.
  const factory BuildPhase.static({
    @required String name,
    @required Target target,
    @required List<String> dependencies,
  }) = _StaticBuildPhase;

  /// The name of the build phase.
  String get name;

  /// The names of the [BuildPhase]s this phase depends on.
  List<String> get dependencies;

  /// Generate one or more targets for this build phase.
  Future<List<Target>> plan(Environment environment);
}

class _StaticBuildPhase implements BuildPhase {
  const _StaticBuildPhase({
    @required this.name,
    @required this.target,
    @required this.dependencies
  }) : assert(name != null),
       assert(target != null),
       assert(dependencies != null);

  @override
  final List<String> dependencies;

  @override
  final String name;

  final Target target;

  @override
  Future<List<Target>> plan(Environment environment) async {
    return <Target>[target];
  }
}

/// Check if there are any dependency cycles in the target.
///
/// Throws a [CycleException] if one is encountered.
void checkCycles(Target initial) {
  void checkInternal(Target target, Set<String> visited, Set<String> stack) {
    if (stack.contains(target.name)) {
      throw CycleException(stack..add(target.name));
    }
    if (visited.contains(target.name)) {
      return;
    }
    visited.add(target.name);
    stack.add(target.name);
    for (Target dependency in target.dependencies) {
      checkInternal(dependency, visited, stack);
    }
    stack.remove(target);
  }
  checkInternal(initial, <String>{}, <String>{});
}
