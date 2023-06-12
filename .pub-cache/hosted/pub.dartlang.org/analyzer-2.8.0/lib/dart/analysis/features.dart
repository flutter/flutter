// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// Information about a single language feature whose presence or absence
/// depends on the supported Dart SDK version, and possibly on the presence of
/// experimental flags.
abstract class Feature {
  /// Feature information for the 2018 constant update.
  static final constant_update_2018 = ExperimentalFeatures.constant_update_2018;

  /// Feature information for non-nullability by default.
  static final non_nullable = ExperimentalFeatures.non_nullable;

  /// Feature information for constructor tear-offs.
  static final constructor_tearoffs = ExperimentalFeatures.constructor_tearoffs;

  /// Feature information for control flow collections.
  static final control_flow_collections =
      ExperimentalFeatures.control_flow_collections;

  /// Feature information for extension methods.
  static final extension_methods = ExperimentalFeatures.extension_methods;

  /// Feature information for extension types.
  static final extension_types = ExperimentalFeatures.extension_types;

  /// Feature information for generic metadata.
  static final generic_metadata = ExperimentalFeatures.generic_metadata;

  /// Feature information for spread collections.
  static final spread_collections = ExperimentalFeatures.spread_collections;

  /// Feature information for set literals.
  static final set_literals = ExperimentalFeatures.set_literals;

  /// Feature information for super parameters.
  static final super_parameters = ExperimentalFeatures.super_parameters;

  /// Feature information for the triple-shift operator.
  static final triple_shift = ExperimentalFeatures.triple_shift;

  /// Feature information for named arguments anywhere.
  static final named_arguments_anywhere =
      ExperimentalFeatures.named_arguments_anywhere;

  /// Feature information for non-function type aliases.
  static final nonfunction_type_aliases =
      ExperimentalFeatures.nonfunction_type_aliases;

  /// Feature information for variance.
  static final variance = ExperimentalFeatures.variance;

  /// If the feature may be enabled or disabled on the command line, the
  /// experimental flag that may be used to enable it.  Otherwise `null`.
  ///
  /// Should be `null` if [status] is `current` or `abandoned`.
  String? get experimentalFlag;

  /// If [status] is not `future`, the first language version in which this
  /// feature was enabled by default.  Otherwise `null`.
  Version? get releaseVersion;

  /// The status of the feature.
  FeatureStatus get status;
}

/// An unordered collection of [Feature] objects.
abstract class FeatureSet {
  /// Computes a set of features for use in a unit test.  Computes the set of
  /// features enabled in [sdkVersion], plus any specified [additionalFeatures].
  ///
  /// If [sdkVersion] is not supplied (or is `null`), then the current set of
  /// enabled features is used as the starting point.
  @visibleForTesting
  factory FeatureSet.forTesting(
          {String sdkVersion, List<Feature> additionalFeatures}) =
      // ignore: invalid_use_of_visible_for_testing_member
      ExperimentStatus.forTesting;

  /// Computes the set of features implied by the given set of experimental
  /// enable flags.
  @Deprecated("Use 'fromEnableFlags2' instead")
  factory FeatureSet.fromEnableFlags(List<String> flags) =
      ExperimentStatus.fromStrings;

  /// Computes the set of features implied by the given set of experimental
  /// enable flags.
  factory FeatureSet.fromEnableFlags2({
    required Version sdkLanguageVersion,
    required List<String> flags,
  }) = ExperimentStatus.fromStrings2;

  /// Computes the set of features for the latest language version known
  /// to the analyzer, without any experiments.  Use it only if you really
  /// don't care which language version you want to use, and sure that the
  /// code that you process is valid for the latest language version.
  ///
  /// Otherwise, it is recommended to use [FeatureSet.fromEnableFlags2].
  factory FeatureSet.latestLanguageVersion() =
      ExperimentStatus.latestLanguageVersion;

  /// Queries whether the given [feature] is contained in this feature set.
  bool isEnabled(Feature feature);

  /// Computes a subset of this FeatureSet by removing any features that are
  /// not available in the given language version.
  FeatureSet restrictToVersion(Version version);
}

/// Information about the status of a language feature.
enum FeatureStatus {
  /// The language feature has not yet shipped.  It may not be used unless an
  /// experimental flag is used to enable it.
  future,

  /// The language feature has not yet shipped, but we are testing the effect of
  /// enabling it by default.  It may be used in any library with an appropriate
  /// version constraint, unless an experimental flag is used to disable it.
  provisional,

  /// The language feature has been shipped.  It may be used in any library with
  /// an appropriate version constraint.
  current,

  /// The language feature is no longer planned.  It may not be used.
  abandoned,
}
