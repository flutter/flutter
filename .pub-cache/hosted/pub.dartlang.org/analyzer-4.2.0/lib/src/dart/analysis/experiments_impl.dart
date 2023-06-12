// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// The same as [ExperimentStatus.knownFeatures], except when a call to
/// [overrideKnownFeatures] is in progress.
Map<String, ExperimentalFeature> _knownFeatures =
    ExperimentStatus.knownFeatures;

/// This flag is `true` while [overrideKnownFeaturesAsync] is executing.
bool _overrideKnownFeaturesAsyncExecuting = false;

/// Decodes the strings given in [flags] into a list of booleans representing
/// experiments that should be enabled.
///
/// Always succeeds, even if the input flags are invalid.  Expired and
/// unrecognized flags are ignored, conflicting flags are resolved in favor of
/// the flag appearing last.
EnabledDisabledFlags decodeExplicitFlags(List<String> flags) {
  var enabledFlags = List<bool>.filled(_knownFeatures.length, false);
  var disabledFlags = List<bool>.filled(_knownFeatures.length, false);
  for (var entry in _flagStringsToMap(flags).entries) {
    if (entry.value) {
      enabledFlags[entry.key] = true;
    } else {
      disabledFlags[entry.key] = true;
    }
  }
  return EnabledDisabledFlags(enabledFlags, disabledFlags);
}

/// Pretty-prints the given set of enable flags as a set of feature names.
String experimentStatusToString(List<bool> enableFlags) {
  var featuresInSet = <String>[];
  for (var feature in _knownFeatures.values) {
    if (enableFlags[feature.index]) {
      featuresInSet.add(feature.enableString);
    }
  }
  return 'FeatureSet{${featuresInSet.join(', ')}}';
}

/// Converts the flags in [status] to a list of strings suitable for
/// passing to [_decodeFlags].
List<String> experimentStatusToStringList(ExperimentStatus status) {
  var result = <String>[];
  for (var feature in _knownFeatures.values) {
    if (feature.isExpired) continue;
    var isEnabled = status.isEnabled(feature);
    if (isEnabled != feature.isEnabledByDefault) {
      result.add(feature.stringForValue(isEnabled));
    }
  }
  return result;
}

/// Execute the callback, pretending that the given [knownFeatures] take the
/// place of [ExperimentStatus.knownFeatures].
///
/// It isn't safe to call this method with an asynchronous callback, because it
/// only changes the set of known features during the time that [callback] is
/// (synchronously) executing. Use [overrideKnownFeaturesAsync] instead.
@visibleForTesting
T overrideKnownFeatures<T>(
  Map<String, ExperimentalFeature> knownFeatures,
  T Function() callback,
) {
  var oldKnownFeatures = _knownFeatures;
  try {
    _knownFeatures = knownFeatures;
    return callback();
  } finally {
    _knownFeatures = oldKnownFeatures;
  }
}

/// Execute the callback, pretending that the given [knownFeatures] take the
/// place of [ExperimentStatus.knownFeatures].
///
/// This function cannot be invoked before its previous invocation completes.
@visibleForTesting
Future<T> overrideKnownFeaturesAsync<T>(
  Map<String, ExperimentalFeature> knownFeatures,
  Future<T> Function() callback,
) async {
  if (_overrideKnownFeaturesAsyncExecuting) {
    throw StateError('overrideKnownFeaturesAsync is not reentrant');
  }

  _overrideKnownFeaturesAsyncExecuting = true;
  var oldKnownFeatures = _knownFeatures;
  try {
    _knownFeatures = knownFeatures;
    return await callback();
  } finally {
    _knownFeatures = oldKnownFeatures;
    _overrideKnownFeaturesAsyncExecuting = false;
  }
}

/// Computes a new set of enable flags based on [version].
///
/// Features in [explicitEnabledFlags] are enabled in the [sdkLanguageVersion].
///
/// Features in [explicitDisabledFlags] are always disabled.
List<bool> restrictEnableFlagsToVersion({
  required Version sdkLanguageVersion,
  required List<bool> explicitEnabledFlags,
  required List<bool> explicitDisabledFlags,
  required Version version,
}) {
  var decodedFlags = List.filled(_knownFeatures.length, false);
  for (var feature in _knownFeatures.values) {
    if (explicitDisabledFlags[feature.index]) {
      decodedFlags[feature.index] = false;
      continue;
    }

    var releaseVersion = feature.releaseVersion;
    if (releaseVersion != null && version >= releaseVersion) {
      decodedFlags[feature.index] = true;
    }

    if (explicitEnabledFlags[feature.index]) {
      var experimentalReleaseVersion = feature.experimentalReleaseVersion;
      if (experimentalReleaseVersion == null) {
        // Specifically, the current sdk version (whatever it is) is always
        // used as the language version which opts code into the experiment
        // when the experiment flag is passed.
        if (version == sdkLanguageVersion) {
          decodedFlags[feature.index] = true;
        }
      } else {
        // An experiment flag may at any point be assigned an experimental
        // release version.  From that point forward, all tools will no
        // longer use the current sdk version to opt code in, but rather
        // will use the experimental release version as the opt in version.
        // Updated 2020-08-25: we decided that experimental features should
        // be available since `min(sdk, experimentalRelease)`.
        if (version >= experimentalReleaseVersion ||
            version >= sdkLanguageVersion) {
          decodedFlags[feature.index] = true;
        }
      }
    }
  }

  return decodedFlags;
}

