// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Co-evolve with packages/flutter_tools/gradle/src/main/kotlin/AndroidSupportVersions.kt

import 'dart:convert';
import 'package:meta/meta.dart';
import '../base/file_system.dart';

@immutable
class VersionThresholds {
  const VersionThresholds({required this.warn, required this.error});

  factory VersionThresholds.fromJson(Map<String, dynamic> json) {
    if (json case {'warn': final String warn, 'error': final String error}) {
      return VersionThresholds(warn: warn, error: error);
    }
    throw FormatException('Invalid VersionThresholds JSON: $json');
  }

  final String warn;
  final String error;

  @override
  bool operator ==(Object other) =>
      other is VersionThresholds && other.warn == warn && other.error == error;

  @override
  int get hashCode => Object.hash(warn, error);

  @override
  String toString() => 'VersionThresholds(warn: $warn, error: $error)';
}

@immutable
class MinSdkThresholds {
  const MinSdkThresholds({required this.warn, required this.error});

  factory MinSdkThresholds.fromJson(Map<String, dynamic> json) {
    if (json case {'warn': final int warn, 'error': final int error}) {
      return MinSdkThresholds(warn: warn, error: error);
    }
    throw FormatException('Invalid MinSdkThresholds JSON: $json');
  }

  final int warn;
  final int error;

  @override
  bool operator ==(Object other) =>
      other is MinSdkThresholds && other.warn == warn && other.error == error;

  @override
  int get hashCode => Object.hash(warn, error);

  @override
  String toString() => 'MinSdkThresholds(warn: $warn, error: $error)';
}

@immutable
class MaxKnownVersions {
  const MaxKnownVersions({
    required this.gradle,
    required this.kgp,
    required this.agp,
    required this.agpWithKotlin,
  });

  factory MaxKnownVersions.fromJson(Map<String, dynamic> json) {
    if (json case {
      'gradle': final String gradle,
      'kgp': final String kgp,
      'agp': final String agp,
      'agpWithKotlin': final String agpWithKotlin,
    }) {
      return MaxKnownVersions(
        gradle: gradle,
        kgp: kgp,
        agp: agp,
        agpWithKotlin: agpWithKotlin,
      );
    }
    throw FormatException('Invalid MaxKnownVersions JSON: $json');
  }

  final String gradle;
  final String kgp;
  final String agp;
  final String agpWithKotlin;

  @override
  bool operator ==(Object other) =>
      other is MaxKnownVersions &&
      other.gradle == gradle &&
      other.kgp == kgp &&
      other.agp == agp &&
      other.agpWithKotlin == agpWithKotlin;

  @override
  int get hashCode => Object.hash(gradle, kgp, agp, agpWithKotlin);

  @override
  String toString() =>
      'MaxKnownVersions(gradle: $gradle, kgp: $kgp, agp: $agp, agpWithKotlin: $agpWithKotlin)';
}

@immutable
class OldestConsideredVersions {
  const OldestConsideredVersions({
    required this.gradle,
    required this.agp,
    required this.kgp,
    required this.javaAgp,
    required this.java,
    required this.javaGradle,
  });

  factory OldestConsideredVersions.fromJson(Map<String, dynamic> json) {
    if (json case {
      'gradle': final String gradle,
      'agp': final String agp,
      'kgp': final String kgp,
      'javaAgp': final String javaAgp,
      'java': final String java,
      'javaGradle': final String javaGradle,
    }) {
      return OldestConsideredVersions(
        gradle: gradle,
        agp: agp,
        kgp: kgp,
        javaAgp: javaAgp,
        java: java,
        javaGradle: javaGradle,
      );
    }
    throw FormatException('Invalid OldestConsideredVersions JSON: $json');
  }

  final String gradle;
  final String agp;
  final String kgp;
  final String javaAgp;
  final String java;
  final String javaGradle;

  @override
  bool operator ==(Object other) =>
      other is OldestConsideredVersions &&
      other.gradle == gradle &&
      other.agp == agp &&
      other.kgp == kgp &&
      other.javaAgp == javaAgp &&
      other.java == java &&
      other.javaGradle == javaGradle;

  @override
  int get hashCode => Object.hash(gradle, agp, kgp, javaAgp, java, javaGradle);

  @override
  String toString() =>
      'OldestConsideredVersions(gradle: $gradle, agp: $agp, kgp: $kgp, javaAgp: $javaAgp, java: $java, javaGradle: $javaGradle)';
}

