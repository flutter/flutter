// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:graphs/graphs.dart';

/// Put [builders] into an order such that any builder which specifies
/// [BuilderDefinition.requiredInputs] will come after any builder which
/// produces a desired output.
///
/// Builders will be ordered such that their `required_inputs` and `runs_before`
/// constraints are met, but the rest of the ordering is arbitrary.
Iterable<BuilderDefinition> findBuilderOrder(
    Iterable<BuilderDefinition> builders) {
  final consistentOrderBuilders = builders.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  Iterable<BuilderDefinition> dependencies(BuilderDefinition parent) =>
      consistentOrderBuilders.where((child) =>
          _hasInputDependency(parent, child) || _mustRunBefore(parent, child));
  var components = stronglyConnectedComponents<BuilderDefinition>(
    consistentOrderBuilders,
    dependencies,
    equals: (a, b) => a.key == b.key,
    hashCode: (b) => b.key.hashCode,
  );
  return components.map((component) {
    if (component.length > 1) {
      throw ArgumentError('Required input cycle for ${component.toList()}');
    }
    return component.single;
  }).toList();
}

/// Whether [parent] has a `required_input` that wants to read outputs produced
/// by [child].
bool _hasInputDependency(BuilderDefinition parent, BuilderDefinition child) {
  final childOutputs = child.buildExtensions.values.expand((v) => v).toSet();
  return parent.requiredInputs
      .any((input) => childOutputs.any((output) => output.endsWith(input)));
}

/// Whether [child] specifies that it wants to run before [parent].
bool _mustRunBefore(BuilderDefinition parent, BuilderDefinition child) =>
    child.runsBefore.contains(parent.key);
