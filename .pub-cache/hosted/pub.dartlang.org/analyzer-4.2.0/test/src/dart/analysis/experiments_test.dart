// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentsTest);
  });
}

@reflectiveTest
class ExperimentsTest {
  var knownFeatures = <String, ExperimentalFeature>{};

  void assertCurrentSdkLanguageVersion(ExperimentStatus status) {
    expect(
      getSdkLanguageVersion(status),
      ExperimentStatus.currentVersion,
    );
  }

  void assertSdkLanguageVersion(ExperimentStatus status, String expectedStr) {
    var actual = getSdkLanguageVersion(status);
    expect('${actual.major}.${actual.minor}', expectedStr);
  }

  ExperimentStatus fromStrings2({
    required Version sdkLanguageVersion,
    required List<String> flags,
  }) {
    return overrideKnownFeatures(knownFeatures, () {
      return ExperimentStatus.fromStrings2(
        sdkLanguageVersion: sdkLanguageVersion,
        flags: flags,
      );
    });
  }

  List<bool> getFlags(ExperimentStatus status) {
    return getExperimentalFlags_forTesting(status);
  }

  Version getSdkLanguageVersion(ExperimentStatus status) {
    return getSdkLanguageVersion_forTesting(status);
  }

  List<ConflictingFlagLists> getValidateCombinationResult(
      List<String> flags1, List<String> flags2) {
    return overrideKnownFeatures(
        knownFeatures, () => validateFlagCombination(flags1, flags2).toList());
  }

  List<ValidationResult> getValidationResult(List<String> flags) {
    return overrideKnownFeatures(
        knownFeatures, () => validateFlags(flags).toList());
  }

  test_currentVersion() {
    // We don't care what the current version is, we just want to make sure that
    // it parses without error, and that it takes a simple 'major.minor' form.
    var currentVersion = ExperimentStatus.currentVersion;
    expect(currentVersion.patch, 0);
    expect(currentVersion.preRelease, isEmpty);
    expect(currentVersion.build, isEmpty);
  }

