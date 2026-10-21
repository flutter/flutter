// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Host platforms that Flutter tools can be executed on.
enum HostPlatform {
  darwin_x64,
  darwin_arm64,
  linux_x64,
  linux_arm64,
  linux_riscv64,
  windows_x64,
  windows_arm64;

  /// Parses a [HostPlatform] from its [cliName] or enum [name].
  ///
  /// Throws a [FormatException] if [name] does not match a known host platform.
  factory HostPlatform.fromName(String name) {
    return tryFromName(name) ?? (throw FormatException('Unsupported host platform: "$name"'));
  }

  /// Architecture name of the host platform (e.g. `'x64'`, `'arm64'`, `'riscv64'`).
  String get platformName => switch (this) {
    darwin_x64 || windows_x64 || linux_x64 => 'x64',
    darwin_arm64 || windows_arm64 || linux_arm64 => 'arm64',
    linux_riscv64 => 'riscv64',
  };

  /// Returns the hyphen-delimited CLI representation (e.g. `'linux-x64'`).
  String get cliName => name.replaceAll('_', '-');

  /// Parses a [HostPlatform] from its [cliName] or enum [name], or returns `null` if invalid.
  static HostPlatform? tryFromName(String name) {
    final String normalized = name.replaceAll('-', '_');
    for (final HostPlatform value in HostPlatform.values) {
      if (value.name == normalized) {
        return value;
      }
    }
    return null;
  }

  /// Returns the host platform for the specified OS and architecture.
  ///
  /// [os] is an operating system name as returned by `Platform.operatingSystem`.
  /// [arch] is an architecture name matching the [platformName] of one of the
  /// values of this enum. Returns `null` if no match is found.
  static HostPlatform? fromOsAndArch(String os, String arch) {
    return switch ((os, arch.toLowerCase())) {
      ('macos', 'x64') => darwin_x64,
      ('macos', 'arm64') => darwin_arm64,
      ('linux', 'x64') => linux_x64,
      ('linux', 'arm64') => linux_arm64,
      ('linux', 'riscv64') => linux_riscv64,
      ('windows', 'x64') => windows_x64,
      ('windows', 'arm64') => windows_arm64,
      _ => null,
    };
  }
}

/// Representation of an artifact dependency required by a tool extension.
@immutable
class ArtifactDependency {
  const ArtifactDependency({
    required this.name,
    required this.sha256,
    required this.url,
    this.hostPlatform,
    this.targetPlatform,
  });

  /// Deserializes an [ArtifactDependency] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if any required field is missing or invalid.
  factory ArtifactDependency.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (!isValidSinglePathSegment(name)) {
      throw FormatException('Invalid artifact dependency name: "$name"');
    }
    final String sha256 = json.requiredField<String>(sha256Key);
    if (!_sha256RegExp.hasMatch(sha256)) {
      throw FormatException(
        'Invalid artifact dependency sha256 (expected 64 hex characters): "$sha256"',
      );
    }
    final String urlStr = json.requiredField<String>(urlKey);
    final Uri? uri = Uri.tryParse(urlStr);
    if (uri == null || (!uri.isScheme(_httpScheme) && !uri.isScheme(_httpsScheme))) {
      throw FormatException('Invalid artifact dependency URL (expected http/https): "$urlStr"');
    }
    final String? hostPlatformName = json.nullableField<String>(hostPlatformKey);
    return ArtifactDependency(
      name: name,
      sha256: sha256,
      url: uri,
      hostPlatform: hostPlatformName != null ? HostPlatform.fromName(hostPlatformName) : null,
      targetPlatform: json.nullableField<String>(targetPlatformKey),
    );
  }

  static const String _httpScheme = 'http';
  static const String _httpsScheme = 'https';
  static final RegExp _sha256RegExp = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Returns whether [value] is a non-empty single path segment without
  /// directory traversal or path separators.
  static bool isValidSinglePathSegment(String value) {
    final String trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed == value &&
        value != '.' &&
        value != '..' &&
        !value.contains('/') &&
        !value.contains(r'\');
  }

  /// Map key for [hostPlatform].
  static const String hostPlatformKey = 'hostPlatform';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [sha256].
  static const String sha256Key = 'sha256';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Map key for [url].
  static const String urlKey = 'url';

  /// Deserializes a list of [ArtifactDependency] objects from RPC response data.
  static List<ArtifactDependency> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ArtifactDependency>[
        for (final item in list)
          if (item case final Map<String, Object?> map) ArtifactDependency.fromJson(map),
      ];
    }
    return const <ArtifactDependency>[];
  }

  /// The name of the artifact.
  final String name;

  /// The download URL for the artifact.
  final Uri url;

  /// The SHA-256 checksum of the artifact.
  final String sha256;

  /// Optional host platform this artifact is intended for.
  final HostPlatform? hostPlatform;

  /// Optional target platform identifier this artifact is intended for
  /// (e.g. `'linux-x64'` or `'custom-embedder-arm64'`).
  ///
  /// This is a [String] rather than a closed `TargetPlatform` enum because tool
  /// extensions may target custom out-of-tree embedders as well as built-in
  /// platform families (matching both exact identifiers and `<os>-<arch>`
  /// prefixes such as `'linux'` matching `'linux-x64'`).
  final String? targetPlatform;

  /// Returns whether this artifact matches [currentHostPlatform] and optional
  /// [targetPlatforms].
  ///
  /// When [targetPlatforms] is provided and [targetPlatform] is non-null, a
  /// target platform matches if it equals [targetPlatform] or is an `<os>`
  /// prefix of `<os>-<arch>` (e.g. `'linux'` matches `'linux-x64'`).
  bool matchesPlatforms({required HostPlatform currentHostPlatform, Set<String>? targetPlatforms}) {
    if (hostPlatform != null && hostPlatform != currentHostPlatform) {
      return false;
    }
    if (targetPlatforms != null && targetPlatform != null) {
      final String depTarget = targetPlatform!;
      return targetPlatforms.contains(depTarget) ||
          targetPlatforms.any((String p) => depTarget.startsWith('$p-'));
    }
    return true;
  }

  /// Serializes the artifact dependency to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    urlKey: url.toString(),
    sha256Key: sha256,
    hostPlatformKey: ?hostPlatform?.cliName,
    targetPlatformKey: ?targetPlatform,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ArtifactDependency &&
            other.name == name &&
            other.url == url &&
            other.sha256 == sha256 &&
            other.hostPlatform == hostPlatform &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hash(name, url, sha256, hostPlatform, targetPlatform);

  @override
  String toString() =>
      'ArtifactDependency(name: $name, url: $url, sha256: $sha256, '
      'hostPlatform: $hostPlatform, targetPlatform: $targetPlatform)';
}
