// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/src/dart/analysis/experiments_impl.dart'
    show
        ConflictingFlags,
        ExperimentalFeature,
        IllegalUseOfExpiredFlag,
        UnnecessaryUseOfExpiredFlag,
        UnrecognizedFlag,
        validateFlags,
        ValidationResult;

part 'experiments.g.dart';

/// Gets access to the private list of boolean flags in an [ExperimentStatus]
/// object. For testing use only.
@visibleForTesting
List<bool> getExperimentalFlags_forTesting(ExperimentStatus status) =>
    status._flags;

/// Gets access to the private SDK language version in an [ExperimentStatus]
/// object. For testing use only.
@visibleForTesting
Version getSdkLanguageVersion_forTesting(ExperimentStatus status) =>
    status._sdkLanguageVersion;

/// A representation of the set of experiments that are active and whether they
/// are enabled.
class ExperimentStatus with _CurrentState implements FeatureSet {
  /// The current language version.
  static final Version currentVersion = Version.parse(_currentVersion);

  /// A map containing information about all known experimental flags.
  static final Map<String, ExperimentalFeature> knownFeatures = _knownFeatures;

  final Version _sdkLanguageVersion;
  final List<bool> _explicitEnabledFlags;
  final List<bool> _explicitDisabledFlags;
  final List<bool> _flags;

  factory ExperimentStatus() {
    return ExperimentStatus.latestLanguageVersion();
  }

  factory ExperimentStatus.fromStorage(Uint8List encoded) {
    var byteIndex = 0;

    int getByte() {
      return encoded[byteIndex++];
    }

    List<bool> getBoolList(int length) {
      var result = List<bool>.filled(length, false);
      var byteValue = 0;
      var bitIndex = 0;
      for (var i = 0; i < length; i++) {
        if (bitIndex == 0) {
          byteValue = getByte();
        }
        if ((byteValue & (1 << bitIndex)) != 0) {
          result[i] = true;
        }
        bitIndex = (bitIndex + 1) % 8;
      }
      return result;
    }

    var sdkLanguageVersion = Version(getByte(), getByte(), 0);
    var featureCount = getByte();
    return ExperimentStatus._(
      sdkLanguageVersion,
      getBoolList(featureCount),
      getBoolList(featureCount),
      getBoolList(featureCount),
    );
  }

  /// Decodes the strings given in [flags] into a representation of the set of
  /// experiments that should be enabled.
  ///
  /// Always succeeds, even if the input flags are invalid.  Expired and
  /// unrecognized flags are ignored, conflicting flags are resolved in favor of
  /// the flag appearing last.
  factory ExperimentStatus.fromStrings2({
    required Version sdkLanguageVersion,
    required List<String> flags,
    // TODO(scheglov) use restrictEnableFlagsToVersion
  }) {
    var explicitFlags = decodeExplicitFlags(flags);

    var decodedFlags = restrictEnableFlagsToVersion(
      sdkLanguageVersion: sdkLanguageVersion,
      explicitEnabledFlags: explicitFlags.enabled,
      explicitDisabledFlags: explicitFlags.disabled,
      version: sdkLanguageVersion,
    );

    return ExperimentStatus._(
      sdkLanguageVersion,
      explicitFlags.enabled,
      explicitFlags.disabled,
      decodedFlags,
    );
  }

  factory ExperimentStatus.latestLanguageVersion() {
    return ExperimentStatus.fromStrings2(
      sdkLanguageVersion: currentVersion,
      flags: [],
    );
  }

  ExperimentStatus._(
    this._sdkLanguageVersion,
    this._explicitEnabledFlags,
    this._explicitDisabledFlags,
    this._flags,
  );

  @override
  int get hashCode => Object.hashAll(_flags);

  @override
  bool operator ==(Object other) {
    if (other is ExperimentStatus) {
      if (_sdkLanguageVersion != other._sdkLanguageVersion) {
        return false;
      }
      if (!_equalListOfBool(
          _explicitEnabledFlags, other._explicitEnabledFlags)) {
        return false;
      }
      if (!_equalListOfBool(
          _explicitDisabledFlags, other._explicitDisabledFlags)) {
        return false;
      }
      if (!_equalListOfBool(_flags, other._flags)) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Queries whether the given [feature] is enabled or disabled.
  @override
  bool isEnabled(covariant ExperimentalFeature feature) =>
      _flags[feature.index];

  @override
  FeatureSet restrictToVersion(Version version) {
    return ExperimentStatus._(
      _sdkLanguageVersion,
      _explicitEnabledFlags,
      _explicitDisabledFlags,
      restrictEnableFlagsToVersion(
        sdkLanguageVersion: _sdkLanguageVersion,
        explicitEnabledFlags: _explicitEnabledFlags,
        explicitDisabledFlags: _explicitDisabledFlags,
        version: version,
      ),
    );
  }

  /// Encode into the format suitable for [ExperimentStatus.fromStorage].
  Uint8List toStorage() {
    var result = Uint8List(16);
    var resultIndex = 0;

    void addByte(int value) {
      assert(value >= 0 && value < 256);
      result[resultIndex++] = value;
    }

    addByte(_sdkLanguageVersion.major);
    addByte(_sdkLanguageVersion.minor);

    void addBoolList(List<bool> values) {
      var byteValue = 0;
      var bitIndex = 0;
      for (var value in values) {
        if (value) {
          byteValue |= 1 << bitIndex;
        }
        bitIndex++;
        if (bitIndex == 8) {
          addByte(byteValue);
          byteValue = 0;
          bitIndex = 0;
        }
      }
      if (bitIndex != 0) {
        addByte(byteValue);
      }
    }

    addByte(_flags.length);
    addBoolList(_explicitEnabledFlags);
    addBoolList(_explicitDisabledFlags);
    addBoolList(_flags);

    return result.sublist(0, resultIndex);
  }

  @override
  String toString() => experimentStatusToString(_flags);

  static bool _equalListOfBool(List<bool> first, List<bool> second) {
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}
