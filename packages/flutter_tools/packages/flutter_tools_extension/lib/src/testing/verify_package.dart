// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../artifacts.dart';
import '../build.dart';
import '../clean.dart';
import '../config.dart';
import '../device.dart';
import '../diagnostics.dart';
import '../protocol_base/connection.dart';
import '../templates.dart';
import 'harness.dart';

const _defaultEntrypointRelativePath = 'extension/flutter_tools/extension.dart';
const _packageUriSchemePrefix = 'package:';
const _packagesKey = 'packages';
const _packageNameKey = 'name';
const _rootUriKey = 'rootUri';
const _packageUriKey = 'packageUri';

const _validServiceNamespaces = <String>{
  DiagnosticsExtension.serviceNamespace,
  ConfigurationExtension.serviceNamespace,
  TemplateService.serviceNamespace,
  DeviceService.serviceNamespace,
  BuildService.serviceNamespace,
  ArtifactService.serviceNamespace,
  CleanService.serviceNamespace,
};

/// Validates a tool extension package's isolate entrypoint, handshake
/// capabilities, contributed build/assemble target identifiers, and template
/// directory URIs.
///
/// Verifies that [entrypointRelativePath] exists inside [packageRoot] without
/// escaping via symlinks. If [entryPoint] is provided, the extension isolate is
/// spawned in-process via [ExtensionTestHarness.spawn]; otherwise, the
/// entrypoint script is spawned via [ExtensionTestHarness.spawnUri] using
/// [packageConfigUri].
///
/// When `template` is registered, any `package:` URI returned by
/// `template.getAppTemplates` or `template.getPluginTemplates` is resolved
/// against [packageConfigUri] when provided, or against the current isolate's
/// package configuration (via [Isolate.resolvePackageUri]) when
/// [packageConfigUri] is `null`, and verified to point to an existing directory
/// inside [packageRoot] (after symlink resolution).
///
/// Service-specific RPC checks are skipped when the extension's reported
/// `supportedPlatforms` excludes [Platform.operatingSystem].
Future<void> verifyExtensionPackage({
  required Uri packageRoot,
  ExtensionIsolateEntryPoint? entryPoint,
  String entrypointRelativePath = _defaultEntrypointRelativePath,
  Uri? packageConfigUri,
  Duration timeout = ExtensionIsolateConnection.defaultRpcTimeout,
}) async {
  final Uri rootUri = _ensureTrailingSlash(packageRoot);
  final (
    Uri entrypointUri,
    String resolvedRootPath,
    String normalizedRootPrefix,
  ) = _resolveAndValidateEntrypointUri(
    entrypointRelativePath: entrypointRelativePath,
    rootUri: rootUri,
  );
  final _ParsedPackageConfig? parsedPackageConfig = packageConfigUri != null
      ? _ParsedPackageConfig.load(packageConfigUri)
      : null;

  final ExtensionTestHarness harness = entryPoint != null
      ? await ExtensionTestHarness.spawn(entryPoint, timeout: timeout)
      : await ExtensionTestHarness.spawnUri(
          entrypointUri,
          packageConfigUri: packageConfigUri,
          timeout: timeout,
        );

  try {
    final runtimeServices = <String>{};
    for (final String service in harness.capabilities.services) {
      if (!_validServiceNamespaces.contains(service)) {
        throw FormatException(
          'Extension reported unknown service "$service". '
          'Valid services are: ${_validServiceNamespaces.join(', ')}.',
        );
      }
      if (!runtimeServices.add(service)) {
        throw StateError('Extension reported duplicate service namespace "$service".');
      }
    }

    if (harness.capabilities.supportedPlatforms.isEmpty) {
      throw StateError('Runtime supportedPlatforms must not be empty.');
    }

    if (!harness.capabilities.supportsHostPlatform(Platform.operatingSystem)) {
      return;
    }

    if (runtimeServices.contains(BuildService.serviceNamespace)) {
      final List<ExtensionBuildTarget> buildTargets = await harness.buildClient.getBuildTargets();
      final runtimeTargetNames = <String>{};
      for (final target in buildTargets) {
        if (!runtimeTargetNames.add(target.name)) {
          throw StateError(
            'Duplicate build target name "${target.name}" reported by build.getBuildTargets.',
          );
        }
      }

      final List<ExtensionAssembleTarget> assembleTargets = await harness.buildClient
          .getAssembleTargets();
      final assembleNames = <String>{};
      for (final target in assembleTargets) {
        if (!assembleNames.add(target.name)) {
          throw StateError(
            'Duplicate assemble target name "${target.name}" reported by build.getAssembleTargets.',
          );
        }
      }
    }

    if (runtimeServices.contains(TemplateService.serviceNamespace)) {
      final String? expectedPackageName = parsedPackageConfig?.packageNameForResolvedRoot(
        resolvedRootPath,
      );
      final Set<String> appTemplates = await harness.templateClient.getAppTemplates();
      final Set<String> pluginTemplates = await harness.templateClient.getPluginTemplates();
      for (final templateUri in <String>{...appTemplates, ...pluginTemplates}) {
        if (!templateUri.startsWith(_packageUriSchemePrefix)) {
          continue;
        }
        final (String packageName, String relativeSubpath, Uri parsedUri) =
            _parsePackageTemplateUri(templateUri);
        if (expectedPackageName != null && packageName != expectedPackageName) {
          throw StateError(
            'Template URI "$templateUri" references package "$packageName", '
            'expected "$expectedPackageName".',
          );
        }
        final Uri? resolvedUri = parsedPackageConfig != null
            ? parsedPackageConfig.resolvePackageUri(packageName, relativeSubpath)
            : await Isolate.resolvePackageUri(parsedUri);
        if (resolvedUri == null || !resolvedUri.isScheme('file')) {
          throw StateError(
            'Template directory "$templateUri" does not exist '
            '(resolved to "${resolvedUri ?? 'unresolvable package URI'}").',
          );
        }
        final templateDirectory = Directory.fromUri(resolvedUri);
        if (!templateDirectory.existsSync()) {
          throw StateError(
            'Template directory "$templateUri" does not exist '
            '(resolved to "$resolvedUri").',
          );
        }
        final String resolvedTemplatePath = templateDirectory.resolveSymbolicLinksSync();
        if (resolvedTemplatePath != resolvedRootPath &&
            !resolvedTemplatePath.startsWith(normalizedRootPrefix)) {
          throw StateError(
            'Template directory "$templateUri" resolves outside package root '
            '"$resolvedRootPath" (resolved to "$resolvedTemplatePath").',
          );
        }
      }
    }
  } finally {
    await harness.dispose();
  }
}

