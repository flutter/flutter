// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

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
  factory HostPlatform.fromName(String name) {
    final String normalized = name.replaceAll('-', '_');
    return HostPlatform.values.firstWhere(
      (HostPlatform platform) => platform.name == normalized,
      orElse: () => throw ArgumentError('Unsupported host platform: "$name"'),
    );
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
  factory ArtifactDependency.fromJson(Map<String, Object?> json) {
    if (json case {
      nameKey: final String name,
      urlKey: final String urlStr,
      sha256Key: final String sha256,
    }) {
      final Uri? uri = Uri.tryParse(urlStr);
      if (uri == null || !uri.hasScheme) {
        throw ArgumentError('Invalid artifact dependency URL: "$urlStr"');
      }
      final HostPlatform? hostPlatform = switch (json[hostPlatformKey]) {
        final String hp => HostPlatform.fromName(hp),
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$hostPlatformKey": $invalid'),
      };
      final String? targetPlatform = switch (json[targetPlatformKey]) {
        final String tp => tp,
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$targetPlatformKey": $invalid'),
      };
      return ArtifactDependency(
        name: name,
        sha256: sha256,
        url: uri,
        hostPlatform: hostPlatform,
        targetPlatform: targetPlatform,
      );
    }
    throw ArgumentError('Invalid ArtifactDependency JSON: $json');
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

  /// Optional target platform identifier this artifact is intended for (e.g. `'linux-x64'`).
  final String? targetPlatform;

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