  test_fromStrings2_experimentalReleased_shouldBe_requested() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.2.0'),
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: Version.parse('1.4.0'),
      releaseVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      experimentalReleaseVersion: Version.parse('1.4.0'),
      releaseVersion: null,
    );
    overrideKnownFeatures(knownFeatures, () {
      // Only experiments that are explicitly requested can be enabled.
      var status = fromStrings2(
        sdkLanguageVersion: Version.parse('1.5.0'),
        flags: ['b'],
      );
      assertSdkLanguageVersion(status, '1.5');
      expect(getFlags(status), [true, true, false]);
    });
  }

  test_fromStrings2_flags_conflicting_disable_then_enable() {
    // Enable takes precedence because it's last
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['no-a', 'a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [true]);
  }

  test_fromStrings2_flags_conflicting_enable_then_disable() {
    // Disable takes precedence because it's last
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['a', 'no-a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [false]);
  }

  test_fromStrings2_flags_disable_disabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['no-a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [false]);
  }

  test_fromStrings2_flags_disable_enabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['no-a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [false]);
  }

  test_fromStrings2_flags_empty() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: [],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [false, true]);
  }

  test_fromStrings2_flags_enable_disabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [true]);
  }

  test_fromStrings2_flags_enable_enabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [true]);
  }

  test_fromStrings2_flags_illegal_use_of_expired_disable() {
    // Expired flags are ignored even if they would fail validation.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['no-a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [true]);
  }

  test_fromStrings2_flags_illegal_use_of_expired_enable() {
    // Expired flags are ignored even if they would fail validation.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [false]);
  }

  test_fromStrings2_flags_unnecessary_use_of_expired_disable() {
    // Expired flags are ignored.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['no-a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [false]);
  }

  test_fromStrings2_flags_unnecessary_use_of_expired_enable() {
    // Expired flags are ignored.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), [true]);
  }

  test_fromStrings2_flags_unrecognized() {
    // Unrecognized flags are ignored.
    var status = fromStrings2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: ['a'],
    );
    assertCurrentSdkLanguageVersion(status);
    expect(getFlags(status), <Object>[]);
  }

  test_fromStrings2_sdkLanguage_allows_experimental() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.2.0'),
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    overrideKnownFeatures(knownFeatures, () {
      var status = fromStrings2(
        sdkLanguageVersion: Version.parse('1.5.0'),
        flags: ['b', 'c'],
      );
      assertSdkLanguageVersion(status, '1.5');
      expect(getFlags(status), [true, true, true]);

      // Restricting to the SDK version does not change anything.
      var status2 =
          status.restrictToVersion(Version.parse('1.5.0')) as ExperimentStatus;
      assertSdkLanguageVersion(status2, '1.5');
      expect(getFlags(status2), [true, true, true]);

      // Restricting to the previous version disables the experiments.
      var status3 =
          status.restrictToVersion(Version.parse('1.4.0')) as ExperimentStatus;
      assertSdkLanguageVersion(status3, '1.5');
      expect(getFlags(status3), [true, false, false]);
    });
  }

  test_fromStrings2_sdkLanguage_allows_experimentalReleased() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.2.0'),
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: Version.parse('1.4.0'),
      releaseVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      experimentalReleaseVersion: Version.parse('1.5.0'),
      releaseVersion: null,
    );
    knownFeatures['d'] = ExperimentalFeature(
      index: 3,
      enableString: 'd',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'd',
      experimentalReleaseVersion: Version.parse('1.6.0'),
      releaseVersion: null,
    );
    overrideKnownFeatures(knownFeatures, () {
      var status = fromStrings2(
        sdkLanguageVersion: Version.parse('1.5.0'),
        flags: ['b', 'c', 'd'],
      );
      assertSdkLanguageVersion(status, '1.5');
      expect(getFlags(status), [true, true, true, true]);

      // Restricting to the SDK version does not change anything.
      var status2 =
          status.restrictToVersion(Version.parse('1.5.0')) as ExperimentStatus;
      assertSdkLanguageVersion(status2, '1.5');
      expect(getFlags(status2), [true, true, true, true]);

      // Restricting to a version disables some experiments.
      var status3 =
          status.restrictToVersion(Version.parse('1.4.0')) as ExperimentStatus;
      assertSdkLanguageVersion(status3, '1.5');
      expect(getFlags(status3), [true, true, false, false]);
    });
  }

  test_fromStrings2_sdkLanguage_restricts_released() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.6.0'),
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.1.0'),
    );
    var status = fromStrings2(
      sdkLanguageVersion: Version.parse('1.5.0'),
      flags: [],
    );
    assertSdkLanguageVersion(status, '1.5');
    expect(getFlags(status), [false, true]);
  }

  test_validateFlagCombination_disable_then_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var validationResult =
        getValidateCombinationResult(['a', 'no-c'], ['no-b', 'c']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0];
    expect(error.feature, knownFeatures['c']);
    expect(error.firstValue, false);
  }

  test_validateFlagCombination_enable_then_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var validationResult =
        getValidateCombinationResult(['a', 'c'], ['no-b', 'no-c']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0];
    expect(error.feature, knownFeatures['c']);
    expect(error.firstValue, true);
  }

  test_validateFlagCombination_ok() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    expect(getValidateCombinationResult(['a', 'c'], ['no-b', 'c']), isEmpty);
  }

  test_validateFlags_conflicting_flags_disable_then_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var validationResult = getValidationResult(['no-a', 'a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as ConflictingFlags;
    expect(error.stringIndex, 1);
    expect(error.flag, 'a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
    expect(error.previousStringIndex, 0);
    expect(error.requestedValue, true);
  }

  test_validateFlags_conflicting_flags_enable_then_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var validationResult = getValidationResult(['a', 'no-a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as ConflictingFlags;
    expect(error.stringIndex, 1);
    expect(error.flag, 'no-a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
    expect(error.previousStringIndex, 0);
    expect(error.requestedValue, false);
  }

  test_validateFlags_ignore_redundant_disable_flags() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    expect(getValidationResult(['no-a', 'no-a']), isEmpty);
  }

  test_validateFlags_ignore_redundant_enable_flags() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    expect(getValidationResult(['a', 'a']), isEmpty);
  }

  test_validateFlags_illegal_use_of_expired_flag_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var validationResult = getValidationResult(['no-a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as IllegalUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'no-a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_illegal_use_of_expired_flag_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var validationResult = getValidationResult(['a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as IllegalUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_unnecessary_use_of_expired_flag_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );
    var validationResult = getValidationResult(['no-a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as UnnecessaryUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'no-a');
    expect(error.isError, false);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_unnecessary_use_of_expired_flag_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: Version.parse('1.0.0'),
    );
    var validationResult = getValidationResult(['a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as UnnecessaryUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'a');
    expect(error.isError, false);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_unrecognized_flag() {
    var validationResult = getValidationResult(['a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as UnrecognizedFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'a');
    expect(error.isError, true);
  }
}
