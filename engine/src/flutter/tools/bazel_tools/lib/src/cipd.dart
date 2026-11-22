// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'deps_file.dart';

/// The platforms a `${platform}` package is locked for: the hosts gclient
/// syncs this repository on, in CIPD's spelling.
const List<String> cipdPlatforms = <String>[
  'linux-amd64',
  'linux-arm64',
  'mac-amd64',
  'mac-arm64',
  'windows-amd64',
];

const String _platformTemplate = r'${platform}';

/// The key of [package] at [version] in the lock's `CIPD_SHA256`.
///
/// [package] is a fully resolved name (no `${platform}`), [version] the pin
/// exactly as `DEPS` writes it. The key is only ever looked up whole, so the
/// `@` a version may contain (`version:2@1.11.1.chromium.4`) does no harm.
String cipdKey(String package, String version) => '$package@$version';

/// The fully resolved names of [package]: itself, or one per platform of
/// [cipdPlatforms] when the name holds the `${platform}` template.
List<String> expandCipdPackage(String package) {
  if (!package.contains(_platformTemplate)) {
    return <String>[package];
  }
  return <String>[
    for (final String platform in cipdPlatforms) package.replaceAll(_platformTemplate, platform),
  ];
}

/// Every key `CIPD_SHA256` holds for [deps], sorted: each CIPD package at
/// its pinned version, a `${platform}` package once per platform.
List<String> cipdLockKeys(DepsFile deps) {
  final keys = <String>{
    for (final CipdDep dep in deps.cipdDeps)
      for (final CipdPackage package in dep.packages)
        for (final String name in expandCipdPackage(package.package))
          cipdKey(name, package.version),
  };
  return keys.toList()..sort();
}

final RegExp _instanceId = RegExp(r'^[A-Za-z0-9_-]{43}C$');

/// The sha256 (lowercase hex) that [version] names when it is a CIPD
/// instance id, and `null` when it is a tag or a ref.
///
/// An instance id is the URL-safe base64, without padding, of the sha256 of
/// the package's archive followed by one byte for the algorithm (2): 44
/// characters, the last of them `C`. So a pin by instance id carries its own
/// hash and needs no lookup.
String? sha256OfInstanceId(String version) {
  if (!_instanceId.hasMatch(version)) {
    return null;
  }
  final List<int> bytes;
  try {
    bytes = base64Url.decode(version);
  } on FormatException {
    return null;
  }
  if (bytes.length != 33 || bytes.last != 2) {
    return null;
  }
  return <String>[for (final int byte in bytes.take(32)) byte.toRadixString(16).padLeft(2, '0')]
      .join();
}

/// Looks up what CIPD holds for a package at a version.
abstract interface class CipdResolver {
  /// The sha256 (lowercase hex) of the archive CIPD serves for [package] at
  /// [version], or `null` when CIPD has no such package, or none an
  /// anonymous caller may see.
  ///
  /// Throws a [CipdException] when CIPD cannot be asked or answers
  /// something else.
  Future<String?> resolve(String package, String version);
}

/// CIPD could not be asked, or did not answer as expected.
final class CipdException implements Exception {
  /// Creates the exception.
  CipdException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => message;
}

/// The [CipdResolver] that asks CIPD itself, anonymously, over its pRPC API.
final class HttpCipdResolver implements CipdResolver {
  /// Creates a resolver for the CIPD service at [host].
  HttpCipdResolver({this.host = 'chrome-infra-packages.appspot.com', io.HttpClient? client})
    : _client = client ?? io.HttpClient();

  /// The CIPD service.
  final String host;

  final io.HttpClient _client;

  @override
  Future<String?> resolve(String package, String version) async {
    final uri = Uri.https(host, '/prpc/cipd.Repository/ResolveVersion');
    final int status;
    final String body;
    try {
      final io.HttpClientRequest request = await _client.postUrl(uri);
      request.headers.contentType = io.ContentType.json;
      request.headers.set(io.HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(<String, String>{'package': package, 'version': version}));
      final io.HttpClientResponse response = await request.close();
      status = response.statusCode;
      body = await utf8.decodeStream(response);
    } on io.IOException catch (e) {
      throw CipdException('Could not ask $host for $package at $version: $e');
    }
    return parseResolveVersionResponse(status, body, package: package, version: version);
  }

  /// Releases the connection.
  void close() => _client.close();
}

/// What a `ResolveVersion` answer of [status] and [body] says: the sha256 of
/// the instance, `null` for a package CIPD does not have or does not show an
/// anonymous caller (404 and 403), and a [CipdException] for anything else.
String? parseResolveVersionResponse(
  int status,
  String body, {
  required String package,
  required String version,
}) {
  if (status == io.HttpStatus.notFound || status == io.HttpStatus.forbidden) {
    return null;
  }
  if (status != io.HttpStatus.ok) {
    throw CipdException(
      'CIPD answered $status for $package at $version: ${body.trim().split('\n').first}',
    );
  }
  // A pRPC JSON answer starts with the line )]}' against script inclusion.
  final String json = body.startsWith(")]}'") ? body.substring(4) : body;
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e) {
    throw CipdException('CIPD answered something unreadable for $package at $version: $e');
  }
  if (decoded case {'instance': {'hashAlgo': 'SHA256', 'hexDigest': final String digest}}
      when RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
    return digest;
  }
  throw CipdException('CIPD named no sha256 for $package at $version: ${json.trim()}');
}

final RegExp _lockEntry = RegExp(r'^    "((?:[^"\\]|\\.)*)": "([0-9a-f]{64}|)",$');

/// The entries of `CIPD_SHA256` in [lock], the text of a `deps.lock.bzl`;
/// empty when the file has none.
///
/// Reads the dictionary as `generateDepsLock` writes it: one entry per line.
Map<String, String> parseCipdSha256(String lock) {
  final result = <String, String>{};
  var inside = false;
  for (final String line in const LineSplitter().convert(lock)) {
    if (!inside) {
      inside = line == 'CIPD_SHA256 = {';
      continue;
    }
    if (line == '}') {
      break;
    }
    final RegExpMatch? match = _lockEntry.firstMatch(line);
    if (match != null) {
      result[match.group(1)!] = match.group(2)!;
    }
  }
  return result;
}