@immutable
class GradleAgpCompat {
  const GradleAgpCompat({
    required this.agpMin,
    required this.agpMax,
    required this.gradleMin,
    this.inclusiveMaxAgp = true,
  });

  factory GradleAgpCompat.fromJson(Map<String, dynamic> json) {
    if (json case {
      'agpMin': final String agpMin,
      'agpMax': final String agpMax,
      'gradleMin': final String gradleMin,
    }) {
      return GradleAgpCompat(
        agpMin: agpMin,
        agpMax: agpMax,
        gradleMin: gradleMin,
        inclusiveMaxAgp: json['inclusiveMaxAgp'] as bool? ?? true,
      );
    }
    throw FormatException('Invalid GradleAgpCompat JSON: $json');
  }

  final String agpMin;
  final String agpMax;
  final String gradleMin;
  final bool inclusiveMaxAgp;

  @override
  bool operator ==(Object other) =>
      other is GradleAgpCompat &&
      other.agpMin == agpMin &&
      other.agpMax == agpMax &&
      other.gradleMin == gradleMin &&
      other.inclusiveMaxAgp == inclusiveMaxAgp;

  @override
  int get hashCode => Object.hash(agpMin, agpMax, gradleMin, inclusiveMaxAgp);

  @override
  String toString() =>
      'GradleAgpCompat(agpMin: $agpMin, agpMax: $agpMax, gradleMin: $gradleMin, inclusiveMaxAgp: $inclusiveMaxAgp)';
}

@immutable
class GradleVersionForAgp {
  const GradleVersionForAgp({
    required this.agpMin,
    required this.agpMax,
    required this.minRequiredGradle,
  });

  factory GradleVersionForAgp.fromJson(Map<String, dynamic> json) {
    if (json case {
      'agpMin': final String agpMin,
      'agpMax': final String agpMax,
      'minRequiredGradle': final String minRequiredGradle,
    }) {
      return GradleVersionForAgp(
        agpMin: agpMin,
        agpMax: agpMax,
        minRequiredGradle: minRequiredGradle,
      );
    }
    throw FormatException('Invalid GradleVersionForAgp JSON: $json');
  }

  final String agpMin;
  final String agpMax;
  final String minRequiredGradle;

  @override
  bool operator ==(Object other) =>
      other is GradleVersionForAgp &&
      other.agpMin == agpMin &&
      other.agpMax == agpMax &&
      other.minRequiredGradle == minRequiredGradle;

  @override
  int get hashCode => Object.hash(agpMin, agpMax, minRequiredGradle);

  @override
  String toString() =>
      'GradleVersionForAgp(agpMin: $agpMin, agpMax: $agpMax, minRequiredGradle: $minRequiredGradle)';
}

@immutable
class JavaGradleCompat {
  const JavaGradleCompat({
    required this.javaMin,
    required this.javaMax,
    required this.gradleMin,
    this.gradleMax,
  });

  factory JavaGradleCompat.fromJson(Map<String, dynamic> json) {
    if (json case {
      'javaMin': final String javaMin,
      'javaMax': final String javaMax,
      'gradleMin': final String gradleMin,
    }) {
      return JavaGradleCompat(
        javaMin: javaMin,
        javaMax: javaMax,
        gradleMin: gradleMin,
        gradleMax: json['gradleMax'] as String?,
      );
    }
    throw FormatException('Invalid JavaGradleCompat JSON: $json');
  }

  final String javaMin;
  final String javaMax;
  final String gradleMin;
  final String? gradleMax;

  @override
  bool operator ==(Object other) =>
      other is JavaGradleCompat &&
      other.javaMin == javaMin &&
      other.javaMax == javaMax &&
      other.gradleMin == gradleMin &&
      other.gradleMax == gradleMax;

  @override
  int get hashCode => Object.hash(javaMin, javaMax, gradleMin, gradleMax);

  @override
  String toString() =>
      'JavaGradleCompat(javaMin: $javaMin, javaMax: $javaMax, gradleMin: $gradleMin, gradleMax: $gradleMax)';
}

@immutable
class JavaAgpCompat {
  const JavaAgpCompat({
    required this.javaMin,
    required this.javaDefault,
    required this.agpMin,
    required this.agpMax,
  });

  factory JavaAgpCompat.fromJson(Map<String, dynamic> json) {
    if (json case {
      'javaMin': final String javaMin,
      'javaDefault': final String javaDefault,
      'agpMin': final String agpMin,
      'agpMax': final String agpMax,
    }) {
      return JavaAgpCompat(
        javaMin: javaMin,
        javaDefault: javaDefault,
        agpMin: agpMin,
        agpMax: agpMax,
      );
    }
    throw FormatException('Invalid JavaAgpCompat JSON: $json');
  }

