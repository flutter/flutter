// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Matches a single-segment lowercase ASCII alphanumeric identifier.
///
/// Hyphens and underscores are disallowed because they delimit `<os>` and
/// `<arch>` in [HostPlatform.cliName] and [HostPlatform.name].
final RegExp _validIdentifierRegExp = RegExp(r'^[a-z0-9]+$');

// Matches a Windows drive-letter prefix such as `C:` or `d:`.
final RegExp _windowsDrivePrefixRegExp = RegExp(r'^[A-Za-z]:');

const String _darwinOsName = 'darwin';
const String _macosAlias = 'macos';

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
/// `HostPlatform('freebsd', CpuArch.x64)`). The `'macos'` OS alias is
/// normalized to `'darwin'` so `HostPlatform('macos', CpuArch.arm64)` and
/// `HostPlatform.fromName('macos-arm64')` resolve to [darwin_arm64].
@immutable
final class HostPlatform {
  /// Creates a [HostPlatform] with the given lowercase alphanumeric [osName]
  /// (e.g. `'linux'`, `'darwin'`, `'macos'`, `'freebsd'`) and [cpuArch],
  /// returning canonical constants from [values] when matched.
  factory HostPlatform(String osName, CpuArch cpuArch) {
    assert(
      _validIdentifierRegExp.hasMatch(osName),
      'Invalid host OS name (expected lowercase alphanumeric): "$osName"',
    );
    final String normalizedOs = osName == _macosAlias ? _darwinOsName : osName;
    for (final HostPlatform value in values) {
      if (value.osName == normalizedOs && value.cpuArch == cpuArch) {
        return value;
      }
    }
    return HostPlatform._(normalizedOs, cpuArch);
  }

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
  static const darwin_x64 = HostPlatform._(_darwinOsName, .x64);

  /// macOS (Darwin) on ARM64 (Apple Silicon).
  static const darwin_arm64 = HostPlatform._(_darwinOsName, .arm64);

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

  /// Parses a [HostPlatform] from its [cliName] or [name] (normalizing
  /// `'macos'` to `'darwin'`), returning canonical constants from [values] when
  /// matched or a custom [HostPlatform] for non-standard `<os>-<arch>`
  /// platforms, or `null` if [name] is invalid.
  static HostPlatform? tryFromName(String name) {
    if (!_validNameRegExp.hasMatch(name)) {
      return null;
    }
    final String normalizedCli = name.replaceAll('_', '-');
    final int separatorIndex = normalizedCli.indexOf('-');
    final String os = normalizedCli.substring(0, separatorIndex);
    final String arch = normalizedCli.substring(separatorIndex + 1);
    return HostPlatform(os, CpuArch.fromName(arch));
  }