/// Validates whether there are any disagreements between the strings given in
/// [flags1] and the strings given in [flags2].
///
/// The returned iterable yields any problems that were found.  Only reports
/// problems related to combining the flags; problems that would be found by
/// applying [validateFlags] to [flags1] or [flags2] individually are not
/// reported.
///
/// If no problems are found, it is safe to concatenate the flag lists.  If
/// problems are found, the only negative side effect is that some flags in
/// one list may be overridden by some flags in the other list.
///
/// TODO(paulberry): if this method ever needs to be exposed via the analyzer
/// public API, consider making a version that reports validation results using
/// the AnalysisError type.
Iterable<ConflictingFlagLists> validateFlagCombination(
    List<String> flags1, List<String> flags2) sync* {
  var flag1Map = _flagStringsToMap(flags1);
  var flag2Map = _flagStringsToMap(flags2);
  for (var entry in flag2Map.entries) {
    if (flag1Map[entry.key] != null && flag1Map[entry.key] != entry.value) {
      yield ConflictingFlagLists(
          _featureIndexToFeature(entry.key), !entry.value);
    }
  }
}

/// Validates whether the strings given in [flags] constitute a valid set of
/// experimental feature enable/disable flags.
///
/// The returned iterable yields any problems that were found.
///
/// TODO(paulberry): if this method ever needs to be exposed via the analyzer
/// public API, consider making a version that reports validation results using
/// the AnalysisError type.
Iterable<ValidationResult> validateFlags(List<String> flags) sync* {
  var previousFlagIndex = <int, int>{};
  var previousFlagValue = <int, bool>{};
  for (int flagIndex = 0; flagIndex < flags.length; flagIndex++) {
    var flag = flags[flagIndex];
    ExperimentalFeature? feature;
    bool requestedValue;
    if (flag.startsWith('no-')) {
      feature = _knownFeatures[flag.substring(3)];
      requestedValue = false;
    } else {
      feature = _knownFeatures[flag];
      requestedValue = true;
    }
    if (feature == null) {
      yield UnrecognizedFlag(flagIndex, flag);
    } else if (feature.isExpired) {
      yield requestedValue == feature.isEnabledByDefault
          ? UnnecessaryUseOfExpiredFlag(flagIndex, feature)
          : IllegalUseOfExpiredFlag(flagIndex, feature);
    } else if (previousFlagIndex.containsKey(feature.index) &&
        previousFlagValue[feature.index] != requestedValue) {
      yield ConflictingFlags(flagIndex, previousFlagIndex[feature.index]!,
          feature, requestedValue);
    } else {
      previousFlagIndex[feature.index] = flagIndex;
      previousFlagValue[feature.index] = requestedValue;
    }
  }
}

ExperimentalFeature _featureIndexToFeature(int index) {
  for (var feature in _knownFeatures.values) {
    if (feature.index == index) return feature;
  }
  throw ArgumentError('Unrecognized feature index');
}

Map<int, bool> _flagStringsToMap(List<String> flags) {
  var result = <int, bool>{};
  for (int flagIndex = 0; flagIndex < flags.length; flagIndex++) {
    var flag = flags[flagIndex];
    ExperimentalFeature? feature;
    bool requestedValue;
    if (flag.startsWith('no-')) {
      feature = _knownFeatures[flag.substring(3)];
      requestedValue = false;
    } else {
      feature = _knownFeatures[flag];
      requestedValue = true;
    }
    if (feature != null && !feature.isExpired) {
      result[feature.index] = requestedValue;
    }
  }
  return result;
}

/// Indication of a conflict between two lists of flags.
class ConflictingFlagLists {
  /// Info about which feature the user requested conflicting values for
  final ExperimentalFeature feature;

  /// True if the first list of flags requested to enable the experimental
  /// feature.
  final bool firstValue;

  ConflictingFlagLists(this.feature, this.firstValue);
}

/// Validation result indicating that the user requested conflicting values for
/// an experimental flag (e.g. both "foo" and "no-foo").
class ConflictingFlags extends ValidationResult {
  /// Info about which feature the user requested conflicting values for
  final ExperimentalFeature feature;

  /// The index of the first of the two conflicting strings.
  ///
  /// [stringIndex] is the index of the second of the two conflicting strings.
  final int previousStringIndex;

