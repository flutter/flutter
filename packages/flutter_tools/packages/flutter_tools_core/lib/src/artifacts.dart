// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Matches a single-segment lowercase ASCII alphanumeric identifier.
///
/// Hyphens and underscores are disallowed because they delimit `<os>` and
/// `<arch>` in [HostPlatform.cliName] and [HostPlatform.name].
final RegExp _validIdentifierRegExp = RegExp(r'^[a-z0-9]+$');

/// Platform-agnostic CPU architecture type.
///
/// Built-in architectures are exposed as static constants (e.g. [x64],
/// [arm64], [riscv64]), while extensions targeting non-standard architectures
/// can construct or parse custom lowercase alphanumeric identifiers (e.g.
/// `CpuArch('ppc64le')`).
@immutable
final class CpuArch {
  /// Creates a [CpuArch] with the given lowercase alphanumeric [name] (e.g.
  /// `'x64'` or `'ppc64le'`).
  CpuArch(this.name)
    : assert(
        _validIdentifierRegExp.hasMatch(name),
        'Invalid CPU architecture name (expected lowercase alphanumeric): "$name"',
      );

  const CpuArch._(this.name) : assert(name.length > 0);

  /// Parses a [CpuArch] from its [name] (e.g. `'x64'`, `'x86_64'`, `'arm64'`, or `'ppc64le'`).
  ///
  /// Throws a [FormatException] if [name] is not a valid CPU architecture identifier.
  factory CpuArch.fromName(String name) {
    return tryFromName(name) ?? (throw FormatException('Invalid CPU arch: "$name"'));
  }

  /// Unknown architecture. Used when the architecture is not relevant.
  static const unknown = CpuArch._('unknown');

  /// 32-bit ARM (ARMv7) architecture.
  static const armv7 = CpuArch._('armv7');

  /// 64-bit ARM (AArch64 / ARM64) architecture.
  static const arm64 = CpuArch._('arm64');

  /// 32-bit x86 (IA-32) architecture.
  static const x86 = CpuArch._('x86');

  /// 64-bit x86 (x86_64 / AMD64) architecture.
  static const x64 = CpuArch._('x64');

  /// 64-bit RISC-V (RV64GC) architecture.
  static const riscv64 = CpuArch._('riscv64');

  /// Standard built-in CPU architectures available in the Flutter tool.
  static const values = <CpuArch>[.unknown, .armv7, .arm64, .x86, .x64, .riscv64];

  /// The canonical architecture identifier (e.g. `'x64'`, `'arm64'`, `'riscv64'`).
  final String name;

  /// Parses a [CpuArch] from [name], returning canonical constants from
  /// [values] when matched (including `'x86_64'` -> [x64]) or a custom
  /// [CpuArch] for non-standard lowercase alphanumeric architectures, or `null`
  /// if [name] is invalid.
  static CpuArch? tryFromName(String name) {
    return switch (name) {
      'unknown' => .unknown,
      'armv7' => .armv7,
      'arm64' => .arm64,
      'x86' => .x86,
      'x64' || 'x86_64' => .x64,
      'riscv64' => .riscv64,
      _ when _validIdentifierRegExp.hasMatch(name) => CpuArch(name),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CpuArch && other.name == name);

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CpuArch.$name';
}

/// Host platforms that Flutter tools and extensions can be executed on.
///
/// Built-in host platforms are exposed as static constants (e.g. [linux_x64],
/// [darwin_arm64]), while extensions running on non-standard host platforms can
/// construct or parse custom `<os>-<arch>` identifiers (e.g.
/// `HostPlatform('freebsd', CpuArch.x64)`).
@immutable
final class HostPlatform {
  /// Creates a [HostPlatform] with the given lowercase alphanumeric [osName]
  /// (e.g. `'linux'`, `'darwin'`, `'freebsd'`) and [cpuArch].
  HostPlatform(this.osName, this.cpuArch)
    : assert(
        _validIdentifierRegExp.hasMatch(osName),
        'Invalid host OS name (expected lowercase alphanumeric): "$osName"',
      );

  const HostPlatform._(this.osName, this.cpuArch) : assert(osName.length > 0);

  /// Parses a [HostPlatform] from its [cliName] (e.g. `'linux-x64'`) or
  /// underscore-delimited [name] (e.g. `'linux_x64'`).
  ///
  /// Throws a [FormatException] if [name] is not a valid `<os>-<arch>` or
  /// `<os>_<arch>` host platform identifier.
  factory HostPlatform.fromName(String name) {
    return tryFromName(name) ?? (throw FormatException('Invalid host platform: "$name"'));
  }

  /// macOS (Darwin) on x64.
  static const darwin_x64 = HostPlatform._('darwin', .x64);

