// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>?> getJson(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode == 200) {
      final content = await response.transform(utf8.decoder).join();
      final dynamic decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
  } catch (e) {
    stderr.writeln('Error fetching data from $url: $e');
  } finally {
    client.close();
  }
  return null;
}

Future<String?> fetchChromeLatest() async {
  final data = await getJson(
    'https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions.json',
  );
  if (data case {'channels': {'Stable': {'version': String version}}}) {
    return version;
  }
  return null;
}

Future<String?> fetchFirefoxLatest() async {
  final data = await getJson('https://product-details.mozilla.org/1.0/firefox_versions.json');
  if (data case {'LATEST_FIREFOX_VERSION': String version}) {
    return version;
  }
  return null;
}

Future<bool> verifyChromeVersion(String version) async {
  final data = await getJson(
    'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions.json',
  );
  if (data case {'versions': List versions}) {
    return versions.any((v) => v is Map && v['version'] == version);
  }
  return false;
}

Future<bool> verifyFirefoxVersion(String version) async {
  final majorReleases = await getJson(
    'https://product-details.mozilla.org/1.0/firefox_history_major_releases.json',
  );
  if (majorReleases != null && majorReleases.keys.contains(version)) {
    return true;
  }
  final stabilityReleases = await getJson(
    'https://product-details.mozilla.org/1.0/firefox_history_stability_releases.json',
  );
  if (stabilityReleases != null && stabilityReleases.keys.contains(version)) {
    return true;
  }
  return false;
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart fetch_versions.dart latest <chrome|firefox>');
    print('  dart fetch_versions.dart verify <chrome|firefox> <version>');
    exit(1);
  }

  final cmd = args[0].toLowerCase();

  if (cmd == 'latest') {
    final target = args.length > 1 ? args[1].toLowerCase() : null;
    if (target == 'chrome') {
      print(await fetchChromeLatest());
    } else if (target == 'firefox') {
      print(await fetchFirefoxLatest());
    } else {
      final versions = {'chrome': await fetchChromeLatest(), 'firefox': await fetchFirefoxLatest()};
      print(json.encode(versions));
    }
  } else if (cmd == 'verify') {
    if (args.length < 3) {
      print('Error: Missing version to verify.');
      exit(1);
    }
    final target = args[1].toLowerCase();
    final version = args[2];
    bool exists = false;
    if (target == 'chrome') {
      exists = await verifyChromeVersion(version);
    } else if (target == 'firefox') {
      exists = await verifyFirefoxVersion(version);
    } else {
      print('Unknown target: $target');
      exit(1);
    }
    print(exists);
  } else {
    print('Unknown command: $cmd');
    exit(1);
  }
}
