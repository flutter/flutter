// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'input_matcher.dart';

/// A "phase" in the build graph, which represents running a one or more
/// builders on a set of sources.
abstract class BuildPhase {
  /// Whether to run lazily when an output is read.
  ///
  /// An optional build action will only run if one of its outputs is read by
  /// a later [Builder], or is used as a primary input to a later [Builder].
  ///
  /// If no build actions read the output of an optional action, then it will
  /// never run.
  bool get isOptional;

  /// Whether generated assets should be placed in the build cache.
  ///
  /// When this is `false` the Builder may not run on any package other than
  /// the root.
  bool get hideOutput;

  /// The identity of this action in terms of a build graph. If the identity of
  /// any action changes the build will be invalidated.
  ///
  /// This should take into account everything except for the builderOptions,
  /// which are tracked separately via a `BuilderOptionsNode` which supports
  /// more fine grained invalidation.
  int get identity;
}

/// An "action" in the build graph which represents running a single builder
/// on a set of sources.
abstract class BuildAction {
  /// Either a [Builder] or a [PostProcessBuilder].
  dynamic get builder;
  String get builderLabel;
  BuilderOptions get builderOptions;
  InputMatcher get generateFor;
  String get package;
  InputMatcher get targetSources;
}

/// A [BuildPhase] that uses a single [Builder] to generate files.
class InBuildPhase extends BuildPhase implements BuildAction {
  @override
  final Builder builder;
  @override
  final String builderLabel;
  @override
  final BuilderOptions builderOptions;
  @override
  final InputMatcher generateFor;
  @override
  final String package;
  @override
  final InputMatcher targetSources;

  @override
  final bool isOptional;
  @override
  final bool hideOutput;

  InBuildPhase._(this.package, this.builder, this.builderOptions,
      {@required this.targetSources,
      @required this.generateFor,
      @required this.builderLabel,
      bool isOptional,
      bool hideOutput})
      : isOptional = isOptional ?? false,
        hideOutput = hideOutput ?? false;

  /// Creates an [BuildPhase] for a normal [Builder].
  ///
  /// The build target is defined by [package] as well as [targetSources]. By
  /// default all sources in the target are used as primary inputs to the
  /// builder, but it can be further filtered with [generateFor].
  ///
  /// [isOptional] specifies that a Builder may not be run unless some other
  /// Builder in a later phase attempts to read one of the potential outputs.
  ///
  /// [hideOutput] specifies that the generated asses should be placed in the
  /// build cache rather than the source tree.
  InBuildPhase(
    Builder builder,
    String package, {
    String builderKey,
    InputSet targetSources,
    InputSet generateFor,
    BuilderOptions builderOptions,
    bool isOptional,
    bool hideOutput,
  }) : this._(package, builder, builderOptions ?? const BuilderOptions({}),
            targetSources: InputMatcher(targetSources ?? const InputSet()),
            generateFor: InputMatcher(generateFor ?? const InputSet()),
            builderLabel: builderKey == null || builderKey.isEmpty
                ? _builderLabel(builder)
                : _simpleBuilderKey(builderKey),
            isOptional: isOptional,
            hideOutput: hideOutput);

  @override
  String toString() {
    final settings = <String>[];
    if (isOptional) settings.add('optional');
    if (hideOutput) settings.add('hidden');
    var result = '$builderLabel on $targetSources in $package';
    if (settings.isNotEmpty) result += ' $settings';
    return result;
  }

  @override
  int get identity => _deepEquals.hash([
        builderLabel,
        builder.buildExtensions,
        package,
        targetSources,
        generateFor,
        isOptional,
        hideOutput
      ]);
}

/// A [BuildPhase] that can run multiple [PostBuildAction]s to
/// generate files.
///
/// There should only be one of these per build, and it should be the final
/// phase.
class PostBuildPhase extends BuildPhase {
  final List<PostBuildAction> builderActions;

  @override
  bool get hideOutput => true;
  @override
  bool get isOptional => false;

  PostBuildPhase(this.builderActions);

  @override
  String toString() =>
      '${builderActions.map((a) => a.builderLabel).join(', ')}';

  @override
  int get identity =>
      _deepEquals.hash(builderActions.map<dynamic>((b) => b.identity).toList()
        ..addAll([
          isOptional,
          hideOutput,
        ]));
}

/// Part of a larger [PostBuildPhase], applies a single
/// [PostProcessBuilder] to a single [package] with some additional options.
class PostBuildAction implements BuildAction {
  @override
  final PostProcessBuilder builder;
  @override
  final String builderLabel;
  @override
  final BuilderOptions builderOptions;
  @override
  final InputMatcher generateFor;
  @override
  final String package;
  @override
  final InputMatcher targetSources;

  PostBuildAction(this.builder, this.package,
      {String builderKey,
      @required BuilderOptions builderOptions,
      @required InputSet targetSources,
      @required InputSet generateFor})
      : builderLabel = builderKey == null || builderKey.isEmpty
            ? _builderLabel(builder)
            : _simpleBuilderKey(builderKey),
        builderOptions = builderOptions ?? const BuilderOptions({}),
        targetSources = InputMatcher(targetSources ?? const InputSet()),
        generateFor = InputMatcher(generateFor ?? const InputSet());

  int get identity => _deepEquals.hash([
        builderLabel,
        builder.inputExtensions.toList(),
        generateFor,
        package,
        targetSources,
      ]);
}

/// If we have no key find a human friendly name for the Builder.
String _builderLabel(Object builder) {
  var label = '$builder';
  if (label.startsWith('Instance of \'')) {
    label = label.substring(13, label.length - 1);
  }
  return label;
}

/// Change "angular|angular" to "angular".
String _simpleBuilderKey(String builderKey) {
  if (!builderKey.contains('|')) return builderKey;
  var parts = builderKey.split('|');
  if (parts[0] == parts[1]) return parts[0];
  return builderKey;
}

final _deepEquals = const DeepCollectionEquality();