  /// macOS (Darwin) on ARM64 (Apple Silicon).
  static const darwin_arm64 = HostPlatform._('darwin', .arm64);

  /// Linux on x64.
  static const linux_x64 = HostPlatform._('linux', .x64);

  /// Linux on ARM64.
  static const linux_arm64 = HostPlatform._('linux', .arm64);

  /// Linux on RISC-V 64-bit.
  static const linux_riscv64 = HostPlatform._('linux', .riscv64);

  /// Windows on x64.
  static const windows_x64 = HostPlatform._('windows', .x64);

  /// Windows on ARM64.
  static const windows_arm64 = HostPlatform._('windows', .arm64);

  /// Standard built-in host platforms supported by the Flutter tool.
  static const values = <HostPlatform>[
    .darwin_x64,
    .darwin_arm64,
    .linux_x64,
    .linux_arm64,
    .linux_riscv64,
    .windows_x64,
    .windows_arm64,
  ];

  // Matches a lowercase alphanumeric <os> and <arch> separated by a single '-' or '_'.
  static final RegExp _validNameRegExp = RegExp(r'^[a-z0-9]+[-_][a-z0-9]+$');

  /// Operating system identifier of the host platform (e.g. `'linux'`, `'darwin'`, `'windows'`).
  final String osName;

  /// CPU architecture of the host platform.
  final CpuArch cpuArch;

  /// Architecture name of the host platform (e.g. `'x64'`, `'arm64'`, `'riscv64'`).
  String get cpuArchName => cpuArch.name;

  /// The hyphen-delimited CLI representation (e.g. `'linux-x64'`).
  String get cliName => '$osName-$cpuArchName';

  /// The underscore-delimited representation (e.g. `'linux_x64'`).
  String get name => '${osName}_$cpuArchName';

  /// Parses a [HostPlatform] from its [cliName] or [name], returning canonical
  /// constants from [values] when matched or a custom [HostPlatform] for
  /// non-standard `<os>-<arch>` platforms, or `null` if [name] is invalid.
  static HostPlatform? tryFromName(String name) {
    if (!_validNameRegExp.hasMatch(name)) {
      return null;
    }
    final String normalizedCli = name.replaceAll('_', '-');
    final int separatorIndex = normalizedCli.indexOf('-');
    final String os = normalizedCli.substring(0, separatorIndex);
    final String arch = normalizedCli.substring(separatorIndex + 1);
    final archValue = CpuArch.fromName(arch);
    for (final HostPlatform value in values) {
      if (value.osName == os && value.cpuArch == archValue) {
        return value;
      }
    }
    return HostPlatform(os, archValue);
  }

  /// Returns the host platform for the specified OS and architecture.
  ///
  /// [os] is an operating system name as returned by `Platform.operatingSystem`.
  /// [arch] is an architecture name matching the [cpuArchName] of one of the
  /// values in [values]. Returns `null` if no match is found.
  static HostPlatform? fromOsAndArch(String os, String arch) {
    return switch ((os, arch.toLowerCase())) {
      ('macos', 'x64') => .darwin_x64,
      ('macos', 'arm64') => .darwin_arm64,
      ('linux', 'x64') => .linux_x64,
      ('linux', 'arm64') => .linux_arm64,
      ('linux', 'riscv64') => .linux_riscv64,
      ('windows', 'x64') => .windows_x64,
      ('windows', 'arm64') => .windows_arm64,
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HostPlatform && other.osName == osName && other.cpuArch == cpuArch);

  @override
  int get hashCode => Object.hash(osName, cpuArch);

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
         _isValidSinglePathSegment(name),
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
    if (!_isValidSinglePathSegment(name)) {
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
  static final RegExp _singlePathSegmentRegExp = RegExp(r'^[A-Za-z0-9._-]+$');

  static bool _isValidSha256(String value) => _sha256RegExp.hasMatch(value);

  static bool _isValidSinglePathSegment(String value) {
    return _singlePathSegmentRegExp.hasMatch(value) && !value.endsWith('.');
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
  ///
  /// Throws a [FormatException] if [rpcResult] is not a list or contains invalid
  /// entries.
  static List<ArtifactDependency> listFromJson(Object? rpcResult) {
    if (rpcResult is! List<Object?>) {
      throw FormatException(
        'Invalid artifact dependency list: expected a List, got ${rpcResult.runtimeType}.',
      );
    }
    return <ArtifactDependency>[
      for (final Object? item in rpcResult)
        if (item is Map<String, Object?>)
          ArtifactDependency.fromJson(item)
        else
          throw FormatException(
            'Invalid artifact dependency entry: expected a Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
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