  final String javaMin;
  final String javaDefault;
  final String agpMin;
  final String agpMax;

  @override
  bool operator ==(Object other) =>
      other is JavaAgpCompat &&
      other.javaMin == javaMin &&
      other.javaDefault == javaDefault &&
      other.agpMin == agpMin &&
      other.agpMax == agpMax;

  @override
  int get hashCode => Object.hash(javaMin, javaDefault, agpMin, agpMax);

  @override
  String toString() =>
      'JavaAgpCompat(javaMin: $javaMin, javaDefault: $javaDefault, agpMin: $agpMin, agpMax: $agpMax)';
}

@immutable
class KgpGradleCompat {
  const KgpGradleCompat({
    required this.kgpMin,
    required this.kgpMax,
    required this.gradleMin,
    required this.gradleMax,
    this.inclusiveMaxKgp = true,
    this.inclusiveMaxGradle = true,
  });

  factory KgpGradleCompat.fromJson(Map<String, dynamic> json) {
    if (json case {
      'kgpMin': final String kgpMin,
      'kgpMax': final String kgpMax,
      'gradleMin': final String gradleMin,
      'gradleMax': final String gradleMax,
    }) {
      return KgpGradleCompat(
        kgpMin: kgpMin,
        kgpMax: kgpMax,
        gradleMin: gradleMin,
        gradleMax: gradleMax,
        inclusiveMaxKgp: json['inclusiveMaxKgp'] as bool? ?? true,
        inclusiveMaxGradle: json['inclusiveMaxGradle'] as bool? ?? true,
      );
    }
    throw FormatException('Invalid KgpGradleCompat JSON: $json');
  }

  final String kgpMin;
  final String kgpMax;
  final String gradleMin;
  final String gradleMax;
  final bool inclusiveMaxKgp;
  final bool inclusiveMaxGradle;

  @override
  bool operator ==(Object other) =>
      other is KgpGradleCompat &&
      other.kgpMin == kgpMin &&
      other.kgpMax == kgpMax &&
      other.gradleMin == gradleMin &&
      other.gradleMax == gradleMax &&
      other.inclusiveMaxKgp == inclusiveMaxKgp &&
      other.inclusiveMaxGradle == inclusiveMaxGradle;

  @override
  int get hashCode =>
      Object.hash(kgpMin, kgpMax, gradleMin, gradleMax, inclusiveMaxKgp, inclusiveMaxGradle);

  @override
  String toString() =>
      'KgpGradleCompat(kgpMin: $kgpMin, kgpMax: $kgpMax, gradleMin: $gradleMin, gradleMax: $gradleMax, inclusiveMaxKgp: $inclusiveMaxKgp, inclusiveMaxGradle: $inclusiveMaxGradle)';
}

@immutable
class AgpKgpCompat {
  const AgpKgpCompat({
    required this.kgpMin,
    required this.kgpMax,
    required this.agpMin,
    required this.agpMax,
    this.inclusiveMaxKgp = true,
    this.inclusiveMaxAgp = true,
  });

  factory AgpKgpCompat.fromJson(Map<String, dynamic> json) {
    if (json case {
      'kgpMin': final String kgpMin,
      'kgpMax': final String kgpMax,
      'agpMin': final String agpMin,
      'agpMax': final String agpMax,
    }) {
      return AgpKgpCompat(
        kgpMin: kgpMin,
        kgpMax: kgpMax,
        agpMin: agpMin,
        agpMax: agpMax,
        inclusiveMaxKgp: json['inclusiveMaxKgp'] as bool? ?? true,
        inclusiveMaxAgp: json['inclusiveMaxAgp'] as bool? ?? true,
      );
    }
    throw FormatException('Invalid AgpKgpCompat JSON: $json');
  }

  final String kgpMin;
  final String kgpMax;
  final String agpMin;
  final String agpMax;
  final bool inclusiveMaxKgp;
  final bool inclusiveMaxAgp;

  @override
  bool operator ==(Object other) =>
      other is AgpKgpCompat &&
      other.kgpMin == kgpMin &&
      other.kgpMax == kgpMax &&
      other.agpMin == agpMin &&
      other.agpMax == agpMax &&
      other.inclusiveMaxKgp == inclusiveMaxKgp &&
      other.inclusiveMaxAgp == inclusiveMaxAgp;

  @override
  int get hashCode => Object.hash(kgpMin, kgpMax, agpMin, agpMax, inclusiveMaxKgp, inclusiveMaxAgp);

