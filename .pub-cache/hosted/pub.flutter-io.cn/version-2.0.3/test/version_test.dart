// Copyright (c) 2021, Matthew Barbour. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:version/version.dart';

void main() {
  late Version zeroZeroZero,
      zeroZeroOne,
      zeroOneZero,
      oneZeroZero,
      fiveZeroFive,
      oneZeroZeroDuplicate,
      buildVersion,
      preReleaseVersion,
      buildAndPrereleaseVersion;

  setUp(() {
    zeroZeroZero = new Version(0, 0, 0);
    zeroZeroOne = new Version(0, 0, 1);
    zeroOneZero = new Version(0, 1, 0);
    oneZeroZero = new Version(1, 0, 0);

    fiveZeroFive = new Version(5, 0, 5);
    oneZeroZeroDuplicate = new Version(1, 0, 0);

    buildVersion = new Version(1, 0, 0, build: "buildNumber");
    preReleaseVersion = new Version(1, 0, 0, preRelease: <String>["alpha"]);
    buildAndPrereleaseVersion = new Version(1, 0, 0,
        preRelease: <String>["alpha"], build: "anotherBuild");
  });

  test('== tests', () {
    expect(zeroZeroOne == zeroZeroZero, isFalse);
    expect(oneZeroZero == zeroZeroZero, isFalse);
    expect(fiveZeroFive == zeroZeroZero, isFalse);
    expect(zeroZeroZero == zeroZeroZero, isTrue);

    expect(zeroZeroOne == zeroOneZero, isFalse);
    expect(zeroZeroOne == oneZeroZero, isFalse);
    expect(zeroOneZero == oneZeroZero, isFalse);
    expect(fiveZeroFive == zeroOneZero, isFalse);

    expect(zeroZeroOne == zeroZeroOne, isTrue);
    expect(zeroOneZero == zeroOneZero, isTrue);
    expect(oneZeroZero == oneZeroZero, isTrue);
    expect(fiveZeroFive == fiveZeroFive, isTrue);
    expect(oneZeroZero == oneZeroZeroDuplicate, isTrue);

    expect(buildVersion == oneZeroZero, isTrue);
    expect(preReleaseVersion == oneZeroZero, isFalse);
    expect(buildVersion == buildVersion, isTrue);
    expect(preReleaseVersion == preReleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion == preReleaseVersion, isTrue);
    expect(buildAndPrereleaseVersion == buildVersion, isFalse);
    expect(buildAndPrereleaseVersion == oneZeroZero, isFalse);
    expect(buildAndPrereleaseVersion == buildAndPrereleaseVersion, isTrue);
  });

  test('> tests', () {
    expect(zeroZeroZero > zeroOneZero, isFalse);
    expect(zeroZeroZero > oneZeroZero, isFalse);
    expect(zeroZeroZero > zeroZeroZero, isFalse);

    expect(zeroZeroOne > zeroOneZero, isFalse);
    expect(zeroZeroOne > oneZeroZero, isFalse);
    expect(zeroOneZero > oneZeroZero, isFalse);
    expect(zeroOneZero > fiveZeroFive, isFalse);

    expect(zeroOneZero > zeroZeroOne, isTrue);
    expect(oneZeroZero > zeroZeroOne, isTrue);
    expect(oneZeroZero > zeroOneZero, isTrue);
    expect(fiveZeroFive > zeroOneZero, isTrue);

    expect(zeroZeroOne > zeroZeroOne, isFalse);
    expect(zeroOneZero > zeroOneZero, isFalse);
    expect(oneZeroZero > oneZeroZero, isFalse);
    expect(fiveZeroFive > fiveZeroFive, isFalse);
    expect(oneZeroZero > oneZeroZeroDuplicate, isFalse);

    expect(buildVersion > oneZeroZero, isFalse);
    expect(oneZeroZero > buildVersion, isFalse);

    expect(preReleaseVersion > oneZeroZero, isFalse);
    expect(oneZeroZero > preReleaseVersion, isTrue);

    expect(buildVersion > buildVersion, isFalse);
    expect(preReleaseVersion > preReleaseVersion, isFalse);

    expect(buildAndPrereleaseVersion > preReleaseVersion, isFalse);
    expect(preReleaseVersion > buildAndPrereleaseVersion, isFalse);

    expect(buildAndPrereleaseVersion > buildVersion, isFalse);
    expect(buildVersion > buildAndPrereleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion > oneZeroZero, isFalse);
    expect(oneZeroZero > buildAndPrereleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion > buildAndPrereleaseVersion, isFalse);
  });

  test('< tests', () {
    expect(zeroZeroZero < zeroOneZero, isTrue);
    expect(zeroZeroZero < oneZeroZero, isTrue);
    expect(zeroZeroZero < fiveZeroFive, isTrue);
    expect(zeroZeroZero < zeroZeroZero, isFalse);

    expect(zeroZeroOne < zeroOneZero, isTrue);
    expect(zeroZeroOne < oneZeroZero, isTrue);
    expect(zeroOneZero < oneZeroZero, isTrue);
    expect(zeroOneZero < fiveZeroFive, isTrue);

    expect(zeroOneZero < zeroZeroOne, isFalse);
    expect(oneZeroZero < zeroZeroOne, isFalse);
    expect(oneZeroZero < zeroOneZero, isFalse);
    expect(fiveZeroFive < zeroOneZero, isFalse);

    expect(zeroZeroOne < zeroZeroOne, isFalse);
    expect(zeroOneZero < zeroOneZero, isFalse);
    expect(oneZeroZero < oneZeroZero, isFalse);
    expect(fiveZeroFive < fiveZeroFive, isFalse);
    expect(oneZeroZero < oneZeroZeroDuplicate, isFalse);

    expect(buildVersion < oneZeroZero, isFalse);
    expect(oneZeroZero < buildVersion, isFalse);

    expect(preReleaseVersion < oneZeroZero, isTrue);
    expect(oneZeroZero < preReleaseVersion, isFalse);

    expect(buildVersion < buildVersion, isFalse);
    expect(preReleaseVersion < preReleaseVersion, isFalse);

    expect(buildAndPrereleaseVersion < preReleaseVersion, isFalse);
    expect(preReleaseVersion < buildAndPrereleaseVersion, isFalse);
    expect(buildAndPrereleaseVersion < buildVersion, isTrue);
    expect(buildVersion < buildAndPrereleaseVersion, isFalse);
    expect(buildAndPrereleaseVersion < oneZeroZero, isTrue);
    expect(oneZeroZero < buildAndPrereleaseVersion, isFalse);
    expect(buildAndPrereleaseVersion < buildAndPrereleaseVersion, isFalse);
  });

  test('<= tests', () {
    expect(zeroZeroZero <= zeroOneZero, isTrue);
    expect(zeroZeroZero <= oneZeroZero, isTrue);
    expect(zeroZeroZero <= zeroZeroZero, isTrue);

    expect(zeroZeroOne <= zeroOneZero, isTrue);
    expect(zeroZeroOne <= oneZeroZero, isTrue);
    expect(zeroOneZero <= oneZeroZero, isTrue);
    expect(zeroOneZero <= fiveZeroFive, isTrue);

    expect(zeroOneZero <= zeroZeroOne, isFalse);
    expect(oneZeroZero <= zeroZeroOne, isFalse);
    expect(oneZeroZero <= zeroOneZero, isFalse);
    expect(fiveZeroFive <= zeroOneZero, isFalse);

    expect(zeroZeroOne <= zeroZeroOne, isTrue);
    expect(zeroOneZero <= zeroOneZero, isTrue);
    expect(oneZeroZero <= oneZeroZero, isTrue);
    expect(fiveZeroFive <= fiveZeroFive, isTrue);
    expect(oneZeroZero <= oneZeroZeroDuplicate, isTrue);

    expect(buildVersion <= oneZeroZero, isTrue);
    expect(oneZeroZero <= buildVersion, isTrue);

    expect(preReleaseVersion <= oneZeroZero, isTrue);
    expect(oneZeroZero <= preReleaseVersion, isFalse);

    expect(buildVersion <= buildVersion, isTrue);
    expect(preReleaseVersion <= preReleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion <= preReleaseVersion, isTrue);
    expect(preReleaseVersion <= buildAndPrereleaseVersion, isTrue);
    expect(buildAndPrereleaseVersion <= buildVersion, isTrue);
    expect(buildVersion <= buildAndPrereleaseVersion, isFalse);
    expect(buildAndPrereleaseVersion <= oneZeroZero, isTrue);
    expect(oneZeroZero <= buildAndPrereleaseVersion, isFalse);
    expect(buildAndPrereleaseVersion <= buildAndPrereleaseVersion, isTrue);
  });

  test('>= tests', () {
    expect(zeroZeroZero >= zeroOneZero, isFalse);
    expect(zeroZeroZero >= oneZeroZero, isFalse);
    expect(zeroZeroZero >= zeroZeroZero, isTrue);

    expect(zeroZeroOne >= zeroOneZero, isFalse);
    expect(zeroZeroOne >= oneZeroZero, isFalse);
    expect(zeroOneZero >= oneZeroZero, isFalse);
    expect(zeroOneZero >= fiveZeroFive, isFalse);

    expect(zeroOneZero >= zeroZeroOne, isTrue);
    expect(oneZeroZero >= zeroZeroOne, isTrue);
    expect(oneZeroZero >= zeroOneZero, isTrue);
    expect(fiveZeroFive >= zeroOneZero, isTrue);

    expect(zeroZeroOne >= zeroZeroOne, isTrue);
    expect(zeroOneZero >= zeroOneZero, isTrue);
    expect(oneZeroZero >= oneZeroZero, isTrue);
    expect(fiveZeroFive >= fiveZeroFive, isTrue);
    expect(oneZeroZero >= oneZeroZeroDuplicate, isTrue);

    expect(buildVersion >= oneZeroZero, isTrue);
    expect(oneZeroZero >= buildVersion, isTrue);

    expect(preReleaseVersion >= oneZeroZero, isFalse);
    expect(oneZeroZero >= preReleaseVersion, isTrue);

    expect(buildVersion >= buildVersion, isTrue);
    expect(preReleaseVersion >= preReleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion >= preReleaseVersion, isTrue);
    expect(preReleaseVersion >= buildAndPrereleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion >= buildVersion, isFalse);
    expect(buildVersion >= buildAndPrereleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion >= oneZeroZero, isFalse);
    expect(oneZeroZero >= buildAndPrereleaseVersion, isTrue);

    expect(buildAndPrereleaseVersion >= buildAndPrereleaseVersion, isTrue);
  });

  test("Validation tests", () {
    expect(() => new Version(-1, 0, 0), throwsArgumentError);
    expect(() => new Version(1, -1, 0), throwsArgumentError);
    expect(() => new Version(1, 1, -1), throwsArgumentError);
    expect(() => new Version(0, -1, 1), throwsArgumentError);
    expect(() => new Version(0, 0, -1), throwsArgumentError);
    expect(() => new Version(1, 0, 0, preRelease: <String>[""]),
        throwsArgumentError);
    expect(() => new Version(1, 0, 0, preRelease: <String>["not^safe"]),
        throwsFormatException);
    expect(
        () => new Version(1, 0, 0, build: "not^safe"), throwsFormatException);
  });

  test("Parse tests", () {
    expect(Version.parse("0"), equals(new Version(0, 0, 0)));
    expect(Version.parse("0.0.0"), equals(new Version(0, 0, 0)));
    expect(Version.parse("1"), equals(new Version(1, 0, 0)));
    expect(Version.parse("1.0"), equals(new Version(1, 0, 0)));
    expect(Version.parse("1.2.1"), equals(new Version(1, 2, 1)));
    expect(Version.parse("0.5.3"), equals(new Version(0, 5, 3)));
    expect(Version.parse("0.0.3"), equals(new Version(0, 0, 3)));
    expect(Version.parse("1.2.3.5"), equals(new Version(1, 2, 3)));
    expect(Version.parse("99999.55465.5456"),
        equals(new Version(99999, 55465, 5456)));
    expect(Version.parse("1.0.0-alpha"),
        equals(new Version(1, 0, 0, preRelease: <String>["alpha"])));
    expect(Version.parse("1.0.0+build"),
        equals(new Version(1, 0, 0, build: "build")));
    expect(
        Version.parse("1.0.0-alpha+build"),
        equals(new Version(1, 0, 0,
            build: "build", preRelease: <String>["alpha"])));
    expect(
        Version.parse("1.0.0-alpha.beta+build"),
        equals(new Version(1, 0, 0,
            build: "build", preRelease: <String>["alpha", "beta"])));

    expect(
        Version.parse("1.0.0-az.AZ.12-3+az.AZ.12-3"),
        equals(new Version(1, 0, 0,
            build: "az.AZ.12-3", preRelease: <String>["az", "AZ", "12-3"])));

    expect(() => Version.parse(null), throwsFormatException);
    expect(() => Version.parse("a"), throwsFormatException);
    expect(() => Version.parse("123,4322"), throwsFormatException);
    expect(() => Version.parse("123a"), throwsFormatException);
    expect(() => Version.parse("1.0.0+not^safe"), throwsFormatException);
    expect(() => Version.parse("1.0.0-not^safe"), throwsFormatException);
  });

  test("Increment tests", () {
    expect(new Version(1, 0, 0).incrementMajor(), equals(new Version(2, 0, 0)));
    expect(new Version(1, 1, 0).incrementMajor(), equals(new Version(2, 0, 0)));
    expect(new Version(1, 1, 1).incrementMajor(), equals(new Version(2, 0, 0)));
    expect(new Version(1, 0, 0).incrementMinor(), equals(new Version(1, 1, 0)));
    expect(new Version(1, 1, 2).incrementMinor(), equals(new Version(1, 2, 0)));
    expect(new Version(1, 0, 0).incrementPatch(), equals(new Version(1, 0, 1)));
    expect(new Version(1, 1, 2).incrementPatch(), equals(new Version(1, 1, 3)));

    expect(
        new Version(1, 1, 1, preRelease: <String>["alpha"], build: "test")
            .incrementMajor(),
        equals(new Version(2, 0, 0)));
  });

  test("Comparison tests", () {
    Version a = new Version(1, 0, 0);
    Version b = new Version(1, 0, 0);
    expect(a.compareTo(b), equals(0));
    b = b.incrementMinor();
    expect(a.compareTo(b), equals(-1));
    a = a.incrementMajor();
    expect(a.compareTo(b), equals(1));
  });

  test("toString tests", () {
    expect(new Version(0, 0, 0).toString(), equals("0.0.0"));
    expect(new Version(1, 0, 0).toString(), equals("1.0.0"));
    expect(new Version(1, 1, 0).toString(), equals("1.1.0"));
    expect(new Version(1, 1, 1).toString(), equals("1.1.1"));
    expect(new Version(1, 0, 1).toString(), equals("1.0.1"));
    expect(new Version(001, 000, 0010).toString(), equals("1.0.10"));
    expect(
        new Version(1, 1, 1, build: "alpha").toString(), equals("1.1.1+alpha"));
    expect(
        new Version(1, 1, 1, preRelease: <String>["alpha", "omega"]).toString(),
        equals("1.1.1-alpha.omega"));
    expect(
        new Version(1, 1, 1,
            build: "alpha", preRelease: <String>["beta", "gamma"]).toString(),
        equals("1.1.1-beta.gamma+alpha"));
  });

  test("Pre-release precedence test", () {
    // 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0
    final List<Version> versions = <Version>[
      zeroZeroZero,
      zeroZeroOne,
      zeroOneZero,
      Version.parse("1.0.0-alpha"),
      Version.parse("1.0.0-alpha.1"),
      Version.parse("1.0.0-alpha.beta"),
      Version.parse("1.0.0-beta"),
      Version.parse("1.0.0-beta.2"),
      Version.parse("1.0.0-beta.11"),
      Version.parse("1.0.0-rc.1"),
      Version.parse("1.0.0"),
      fiveZeroFive
    ];
    for (int i = 0; i < versions.length; i++) {
      final Version version = versions[i];
      for (int j = 0; j <= i; j++) {
        final Version otherVersion = versions[j];
        expect(version >= otherVersion, isTrue,
            reason:
                "$version should be greater than or equal to $otherVersion");
        if (j == i) {
          expect(version > otherVersion, isFalse,
              reason: "$version should be equal to $otherVersion");
          expect(version < otherVersion, isFalse,
              reason: "$version should be equal to $otherVersion");
          expect(version == otherVersion, isTrue,
              reason: "$version should be equal to $otherVersion");
          expect(version <= otherVersion, isTrue,
              reason: "$version should be equal to $otherVersion");
        } else {
          expect(version > otherVersion, isTrue,
              reason: "$version should be greater than $otherVersion");
          expect(version < otherVersion, isFalse,
              reason: "$version should be greater than $otherVersion");
          expect(version == otherVersion, isFalse,
              reason: "$version should be greater than $otherVersion");
          expect(version <= otherVersion, isFalse,
              reason: "$version should be greater than $otherVersion");
        }
      }

      for (int j = i; j < versions.length; j++) {
        final Version otherVersion = versions[j];
        expect(version <= otherVersion, isTrue,
            reason: "$version should be less than or equal to $otherVersion");
        if (j == i) {
          expect(version > otherVersion, isFalse,
              reason: "$version should be equal to $otherVersion");
          expect(version < otherVersion, isFalse,
              reason: "$version should be equal to $otherVersion");
          expect(version == otherVersion, isTrue,
              reason: "$version should be equal to $otherVersion");
          expect(version >= otherVersion, isTrue,
              reason: "$version should be equal to $otherVersion");
        } else {
          expect(version > otherVersion, isFalse,
              reason: "$version should be less than $otherVersion");
          expect(version < otherVersion, isTrue,
              reason: "$version should be less than $otherVersion");
          expect(version == otherVersion, isFalse,
              reason: "$version should be less than $otherVersion");
          expect(version >= otherVersion, isFalse,
              reason: "$version should be less than $otherVersion");
        }
      }
    }
  });

  test("hashCode test", () {
    final Version versionOne =
        new Version(1, 0, 0, preRelease: <String>["alpha"]);
    final Version versionTwo =
        new Version(1, 0, 0, preRelease: <String>["al", "pha"]);
    final Version versionThree = new Version(1, 0, 0);

    expect(versionOne.hashCode != versionTwo.hashCode, isTrue);
    expect(versionTwo.hashCode != versionThree.hashCode, isTrue);
    expect(versionOne.hashCode != versionThree.hashCode, isTrue);
  });

  test("isPreRelease test", () {
    final Version versionOne =
        new Version(1, 0, 0, preRelease: <String>["alpha"]);
    final Version versionTwo = new Version(1, 0, 0);

    expect(versionOne.isPreRelease, isTrue);
    expect(versionTwo.isPreRelease, isFalse);
  });

  test("incrementPreRelease test", () {
    expect(() => new Version(1, 0, 0).incrementPreRelease(), throwsException);

    expect(new Version(1, 0, 0, preRelease: ["beta"]).incrementPreRelease(),
        equals(new Version(1, 0, 0, preRelease: ["beta", "1"])));

    expect(
        new Version(1, 0, 0, preRelease: ["alpha", "3"]).incrementPreRelease(),
        equals(new Version(1, 0, 0, preRelease: ["alpha", "4"])));

    expect(
        new Version(1, 0, 0, preRelease: ["alpha", "9", "omega"])
            .incrementPreRelease(),
        equals(new Version(1, 0, 0, preRelease: ["alpha", "10", "omega"])));

    expect(
        new Version(1, 0, 0, preRelease: ["alpha", "9", "omega"])
                .incrementPreRelease() >
            new Version(1, 0, 0, preRelease: ["alpha", "9", "omega"]),
        isTrue);
  });
}