  /// True if the string at [stringIndex] requested to enable the experimental
  /// feature.
  ///
  /// The string at [previousStringIndex] requested the opposite.
  final bool requestedValue;

  ConflictingFlags(super.stringIndex, this.previousStringIndex, this.feature,
      this.requestedValue)
      : super._();

  @override
  String get flag => feature.stringForValue(requestedValue);

  @override
  bool get isError => true;

  @override
  String get message {
    var previousFlag = feature.stringForValue(!requestedValue);
    return 'Flag "$flag" conflicts with previous flag "$previousFlag"';
  }
}

class EnabledDisabledFlags {
  final List<bool> enabled;
  final List<bool> disabled;

  EnabledDisabledFlags(this.enabled, this.disabled);
}

/// Information about a single experimental flag that the user might use to
/// request that a feature be enabled (or disabled).
class ExperimentalFeature implements Feature {
  /// Index of the flag in the private data structure maintained by
  /// [ExperimentStatus].
  ///
  /// This index should not be relied upon to be stable over time.  For instance
  /// it should not be used to serialize the state of experiments to long term
  /// storage if there is any expectation of compatibility between analyzer
  /// versions.
  final int index;

  /// The string to enable the feature.
  final String enableString;

  /// Whether the feature is currently enabled by default.
  final bool isEnabledByDefault;

  /// Whether the flag is currently expired (meaning the enable/disable status
  /// can no longer be altered from the value in [isEnabledByDefault]).
  final bool isExpired;

  /// Documentation for the feature, if known.  `null` for expired flags.
  final String documentation;

  /// The first language version in which this feature can be enabled using
  /// the [enableString] experimental flag.
  final Version? experimentalReleaseVersion;

  @override
  final Version? releaseVersion;

  ExperimentalFeature({
    required this.index,
    required this.enableString,
    required this.isEnabledByDefault,
    required this.isExpired,
    required this.documentation,
    required this.experimentalReleaseVersion,
    required this.releaseVersion,
  }) : assert(isEnabledByDefault
            ? releaseVersion != null
            : releaseVersion == null);

  /// The string to disable the feature.
  String get disableString => 'no-$enableString';

  @override
  String? get experimentalFlag => isExpired ? null : enableString;

  @override
  FeatureStatus get status {
    if (isExpired) {
      if (isEnabledByDefault) {
        return FeatureStatus.current;
      } else {
        return FeatureStatus.abandoned;
      }
    } else {
      if (isEnabledByDefault) {
        return FeatureStatus.provisional;
      } else {
        return FeatureStatus.future;
      }
    }
  }

  /// Retrieves the string to enable or disable the feature, depending on
  /// [value].
  String stringForValue(bool value) => value ? enableString : disableString;

  @override
  String toString() => enableString;
}

/// Validation result indicating that the user requested enabling or disabling
/// of a feature associated with an expired flag, and the requested behavior
/// conflicts with the behavior that is now hardcoded into the toolchain.
class IllegalUseOfExpiredFlag extends ValidationResult {
  /// Information about the feature associated with the error.
  final ExperimentalFeature feature;

  IllegalUseOfExpiredFlag(super.flagIndex, this.feature) : super._();

  @override
  String get flag => feature.stringForValue(!feature.isEnabledByDefault);

  @override
  bool get isError => true;

  @override
  String get message {
    var state = feature.isEnabledByDefault ? 'enabled' : 'disabled';
    return 'Flag "$flag" was supplied, but the feature is already '
        'unconditionally $state.';
  }
}

/// Validation result indicating that the user requested enabling or disabling
/// of a feature associated with an expired flag, and the requested behavior
/// is consistent with the behavior that is now hardcoded into the toolchain.
/// (This is merely a warning, not an error).
class UnnecessaryUseOfExpiredFlag extends ValidationResult {
  /// Information about the feature associated with the warning.
  final ExperimentalFeature feature;

  UnnecessaryUseOfExpiredFlag(super.flagIndex, this.feature) : super._();

  @override
  String get flag => feature.stringForValue(feature.isEnabledByDefault);

  @override
  bool get isError => false;

  @override
  String get message => 'Flag "$flag" is no longer required.';
}

/// Validation result indicating that the user requested enabling or disabling
/// an unrecognized feature.
class UnrecognizedFlag extends ValidationResult {
  @override
  final String flag;

  UnrecognizedFlag(super.flagIndex, this.flag) : super._();

  @override
  bool get isError => true;

  @override
  String get message => 'Flag "$flag" not recognized.';
}

/// Representation of a single error or warning reported by
/// [ExperimentStatus.fromStrings].
abstract class ValidationResult {
  /// Indicates which of the supplied strings is associated with the error or
  /// warning.
  final int stringIndex;

  ValidationResult._(this.stringIndex);

  /// The supplied string associated with the error or warning.
  String get flag;

  /// Indicates whether the validation result is an error or a warning.
  bool get isError;

  /// Message describing the problem.
  String get message;

  @override
  String toString() => message;
}