  /// Returns the host platform for the specified OS and architecture.
  ///
  /// [os] is an operating system name as returned by `Platform.operatingSystem`
  /// (or `'darwin'`). [arch] is an architecture name matching the [cpuArchName]
  /// of one of the values in [values]. Returns `null` if no match is found.
  static HostPlatform? fromOsAndArch(String os, String arch) {
    final HostPlatform? platform = tryFromName('$os-${arch.toLowerCase()}');
    return values.contains(platform) ? platform : null;
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

/// Supported archive formats for [RemoteArtifactDependency].
enum ArchiveFormat {
  /// A single file stored verbatim without extraction.
  none('none'),

  /// A `.zip` archive extracted into a directory named [ArtifactDependency.name].
  zip('zip');

  const ArchiveFormat(this.cliName);

  /// Parses an [ArchiveFormat] from its [cliName].
  ///
  /// Throws a [FormatException] if [name] does not match a known format.
  factory ArchiveFormat.fromName(String name) {
    for (final ArchiveFormat value in values) {
      if (value.cliName == name) {
        return value;
      }
    }
    throw FormatException('Invalid archive format: "$name"');
  }

  /// The serialized wire name of the archive format.
  final String cliName;
}

/// Representation of an artifact dependency required by a tool extension.
@immutable
sealed class ArtifactDependency {
  const ArtifactDependency({required this.name, this.hostPlatform, this.targetPlatform});

  /// Creates a remote [ArtifactDependency] that the host downloads over HTTP/HTTPS,
  /// verifies against [sha256], and caches under the shared extension artifact cache.
  ///
  /// Throws a [FormatException] if [name], [sha256], [url], [executables], or
  /// [isExecutable] is invalid.
  factory ArtifactDependency.remote({
    required String name,
    required String sha256,
    required Uri url,
    ArchiveFormat? archiveFormat,
    Set<String> executables,
    HostPlatform? hostPlatform,
    bool isExecutable,
    String? targetPlatform,
  }) = RemoteArtifactDependency;

  /// Creates a local [ArtifactDependency] that resolves directly to [localUri]
  /// on the host filesystem without downloading or caching.
  ///
  /// [localUri] must point to an unpacked file or directory on disk matching the
  /// layout expected by build targets consuming [name]. Providing [stampUri] is
  /// strongly recommended when [localUri] is a directory so `flutter assemble`
  /// tracks only the stamp file instead of walking the directory tree.
  ///
  /// Throws a [FormatException] if [name], [localUri], or [stampUri] is invalid.
  factory ArtifactDependency.local({
    required Uri localUri,
    required String name,
    HostPlatform? hostPlatform,
    Uri? stampUri,
    String? targetPlatform,
  }) = LocalArtifactDependency;

  /// Deserializes an [ArtifactDependency] from a JSON-serializable map.
  ///
  /// Dispatches on [typeKey] (`'remote'` or `'local'`).
  /// Throws a [FormatException] if any required field is missing or invalid.
  factory ArtifactDependency.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    final String? hostPlatformName = json.nullableField<String>(hostPlatformKey);
    final HostPlatform? hostPlatform = hostPlatformName != null
        ? HostPlatform.fromName(hostPlatformName)
        : null;
    final String? targetPlatform = json.nullableField<String>(targetPlatformKey);
    final String type = json.requiredField<String>(typeKey);

    switch (type) {
      case remoteType:
        final String urlStr = json.requiredField<String>(urlKey);
        final Uri uri =
            Uri.tryParse(urlStr) ??
            (throw FormatException('Invalid artifact dependency URL: "$urlStr"'));
        return RemoteArtifactDependency(
          name: name,
          sha256: json.requiredField<String>(sha256Key),
          url: uri,
          archiveFormat: ArchiveFormat.fromName(json.requiredField<String>(archiveFormatKey)),
          executables: json.stringSet(executablesKey),
          hostPlatform: hostPlatform,
          isExecutable: json.optionalField<bool>(isExecutableKey, defaultValue: false),
          targetPlatform: targetPlatform,
        );
      case localType:
        final String localUriStr = json.requiredField<String>(localUriKey);
        final Uri localUri =
            Uri.tryParse(localUriStr) ??
            (throw FormatException('Invalid artifact dependency localUri: "$localUriStr"'));
        final String? stampUriStr = json.nullableField<String>(stampUriKey);
        final Uri? stampUri = stampUriStr != null
            ? (Uri.tryParse(stampUriStr) ??
                  (throw FormatException('Invalid artifact dependency stampUri: "$stampUriStr"')))
            : null;
        return LocalArtifactDependency(
          localUri: localUri,
          name: name,
          hostPlatform: hostPlatform,
          stampUri: stampUri,
          targetPlatform: targetPlatform,
        );
      default:
        throw FormatException('Invalid artifact dependency type: "$type"');
    }
  }

  static const String _httpScheme = 'http';
  static const String _httpsScheme = 'https';
  static const String _zipExtension = '.zip';

  // Matches a 64-character hexadecimal SHA-256 digest.
  static final RegExp _sha256RegExp = RegExp(r'^[a-fA-F0-9]{64}$');

  // Matches a single non-empty ASCII filename segment containing only
  // alphanumeric characters, dots, underscores, and hyphens.
  static final RegExp _singlePathSegmentRegExp = RegExp(r'^[A-Za-z0-9._-]+$');

  static bool _isValidSha256(String value) => _sha256RegExp.hasMatch(value);

  /// Returns whether [value] is a valid single path segment containing only
  /// ASCII alphanumeric characters, `.`, `_`, or `-`, and not ending with `.`.
  static bool isValidSinglePathSegment(String value) {
    return _singlePathSegmentRegExp.hasMatch(value) && !value.endsWith('.');
  }

  /// Returns whether [value] is a valid relative in-tree POSIX file path
  /// without empty, `'.'`, `'..'`, backslash, NUL, or drive-letter segments.
  static bool isValidExecutableSubpath(String value) {
    if (value.isEmpty ||
        value.contains(r'\') ||
        value.contains('\x00') ||
        _windowsDrivePrefixRegExp.hasMatch(value)) {
      return false;
    }
    for (final String segment in value.split('/')) {
      if (segment.isEmpty || segment == '.' || segment == '..') {
        return false;
      }
    }
    return true;
  }

  /// Discriminator value for [RemoteArtifactDependency].
  static const String remoteType = 'remote';

  /// Discriminator value for [LocalArtifactDependency].
  static const String localType = 'local';

  /// Map key for [RemoteArtifactDependency.archiveFormat].
  static const String archiveFormatKey = 'archiveFormat';

  /// Map key for [RemoteArtifactDependency.executables].
  static const String executablesKey = 'executables';

  /// Map key for [hostPlatform].
  static const String hostPlatformKey = 'hostPlatform';

  /// Map key for [RemoteArtifactDependency.isExecutable].
  static const String isExecutableKey = 'isExecutable';

  /// Map key for [LocalArtifactDependency.localUri].
  static const String localUriKey = 'localUri';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [RemoteArtifactDependency.sha256].
  static const String sha256Key = 'sha256';

  /// Map key for [LocalArtifactDependency.stampUri].
  static const String stampUriKey = 'stampUri';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Map key for the artifact dependency variant discriminator.
  static const String typeKey = 'type';

  /// Map key for [RemoteArtifactDependency.url].
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
  /// the `resolvedArtifacts` map passed to extension build targets.
  final String name;

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

  static String _normalizeTargetPlatform(String platform) {
    if (platform == _macosAlias) {
      return _darwinOsName;
    }
    if (platform.startsWith('$_macosAlias-')) {
      return '$_darwinOsName-${platform.substring('$_macosAlias-'.length)}';
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
  Map<String, Object?> toMap();
}

/// A remote [ArtifactDependency] that the host downloads over HTTP/HTTPS,
/// verifies by SHA-256, and stores in the shared content-addressed cache.
@immutable
final class RemoteArtifactDependency extends ArtifactDependency {
  /// Creates a [RemoteArtifactDependency].
  ///
  /// When [archiveFormat] is omitted, it defaults to [ArchiveFormat.zip] if
  /// [url]'s path ends with `.zip` (case-insensitive), or [ArchiveFormat.none]
  /// otherwise.
  ///
  /// Throws a [FormatException] if [name], [sha256], [url], [executables], or
  /// [isExecutable] is invalid.
  RemoteArtifactDependency({
    required super.name,
    required this.sha256,
    required this.url,
    ArchiveFormat? archiveFormat,
    Set<String> executables = const <String>{},
    super.hostPlatform,
    this.isExecutable = false,
    super.targetPlatform,
  }) : archiveFormat = _resolveArchiveFormat(archiveFormat, url),
       executables = Set<String>.unmodifiable(executables) {
    if (!ArtifactDependency.isValidSinglePathSegment(name)) {
      throw FormatException(
        'Invalid artifact dependency name (expected a single path segment): "$name"',
      );
    }
    if (!ArtifactDependency._isValidSha256(sha256)) {
      throw FormatException(
        'Invalid artifact dependency sha256 (expected 64 hex characters): "$sha256"',
      );
    }
    if (!url.isScheme(ArtifactDependency._httpScheme) &&
        !url.isScheme(ArtifactDependency._httpsScheme)) {
      throw FormatException('Invalid artifact dependency URL (expected http/https): "$url"');
    }
    for (final String entry in this.executables) {
      if (!ArtifactDependency.isValidExecutableSubpath(entry)) {
        throw FormatException('Invalid artifact dependency executable path: "$entry"');
      }
    }
    if (this.archiveFormat == .none && this.executables.isNotEmpty) {
      throw FormatException(
        'Artifact dependency "$name" cannot specify "${ArtifactDependency.executablesKey}" when '
        '"${ArtifactDependency.archiveFormatKey}" is "${ArchiveFormat.none.cliName}"; '
        'use "${ArtifactDependency.isExecutableKey}" instead.',
      );
    }
    if (this.archiveFormat != .none && isExecutable) {
      throw FormatException(
        'Artifact dependency "$name" cannot set "${ArtifactDependency.isExecutableKey}" to true when '
        '"${ArtifactDependency.archiveFormatKey}" is "${this.archiveFormat.cliName}"; '
        'use "${ArtifactDependency.executablesKey}" instead.',
      );
    }
  }

  static const _setEquality = SetEquality<String>();

  static ArchiveFormat _resolveArchiveFormat(ArchiveFormat? archiveFormat, Uri url) {
    return archiveFormat ??
        (url.path.toLowerCase().endsWith(ArtifactDependency._zipExtension) ? .zip : .none);
  }

  /// The archive format of the downloaded artifact.
  final ArchiveFormat archiveFormat;

  /// Relative in-tree POSIX file paths within an extracted archive that must be
  /// marked executable (`chmod +x`) on POSIX hosts after extraction (for
  /// example, `const <String>{'gen_snapshot'}`).
  ///
  /// Entries must stay strictly within the extracted directory (rejecting
  /// `'.'`, `'..'`, absolute paths, and symlinks). For single-file binaries
  /// ([ArchiveFormat.none]), set [isExecutable] instead.
  final Set<String> executables;

  /// Whether a single-file artifact ([ArchiveFormat.none]) must be marked
  /// executable (`chmod +x`) on POSIX hosts after download.
  final bool isExecutable;

  /// The 64-character hexadecimal SHA-256 checksum of the artifact.
  final String sha256;

  /// The download URL for the artifact.
  final Uri url;

  /// Whether this artifact is a `.zip` archive that is extracted into a directory.
  bool get isZipArchive => archiveFormat == .zip;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ArtifactDependency.typeKey: ArtifactDependency.remoteType,
    ArtifactDependency.nameKey: name,
    ArtifactDependency.urlKey: url.toString(),
    ArtifactDependency.sha256Key: sha256,
    ArtifactDependency.archiveFormatKey: archiveFormat.cliName,
    if (executables.isNotEmpty) ArtifactDependency.executablesKey: executables.toList(),
    if (isExecutable) ArtifactDependency.isExecutableKey: isExecutable,
    ArtifactDependency.hostPlatformKey: ?hostPlatform?.cliName,
    ArtifactDependency.targetPlatformKey: ?targetPlatform,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RemoteArtifactDependency &&
            other.name == name &&
            other.url == url &&
            other.sha256 == sha256 &&
            other.archiveFormat == archiveFormat &&
            _setEquality.equals(other.executables, executables) &&
            other.isExecutable == isExecutable &&
            other.hostPlatform == hostPlatform &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hash(
    name,
    url,
    sha256,
    archiveFormat,
    _setEquality.hash(executables),
    isExecutable,
    hostPlatform,
    targetPlatform,
  );

  @override
  String toString() =>
      'RemoteArtifactDependency(name: $name, url: $url, sha256: $sha256, '
      'archiveFormat: ${archiveFormat.cliName}, executables: $executables, '
      'isExecutable: $isExecutable, hostPlatform: $hostPlatform, '
      'targetPlatform: $targetPlatform)';
}

/// A local [ArtifactDependency] that resolves directly to [localUri] on the
/// host filesystem without downloading or caching.
@immutable
final class LocalArtifactDependency extends ArtifactDependency {
  /// Creates a [LocalArtifactDependency].
  ///
  /// [localUri] must be a valid `file:` URI pointing to an already-extracted
  /// local artifact file or directory on disk matching the unpacked layout
  /// expected by build targets consuming [name].
  ///
  /// [stampUri], when provided, must be a valid `file:` URI pointing to a stamp
  /// file (not ending with `/`) whose modification time tracks rebuilds of
  /// directory-based local artifacts.
  ///
  /// Throws a [FormatException] if [name], [localUri], or [stampUri] is invalid.
  LocalArtifactDependency({
    required this.localUri,
    required super.name,
    super.hostPlatform,
    this.stampUri,
    super.targetPlatform,
  }) {
    if (!ArtifactDependency.isValidSinglePathSegment(name)) {
      throw FormatException(
        'Invalid artifact dependency name (expected a single path segment): "$name"',
      );
    }
    if (!localUri.isValidFileUri && !localUri.isValidDirectoryUri) {
      throw FormatException(
        'Invalid artifact dependency localUri (expected absolute file: URI): "$localUri"',
      );
    }
    if (stampUri != null && !stampUri!.isValidFileUri) {
      throw FormatException(
        'Invalid artifact dependency stampUri (expected absolute file: URI): "$stampUri"',
      );
    }
  }

  /// The `file:` URI of the local artifact file or directory on the host.
  final Uri localUri;

  /// Optional `file:` URI of a stamp file used to track staleness for
  /// directory-based local artifacts.
  final Uri? stampUri;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ArtifactDependency.typeKey: ArtifactDependency.localType,
    ArtifactDependency.nameKey: name,
    ArtifactDependency.localUriKey: localUri.toString(),
    ArtifactDependency.stampUriKey: ?stampUri?.toString(),
    ArtifactDependency.hostPlatformKey: ?hostPlatform?.cliName,
    ArtifactDependency.targetPlatformKey: ?targetPlatform,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LocalArtifactDependency &&
            other.name == name &&
            other.localUri == localUri &&
            other.stampUri == stampUri &&
            other.hostPlatform == hostPlatform &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hash(name, localUri, stampUri, hostPlatform, targetPlatform);

  @override
  String toString() =>
      'LocalArtifactDependency(name: $name, localUri: $localUri, stampUri: $stampUri, '
      'hostPlatform: $hostPlatform, targetPlatform: $targetPlatform)';
}