  @override
  String toString() =>
      'AgpKgpCompat(kgpMin: $kgpMin, kgpMax: $kgpMax, agpMin: $agpMin, agpMax: $agpMax, inclusiveMaxKgp: $inclusiveMaxKgp, inclusiveMaxAgp: $inclusiveMaxAgp)';
}

class AndroidSupportVersions {
  AndroidSupportVersions({
    required this.gradle,
    required this.java,
    required this.agp,
    required this.kgp,
    required this.minSdkVersion,
    required this.maxKnownVersions,
    required this.oldestConsideredVersions,
    required this.oneMajorVersionHigherJavaVersion,
    required this.gradleAgpCompat,
    required this.javaGradleCompat,
    required this.javaAgpCompat,
    required this.kgpGradleCompat,
    required this.agpKgpCompat,
    required this.gradleVersionForAgp,
  });

  factory AndroidSupportVersions.fromJson(Map<String, dynamic> json) {
    if (json case {
      'gradle': final Map<String, dynamic> gradle,
      'java': final Map<String, dynamic> java,
      'agp': final Map<String, dynamic> agp,
      'kgp': final Map<String, dynamic> kgp,
      'minSdkVersion': final Map<String, dynamic> minSdkVersion,
      'maxKnownVersions': final Map<String, dynamic> maxKnownVersions,
      'oldestConsideredVersions': final Map<String, dynamic> oldestConsideredVersions,
      'oneMajorVersionHigherJavaVersion': final String oneMajorVersionHigherJavaVersion,
      'gradleAgpCompat': final List<dynamic> gradleAgpCompat,
      'javaGradleCompat': final List<dynamic> javaGradleCompat,
      'javaAgpCompat': final List<dynamic> javaAgpCompat,
      'kgpGradleCompat': final List<dynamic> kgpGradleCompat,
      'agpKgpCompat': final List<dynamic> agpKgpCompat,
      'gradleVersionForAgp': final List<dynamic> gradleVersionForAgp,
    }) {
      return AndroidSupportVersions(
        gradle: VersionThresholds.fromJson(gradle),
        java: VersionThresholds.fromJson(java),
        agp: VersionThresholds.fromJson(agp),
        kgp: VersionThresholds.fromJson(kgp),
        minSdkVersion: MinSdkThresholds.fromJson(minSdkVersion),
        maxKnownVersions: MaxKnownVersions.fromJson(maxKnownVersions),
        oldestConsideredVersions: OldestConsideredVersions.fromJson(oldestConsideredVersions),
        oneMajorVersionHigherJavaVersion: oneMajorVersionHigherJavaVersion,
        gradleAgpCompat: gradleAgpCompat.map((e) => GradleAgpCompat.fromJson(e as Map<String, dynamic>)).toList(),
        javaGradleCompat: javaGradleCompat.map((e) => JavaGradleCompat.fromJson(e as Map<String, dynamic>)).toList(),
        javaAgpCompat: javaAgpCompat.map((e) => JavaAgpCompat.fromJson(e as Map<String, dynamic>)).toList(),
        kgpGradleCompat: kgpGradleCompat.map((e) => KgpGradleCompat.fromJson(e as Map<String, dynamic>)).toList(),
        agpKgpCompat: agpKgpCompat.map((e) => AgpKgpCompat.fromJson(e as Map<String, dynamic>)).toList(),
        gradleVersionForAgp: gradleVersionForAgp.map((e) => GradleVersionForAgp.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    throw const FormatException('Invalid AndroidSupportVersions JSON');
  }

  factory AndroidSupportVersions.load(FileSystem fileSystem, String path) {
    final String content = fileSystem.file(path).readAsStringSync();
    return AndroidSupportVersions.fromJson(json.decode(content) as Map<String, dynamic>);
  }

  final VersionThresholds gradle;
  final VersionThresholds java;
  final VersionThresholds agp;
  final VersionThresholds kgp;
  final MinSdkThresholds minSdkVersion;
  final MaxKnownVersions maxKnownVersions;
  final OldestConsideredVersions oldestConsideredVersions;
  final String oneMajorVersionHigherJavaVersion;
  final List<GradleAgpCompat> gradleAgpCompat;
  final List<JavaGradleCompat> javaGradleCompat;
  final List<JavaAgpCompat> javaAgpCompat;
  final List<KgpGradleCompat> kgpGradleCompat;
  final List<AgpKgpCompat> agpKgpCompat;
  final List<GradleVersionForAgp> gradleVersionForAgp;
}
