// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// A build that produces artifacts that can be built.
///
/// A [BuildDefinition] can be executed via `flutter assemble`.
class BuildDefinition {
  /// Creates a new [BuildDefinition].
  ///
  /// Both [name] and [groups] must not be null. [groups] must not be empty
  /// or [createBuild] will throw a [StateError].
  const BuildDefinition({
    @required this.name,
    @required this.groups,
  }) : assert(name != null && name != ''),
       assert(groups != null);

  final String name;
  final List<TargetGroup> groups;

  /// Create the root [Target] to be invoked via the [BuildSystem].
  ///
  /// This method is also responsible for validating the target graph, including
  /// checking for cycles and naming collisions.
  ///
  /// Throws a [StateError] if [groups] is empty.
  // TODO(jonahwilliams): add output file collision detection.
  Future<Target> createBuild(Environment environment) async {
    if (groups.isEmpty) {
      throw StateError('A BuildDefinition was created with no phases.');
    }
    // First create an aggregate target for each group and store them by.
    // phase name.
    final Map<String, _AggregateTarget> aggregates = <String, _AggregateTarget>{};
    for (TargetGroup buildPhase in groups) {
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
    GraphValidater(result).validate();
    return result;
  }
}

/// A synthetic target created from a list of [TargetGroup] aggregate targets.
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

/// A synthetic target created from the result of a [TargetGroup.plan].
class _AggregateTarget extends Target {
  _AggregateTarget(this.dependencies, this.phase);

  final TargetGroup phase;

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

/// A group creates a list of targets.
///
/// A group doesn't have explicit dependencies on individual targets. Instead,
/// the build system requires all phases in [dependencies] to have run before
/// this phase.
///
/// A group's [plan] method will always be run, but the targets that are created
/// from it may be skipped. This method is always invoked before before build
/// execution begins.
abstract class TargetGroup {
  const TargetGroup();

  /// A target group that consists entirely of static targets.
  ///
  /// All of [name], [target], and [dependencies] must not be null.
  const factory TargetGroup.static({
    @required String name,
    @required Target target,
    @required List<String> dependencies,
  }) = _StaticTargetGroup;

  /// The name of the target group.
  String get name;

  /// The names of the [TargetGroup]s this phase depends on.
  List<String> get dependencies;

  /// Generate one or more targets for this build phase.
  Future<List<Target>> plan(Environment environment);
}

class _StaticTargetGroup implements TargetGroup {
  const _StaticTargetGroup({
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
/// Throws a [CycleException] if a cycle is detected.
/// Throws a [NameCollisionException] if there exist two nodes with the same
/// name and different identities.
class GraphValidater {
  GraphValidater(this.root);

  final Target root;
  final Map<String, Target> visited = <String, Target>{};

  void validate() {
    return _checkInternal(root, visited, <String>{});
  }

  void _checkInternal(Target target, Map<String, Target> visited, Set<String> stack) {
    if (stack.contains(target.name)) {
      final Target previousTarget = visited[target.name];
      // Check that instance is the same.
      if (!identical(previousTarget, target)) {
        throw NameCollisionException(previousTarget, target);
      }
      throw CycleException(stack..add(target.name));
    }
    if (visited.keys.contains(target.name)) {
      // Check that instance is the same.
      final Target previousTarget = visited[target.name];
      if (!identical(previousTarget, target)) {
        throw NameCollisionException(previousTarget, target);
      }
      return;
    }
    visited[target.name] = target;
    stack.add(target.name);
    for (Target dependency in target.dependencies) {
      _checkInternal(dependency, visited, stack);
    }
    stack.remove(target.name);
  }
}