Uri _ensureTrailingSlash(Uri uri) =>
    uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');

(Uri entrypointUri, String resolvedRootPath, String normalizedRootPrefix)
_resolveAndValidateEntrypointUri({required String entrypointRelativePath, required Uri rootUri}) {
  final Uri entrypointUri = rootUri.resolve(entrypointRelativePath);
  final entrypointFile = File.fromUri(entrypointUri);
  final rootDirectory = Directory.fromUri(rootUri);
  if (!entrypointFile.existsSync()) {
    throw StateError(
      'Extension entrypoint not found under ${rootDirectory.path} '
      '(expected $entrypointRelativePath).',
    );
  }
  final String resolvedRootPath = rootDirectory.resolveSymbolicLinksSync();
  final normalizedRootPrefix = resolvedRootPath.endsWith(Platform.pathSeparator)
      ? resolvedRootPath
      : '$resolvedRootPath${Platform.pathSeparator}';
  final String resolvedEntrypointPath = entrypointFile.resolveSymbolicLinksSync();
  if (!resolvedEntrypointPath.startsWith(normalizedRootPrefix)) {
    throw StateError(
      'Extension entrypoint "${entrypointFile.path}" resolves outside package root '
      '"$resolvedRootPath" (resolved to "$resolvedEntrypointPath").',
    );
  }
  return (entrypointUri, resolvedRootPath, normalizedRootPrefix);
}

