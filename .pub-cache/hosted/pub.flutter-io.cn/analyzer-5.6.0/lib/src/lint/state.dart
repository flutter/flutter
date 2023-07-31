// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

/// A version describing Dart language version 2.12.0.
final Version dart2_12 = Version(2, 12, 0);

/// A version describing Dart language version 3.0.0.
final Version dart3 = Version(3, 0, 0);

/// A state that marks a lint as deprecated.
class DeprecatedState extends State {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  /// Initialize a newly created deprecated state with given values.
  const DeprecatedState({super.since, this.replacedBy})
      : super(label: 'deprecated');
}

/// A state that marks a lint as experimental.
class ExperimentalState extends State {
  /// Initialize a newly created experimental state with given values.
  const ExperimentalState({super.since}) : super(label: 'experimental');
}

/// A state that identifies a lint as having been removed.
class RemovedState extends State {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  /// Initialize a newly created removed state with given values.
  const RemovedState({super.since, this.replacedBy}) : super(label: 'removed');
}

/// A state that marks a lint as stable.
class StableState extends State {
  /// Initialize a newly created stable state with given values.
  const StableState({super.since}) : super(label: 'stable');
}

/// Describes the state of a lint.
abstract class State {
  static const _undatedStable = StableState();
  static const _undatedDeprecated = DeprecatedState();
  static const _undatedExperimental = ExperimentalState();

  /// An Optional Dart language version that identifies the start of this state.
  final Version? since;

  /// A short description, suitable for displaying in documentation or a
  /// diagnostic message.
  final String label;

  /// Initialize a newly created State object.
  const State({required this.label, this.since});

  /// Initialize a newly created deprecated state with given values.
  factory State.deprecated({Version? since, String? replacedBy}) =>
      since == null && replacedBy == null
          ? _undatedDeprecated
          : DeprecatedState(since: since, replacedBy: replacedBy);

  /// Initialize a newly created experimental state with given values.
  factory State.experimental({Version? since}) =>
      since == null ? _undatedExperimental : ExperimentalState(since: since);

  /// Initialize a newly created removed state with given values.
  factory State.removed({Version? since, String? replacedBy}) =>
      RemovedState(since: since, replacedBy: replacedBy);

  /// Initialize a newly created stable state with given values.
  factory State.stable({Version? since}) =>
      since == null ? _undatedStable : StableState(since: since);

  /// An optional description that can be used in documentation or diagnostic
  /// reporting.
  String? getDescription() => null;
}

extension StateExtension on State {
  bool get isDeprecated => this is DeprecatedState;
  bool get isExperimental => this is ExperimentalState;
  bool get isRemoved => this is RemovedState;
  bool get isStable => this is StableState;
}
