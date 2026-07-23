// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// To run this script:
// 1. Navigate to packages/flutter_tools directory.
// 2. Run: dart tool/validate_android_support_versions.dart

import 'dart:convert';
import 'dart:io' as io;
import 'package:file/local.dart';
import 'package:flutter_tools/src/android/android_support_versions.dart';
import 'package:flutter_tools/src/base/version.dart';

Future<void> main() async {
  const fileSystem = LocalFileSystem();
  const jsonPath = 'gradle/src/main/resources/android_support_versions.json';

  if (!fileSystem.file(jsonPath).existsSync()) {
    print('Error: Could not find android_support_versions.json at $jsonPath');
    print('Make sure you are running this script from the packages/flutter_tools directory.');
    io.exit(1);
  }

  print('Loading $jsonPath...');
  final versions = AndroidSupportVersions.load(fileSystem, jsonPath);
  print('Loaded successfully.');

  final client = io.HttpClient();
  var hasErrors = false;

  try {
    hasErrors |= await validateJavaGradle(client, versions.javaGradleCompat);
    hasErrors |= await validateKgpGradle(client, versions.kgpGradleCompat);
    hasErrors |= await validateReachability(
      client,
      'Gradle-AGP Compat',
      versions.gradleAgpCompat.sourceUrl,
    );
    hasErrors |= await validateReachability(
      client,
      'Java-AGP Compat',
      versions.javaAgpCompat.sourceUrl,
    );
    hasErrors |= await validateReachability(
      client,
      'AGP-KGP Compat',
      versions.agpKgpCompat.sourceUrl,
    );
    hasErrors |= await validateReachability(
      client,
      'Gradle Version for AGP',
      versions.gradleVersionForAgp.sourceUrl,
    );
  } finally {
    client.close();
  }

  if (hasErrors) {
    print('\nValidation failed with errors.');
    io.exit(1);
  } else {
    print('\nValidation completed successfully.');
  }
}

Future<String?> fetchHtml(io.HttpClient client, String url) async {
  print('\nFetching $url...');
  try {
    final Uri uri = Uri.parse(url);
    final io.HttpClientRequest request = await client.getUrl(uri);
    final io.HttpClientResponse response = await request.close();
    if (response.statusCode != 200) {
      print('Error: Failed to fetch $url: HTTP ${response.statusCode}');
      return null;
    }
    final String html = await response.transform(const Utf8Decoder()).join();
    return html;
  } on Exception catch (e) {
    print('Error: Failed to fetch $url: $e');
    return null;
  }
}

Future<bool> validateReachability(io.HttpClient client, String name, String url) async {
  print('\nChecking reachability for $name: $url');
  try {
    final Uri uri = Uri.parse(url);
    final io.HttpClientRequest request = await client.headUrl(uri);
    final io.HttpClientResponse response = await request.close();
    if (response.statusCode >= 200 && response.statusCode < 400) {
      print('  Reachability OK (HTTP ${response.statusCode})');
      return false;
    }
    print('Error: URL not reachable (HTTP ${response.statusCode}): $url');
    return true;
  } on Exception catch (e) {
    print('Error: Failed to connect to $url: $e');
    return true;
  }
}

bool compareMinVersion(String jsonMinStr, String docMinStr) {
  final Version? jsonMin = Version.parse(jsonMinStr);
  final Version? docMin = Version.parse(docMinStr);
  if (jsonMin == null || docMin == null) {
    return false;
  }
  return jsonMin >= docMin;
}

bool compareMaxVersion(String jsonMaxStr, String docMaxStr, {bool inclusive = true}) {
  final Version? jsonMax = Version.parse(jsonMaxStr);
  final String cleanDocMaxStr = docMaxStr.replaceAll('*', '').replaceAll('.x', '');
  final Version? docMax = Version.parse(cleanDocMaxStr);

  if (jsonMax == null || docMax == null) {
    return false;
  }

  if (inclusive) {
    return jsonMax.major == docMax.major && jsonMax.minor == docMax.minor;
  } else {
    // If non-inclusive, JSON max should be the next minor version of doc max.
    if (jsonMax.major == docMax.major && jsonMax.minor == docMax.minor + 1 && jsonMax.patch == 0) {
      return true;
    }
    // Handle X.Y.99 non-inclusive as equivalent to X.Y.x.
    if (jsonMax.major == docMax.major && jsonMax.minor == docMax.minor && jsonMax.patch == 99) {
      return true;
    }
    // Handle X.Y.99 non-inclusive when doc is X.Y.Z (e.g. 9.5.99 for 9.5.0).
    if (jsonMax.major == docMax.major &&
        jsonMax.minor == docMax.minor &&
        jsonMax.patch >= docMax.patch) {
      return true;
    }
    return false;
  }
}