(String packageName, String relativeSubpath, Uri parsedUri) _parsePackageTemplateUri(
  String templateUri,
) {
  final Uri? parsedUri = Uri.tryParse(templateUri);
  if (parsedUri == null || !parsedUri.isScheme('package')) {
    throw FormatException('Invalid template URI "$templateUri".');
  }
  final int slashIndex = parsedUri.path.indexOf('/');
  if (slashIndex <= 0) {
    throw FormatException(
      'Invalid package template URI "$templateUri": expected "package:<name>/<path>".',
    );
  }
  final String packageName = parsedUri.path.substring(0, slashIndex);
  final String relativeSubpath = parsedUri.path.substring(slashIndex + 1);
  if (relativeSubpath.isEmpty ||
      relativeSubpath.startsWith('/') ||
      parsedUri.pathSegments.any((String segment) => segment == '.' || segment == '..')) {
    throw FormatException('Invalid package template URI "$templateUri".');
  }
  return (packageName, relativeSubpath, parsedUri);
}

final class _ParsedPackageEntry {
  const _ParsedPackageEntry({required this.libUri, required this.name, required this.rootUri});

  final Uri libUri;
  final String name;
  final Uri rootUri;
}

final class _ParsedPackageConfig {
  const _ParsedPackageConfig(this._entriesByName);

  factory _ParsedPackageConfig.load(Uri packageConfigUri) {
    final configFile = File.fromUri(packageConfigUri);
    if (!configFile.existsSync()) {
      throw StateError('Package config file not found at "${configFile.path}".');
    }
    final Object? decoded = jsonDecode(configFile.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw FormatException(
        'Invalid package config at "${configFile.path}": expected JSON object.',
      );
    }
    final Object? rawPackages = decoded[_packagesKey];
    if (rawPackages is! List<Object?>) {
      throw FormatException(
        'Invalid package config at "${configFile.path}": missing "$_packagesKey" list.',
      );
    }
    final entries = <String, _ParsedPackageEntry>{};
    for (final Object? item in rawPackages) {
      if (item is! Map<String, Object?>) {
        throw FormatException(
          'Invalid package entry in "${configFile.path}": expected JSON object.',
        );
      }
      final Object? name = item[_packageNameKey];
      final Object? rawRootUri = item[_rootUriKey];
      final Object? rawPackageUri = item[_packageUriKey];
      if (name is! String || name.isEmpty || rawRootUri is! String || rawRootUri.isEmpty) {
        throw FormatException(
          'Invalid package entry in "${configFile.path}": '
          'expected non-empty "$_packageNameKey" and "$_rootUriKey" strings.',
        );
      }
      final String? packageUri = switch (rawPackageUri) {
        null => null,
        final String value => value,
        _ => throw FormatException(
          'Invalid "$_packageUriKey" for package "$name" in "${configFile.path}".',
        ),
      };
      final Uri resolvedRootUri = _ensureTrailingSlash(packageConfigUri.resolve(rawRootUri));
      final Uri resolvedLibUri = packageUri == null || packageUri.isEmpty
          ? resolvedRootUri
          : _ensureTrailingSlash(resolvedRootUri.resolve(packageUri));
      entries[name] = _ParsedPackageEntry(
        libUri: resolvedLibUri,
        name: name,
        rootUri: resolvedRootUri,
      );
    }
    return _ParsedPackageConfig(entries);
  }

  final Map<String, _ParsedPackageEntry> _entriesByName;

  String? packageNameForResolvedRoot(String resolvedRootPath) {
    for (final _ParsedPackageEntry entry in _entriesByName.values) {
      if (!entry.rootUri.isScheme('file')) {
        continue;
      }
      final dir = Directory.fromUri(entry.rootUri);
      if (dir.existsSync() && dir.resolveSymbolicLinksSync() == resolvedRootPath) {
        return entry.name;
      }
    }
    return null;
  }

  Uri? resolvePackageUri(String packageName, String relativeSubpath) {
    final _ParsedPackageEntry? entry = _entriesByName[packageName];
    if (entry == null) {
      return null;
    }
    return entry.libUri.resolve(relativeSubpath);
  }
}
