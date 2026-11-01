// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Host platforms that Flutter tools and extensions can be executed on.
///
/// Built-in host platforms are exposed as static constants (e.g. [linux_x64],
/// [darwin_arm64]), while extensions running on non-standard host platforms can
/// construct or parse custom `<os>-<arch>` identifiers (e.g.
/// `HostPlatform('freebsd-x64', 'x64')`).
@immutable
final class HostPlatform {
  /// Creates a [HostPlatform] with the given lowercase `<os>-<arch>` [cliName]
  /// (e.g. `'linux-x64'` or `'freebsd-x64'`) and architecture [platformName]
  /// matching the `<arch>` segment (e.g. `'x64'`).
  const HostPlatform(this.cliName, this.platformName)
    : assert(cliName.length > 0),
      assert(platformName.length > 0);

  /// Parses a [HostPlatform] from its [cliName] (e.g. `'linux-x64'`) or
  /// underscore-delimited [name] (e.g. `'linux_x64'`).
  ///
  /// Throws a [FormatException] if [name] is not a valid `<os>-<arch>` or
  /// `<os>_<arch>` host platform identifier.
  factory HostPlatform.fromName(String name) {
    return tryFromName(name) ?? (throw FormatException('Invalid host platform: "$name"'));
  }

  static const darwin_x64 = HostPlatform('darwin-x64', 'x64');
  static const darwin_arm64 = HostPlatform('darwin-arm64', 'arm64');
  static const linux_x64 = HostPlatform('linux-x64', 'x64');
  static const linux_arm64 = HostPlatform('linux-arm64', 'arm64');
  static const linux_riscv64 = HostPlatform('linux-riscv64', 'riscv64');
  static const windows_x64 = HostPlatform('windows-x64', 'x64');
  static const windows_arm64 = HostPlatform('windows-arm64', 'arm64');

  /// Standard built-in host platforms supported by the Flutter tool.
  static const values = <HostPlatform>[
    darwin_x64,
    darwin_arm64,
    linux_x64,
    linux_arm64,
    linux_riscv64,
    windows_x64,
    windows_arm64,
  ];

  // Matches a lowercase alphanumeric <os> and <arch> separated by a single '-' or '_'.
  static final RegExp _validNameRegExp = RegExp(r'^[a-z0-9]+[-_][a-z0-9]+$');

  /// The hyphen-delimited CLI representation (e.g. `'linux-x64'`).
  final String cliName;

  /// Architecture name of the host platform (e.g. `'x64'`, `'arm64'`, `'riscv64'`).
  final String platformName;

  /// The underscore-delimited representation (e.g. `'linux_x64'`).
  String get name => cliName.replaceAll('-', '_');

  /// Parses a [HostPlatform] from its [cliName] or [name], returning canonical
  /// constants from [values] when matched or a custom [HostPlatform] for
  /// non-standard `<os>-<arch>` platforms, or `null` if [name] is invalid.
  static HostPlatform? tryFromName(String name) {
    if (!_validNameRegExp.hasMatch(name)) {
      return null;
    }
    final String normalizedCli = name.replaceAll('_', '-');
    for (final HostPlatform value in values) {
      if (value.cliName == normalizedCli) {
        return value;
      }
    }
    final int separatorIndex = normalizedCli.indexOf('-');
    final String arch = normalizedCli.substring(separatorIndex + 1);
    return HostPlatform(normalizedCli, arch);
  }

  /// Returns the host platform for the specified OS and architecture.
  ///
  /// [os] is an operating system name as returned by `Platform.operatingSystem`.
  /// [arch] is an architecture name matching the [platformName] of one of the
  /// values in [values]. Returns `null` if no match is found.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HostPlatform && other.cliName == cliName && other.platformName == platformName);

  @override
  int get hashCode => Object.hash(cliName, platformName);

  @override
  String toString() => 'HostPlatform.$name';
}

/// Representation of an artifact dependency required by a tool extension.
@immutable
class ArtifactDependency {
  ArtifactDependency({
    required this.name,
    required this.sha256,
    required this.url,
    this.hostPlatform,
    this.targetPlatform,
  }) : assert(
         isValidSinglePathSegment(name),
         'Invalid artifact dependency name (expected a single path segment): "$name"',
       ),
       assert(
         _isValidSha256(sha256),
         'Invalid artifact dependency sha256 (expected 64 hex characters): "$sha256"',
       ),
       assert(
         url.isScheme(_httpScheme) || url.isScheme(_httpsScheme),
         'Invalid artifact dependency URL (expected http/https): "$url"',
       );

  /// Deserializes an [ArtifactDependency] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if any required field is missing or invalid.
  factory ArtifactDependency.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (!isValidSinglePathSegment(name)) {
      throw FormatException('Invalid artifact dependency name: "$name"');
    }
    final String sha256 = json.requiredField<String>(sha256Key);
    if (!_isValidSha256(sha256)) {
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
  static const String _zipExtension = '.zip';
  static final RegExp _sha256RegExp = RegExp(r'^[a-fA-F0-9]{64}$');

  static bool _isValidSha256(String value) => _sha256RegExp.hasMatch(value);

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

  /// The unique single-segment identifier of the artifact within the extension.
  ///
  /// The host uses [name] as the local cache entry name and as the lookup key in
  /// the `resolvedArtifacts` map passed to extension build targets. Downloads
  /// whose [url] path ends with `.zip` (case-insensitive) are extracted into a
  /// directory named [name]; all other downloads are stored verbatim as a single
  /// file named [name].
  final String name;

  /// The download URL for the artifact.
  final Uri url;

  /// The 64-character hexadecimal SHA-256 checksum of the artifact.
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

  /// Whether [url] points to a `.zip` archive that is extracted into a directory.
  bool get isZipArchive => url.path.toLowerCase().endsWith(_zipExtension);

  static String _normalizeTargetPlatform(String platform) {
    if (platform == 'macos') {
      return 'darwin';
    }
    if (platform.startsWith('macos-')) {
      return 'darwin-${platform.substring('macos-'.length)}';
    }
    return platform;
  }

  /// Returns whether this artifact matches [currentHostPlatform] and optional
  /// [targetPlatforms].
  ///
  /// When [targetPlatforms] is provided and [targetPlatform] is non-null, a
  /// target platform matches if it equals [targetPlatform] or either is an
  /// `<os>` prefix of `<os>-<arch>` (e.g. `'linux'` matches `'linux-x64'`, and
  /// `'macos'` and `'darwin'` are treated as aliases). When [targetPlatforms]
  /// is empty, only target-agnostic artifacts (`targetPlatform == null`) match.
  bool matchesPlatforms({required HostPlatform currentHostPlatform, Set<String>? targetPlatforms}) {
    if (hostPlatform != null && hostPlatform != currentHostPlatform) {
      return false;
    }
    if (targetPlatforms != null && targetPlatform != null) {
      final String depTarget = _normalizeTargetPlatform(targetPlatform!);
      return targetPlatforms.any((String p) {
        final String requested = _normalizeTargetPlatform(p);
        return depTarget == requested ||
            depTarget.startsWith('$requested-') ||
            requested.startsWith('$depTarget-');
      });
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