Future<bool> validateJavaGradle(io.HttpClient client, CompatMatrix<JavaGradleCompat> matrix) async {
  final String? html = await fetchHtml(client, matrix.sourceUrl);
  if (html == null) {
    return true;
  }

  print('Validating Java-Gradle compatibility matrix...');

  final rowRegex = RegExp(
    r'<tr>\s*<td[^>]*><p[^>]*>(\d+)</p></td>\s*<td[^>]*><p[^>]*>[^<]*</p></td>\s*<td[^>]*><p[^>]*>([^<]+)</p></td>\s*</tr>',
    multiLine: true,
    dotAll: true,
  );

  final documentedRules = <Map<String, String>>[];
  for (final Match match in rowRegex.allMatches(html)) {
    final String javaVersion = match.group(1)!;
    final String gradleRange = match.group(2)!.trim();
    documentedRules.add(<String, String>{'java': javaVersion, 'gradle': gradleRange});
  }

  if (documentedRules.isEmpty) {
    print(
      'Warning: Could not parse any rules from ${matrix.sourceUrl}. The page structure might have changed.',
    );
    return false;
  }

  print('Found ${documentedRules.length} Java-Gradle rules in documentation.');
  var errorsFound = false;

  // ignore: specify_nonobvious_local_variable_types
  for (final rule in matrix.rules) {
    final String docJavaVersion = rule.javaMin.startsWith('1.')
        ? rule.javaMin.substring(2)
        : rule.javaMin;

    Map<String, String>? docRule;
    for (final element in documentedRules) {
      if (element['java'] == docJavaVersion) {
        docRule = element;
        break;
      }
    }

    if (docRule == null) {
      print(
        'Warning: Java version $docJavaVersion (from JSON ${rule.javaMin}) not found in Gradle compatibility table.',
      );
      continue;
    }

    final String gradleRange = docRule['gradle']!;
    print(
      'Checking JSON rule (Java ${rule.javaMin} -> Gradle [${rule.gradleMin} - ${rule.gradleMax ?? 'unspecified'}]) against doc: "$gradleRange"',
    );

    if (gradleRange.contains('to')) {
      final List<String> parts = gradleRange.split('to');
      final String minGradle = parts[0].trim();
      final String maxGradle = parts[1].trim();

      if (!compareMinVersion(rule.gradleMin, minGradle)) {
        print(
          '  Error: Java ${rule.javaMin} minimum Gradle version mismatch. JSON: ${rule.gradleMin}, Doc: $minGradle',
        );
        errorsFound = true;
      }
      if (rule.gradleMax != null && !compareMaxVersion(rule.gradleMax!, maxGradle)) {
        print(
          '  Error: Java ${rule.javaMin} maximum Gradle version mismatch. JSON: ${rule.gradleMax}, Doc: $maxGradle',
        );
        errorsFound = true;
      }
    } else if (gradleRange.contains('and after')) {
      final String minGradle = gradleRange.replaceAll('and after', '').trim();
      if (!compareMinVersion(rule.gradleMin, minGradle)) {
        print(
          '  Error: Java ${rule.javaMin} minimum Gradle version mismatch. JSON: ${rule.gradleMin}, Doc: $minGradle',
        );
        errorsFound = true;
      }
    }
  }
  return errorsFound;
}

Future<bool> validateKgpGradle(io.HttpClient client, CompatMatrix<KgpGradleCompat> matrix) async {
  final String? html = await fetchHtml(client, matrix.sourceUrl);
  if (html == null) {
    return true;
  }

  print('Validating Kotlin-Gradle compatibility matrix...');

  final rowRegex = RegExp(
    r'<tr[^>]*>\s*<td[^>]*>\s*<p>(.*?)</p>\s*</td>\s*<td[^>]*>\s*<p>(.*?)</p>\s*</td>\s*<td[^>]*>\s*<p>(.*?)</p>\s*</td>\s*</tr>',
    multiLine: true,
    dotAll: true,
  );

  final documentedRules = <Map<String, String>>[];
  for (final Match match in rowRegex.allMatches(html)) {
    final String kgpRange = match.group(1)!.trim();
    final String gradleRange = match.group(2)!.trim();
    final String agpRange = match.group(3)!.trim();
    documentedRules.add(<String, String>{'kgp': kgpRange, 'gradle': gradleRange, 'agp': agpRange});
  }

  if (documentedRules.isEmpty) {
    print(
      'Warning: Could not parse any rules from ${matrix.sourceUrl}. The page structure might have changed.',
    );
    return false;
  }

  print('Found ${documentedRules.length} Kotlin-Gradle-AGP rules in documentation.');
  var errorsFound = false;

  // ignore: specify_nonobvious_local_variable_types
  for (final rule in matrix.rules) {
    Map<String, String>? docRule;
    for (final candidate in documentedRules) {
      final String kgpDocRange = candidate['kgp']!;
      final String cleanKgpRange = kgpDocRange.replaceAll('&ndash;', '-').replaceAll('–', '-');
      final List<String> parts = cleanKgpRange.split('-');
      if (parts.length == 2) {
        final String minKgp = parts[0].trim();
        if (rule.kgpMin.startsWith(minKgp)) {
          docRule = candidate;
          break;
        }
      } else if (cleanKgpRange == rule.kgpMin) {
        docRule = candidate;
        break;
      }
    }

    if (docRule == null) {
      print(
        'Warning: KGP version range ${rule.kgpMin}-${rule.kgpMax} not found in Kotlin compatibility table.',
      );
      continue;
    }

    final String gradleDocRange = docRule['gradle']!
        .replaceAll('&ndash;', '-')
        .replaceAll('–', '-');
    print(
      'Checking JSON rule (KGP ${rule.kgpMin}-${rule.kgpMax} -> Gradle [${rule.gradleMin} - ${rule.gradleMax}]) against doc: "$gradleDocRange"',
    );

    final List<String> parts = gradleDocRange.split('-');
    if (parts.length == 2) {
      final String minGradle = parts[0].trim();
      final String maxGradle = parts[1].trim();

      if (!compareMinVersion(rule.gradleMin, minGradle)) {
        print(
          '  Error: KGP ${rule.kgpMin} minimum Gradle version mismatch. JSON: ${rule.gradleMin}, Doc: $minGradle',
        );
        errorsFound = true;
      }

      if (!compareMaxVersion(rule.gradleMax, maxGradle, inclusive: rule.inclusiveMaxGradle)) {
        print(
          '  Error: KGP ${rule.kgpMin} maximum Gradle version mismatch. JSON: ${rule.gradleMax}, Doc: $maxGradle',
        );
        errorsFound = true;
      }
    }
  }
  return errorsFound;
}
