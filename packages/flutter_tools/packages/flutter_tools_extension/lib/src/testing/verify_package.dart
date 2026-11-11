// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../artifacts.dart';
import '../build.dart';
import '../clean.dart';
import '../config.dart';
import '../dependencies.dart';
import '../device.dart';
import '../diagnostics.dart';
import '../templates.dart';
import 'harness.dart';

const _defaultEntrypointRelativePath = 'extension/flutter_tools/extension.dart';

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
/// capabilities, contributed build/assemble target identifiers, and optional
/// [expectedConfig].
///
/// If [entryPoint] is provided, the extension isolate is spawned in-process via
/// [ExtensionTestHarness.spawn]; otherwise, the entrypoint script under
/// [packageRoot] (resolved from [expectedConfig] or
/// `extension/flutter_tools/extension.dart`) is spawned via
/// [ExtensionTestHarness.spawnUri].
///
/// Throws a [FormatException] or [StateError] if the entrypoint is missing,
/// capabilities are invalid, build target names are malformed or duplicated,
/// or runtime capabilities drift from [expectedConfig].
Future<void> verifyExtensionPackage({
  required Uri packageRoot,
  ExtensionTestEntryPoint? entryPoint,
  // TODO(bkonyi): Remove expectedConfig once ExtensionPackageConfig is removed
  // in https://github.com/flutter/flutter/pull/194774.
  ExtensionPackageConfig? expectedConfig,
  ExtensionFileSystem fileSystem = const LocalExtensionFileSystem(),
  Uri? packageConfigUri,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final Uri rootUri = packageRoot.path.endsWith('/')
      ? packageRoot
      : packageRoot.replace(path: '${packageRoot.path}/');

  if (expectedConfig != null) {
    for (final String service in expectedConfig.services) {
      if (!_validServiceNamespaces.contains(service)) {
        throw FormatException(
          'Unknown service "$service" in "${ExtensionPackageConfig.servicesKey}". '
          'Valid services are: ${_validServiceNamespaces.join(', ')}.',
        );
      }
    }
  }

  final Uri entrypointUri = _resolveEntrypointUri(
    expectedConfig: expectedConfig,
    fileSystem: fileSystem,
    rootUri: rootUri,
  );

  final ExtensionTestHarness harness = entryPoint != null
      ? await ExtensionTestHarness.spawn(entryPoint, timeout: timeout)
      : await ExtensionTestHarness.spawnUri(
          entrypointUri,
          packageConfigUri: packageConfigUri,
          timeout: timeout,
        );

  try {
    final Set<String> runtimePlatforms = harness.capabilities.supportedPlatforms.toSet();
    if (runtimePlatforms.isEmpty) {
      throw StateError('Runtime supportedPlatforms must not be empty.');
    }

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

    if (expectedConfig != null) {
      if (harness.capabilities.extensionName != expectedConfig.name) {
        throw StateError(
          'Extension name mismatch: expected "${expectedConfig.name}", '
          'but runtime capabilities reported "${harness.capabilities.extensionName}".',
        );
      }
      if (!_setsEqual(runtimeServices, expectedConfig.services)) {
        throw StateError(
          'Services mismatch: expected ${expectedConfig.services}, '
          'but runtime capabilities reported $runtimeServices.',
        );
      }
      if (expectedConfig.hostPlatforms.isNotEmpty &&
          !_setsEqual(runtimePlatforms, expectedConfig.hostPlatforms)) {
        throw StateError(
          'Supported platforms mismatch: expected ${expectedConfig.hostPlatforms}, '
          'but runtime capabilities reported $runtimePlatforms.',
        );
      }
    }

    if (runtimeServices.contains(BuildService.serviceNamespace)) {
      final List<ExtensionBuildTarget> buildTargets = await harness.buildClient.getBuildTargets();
      final runtimeTargetNames = <String>{};
      for (final target in buildTargets) {
        if (!ExtensionBuildTarget.isValidName(target.name)) {
          throw StateError(
            'Invalid build target name "${target.name}" reported by build.getBuildTargets.',
          );
        }
        if (!runtimeTargetNames.add(target.name)) {
          throw StateError(
            'Duplicate build target name "${target.name}" reported by build.getBuildTargets.',
          );
        }
      }
      if (expectedConfig != null &&
          expectedConfig.buildTargets.isNotEmpty &&
          !_setsEqual(runtimeTargetNames, expectedConfig.buildTargets)) {
        throw StateError(
          'Build targets mismatch: expected ${expectedConfig.buildTargets}, '
          'but runtime build.getBuildTargets reported $runtimeTargetNames.',
        );
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
      final List<ExtensionProjectTemplate> templates = await harness.templateClient
          .getProjectTemplates();
      final runtimeTemplateNames = <String>{};
      for (final template in templates) {
        if (!runtimeTemplateNames.add(template.name)) {
          throw StateError(
            'Duplicate project template name "${template.name}" reported by template.getProjectTemplates.',
          );
        }
      }
      if (expectedConfig != null &&
          expectedConfig.templates.isNotEmpty &&
          !_setsEqual(runtimeTemplateNames, expectedConfig.templates)) {
        throw StateError(
          'Templates mismatch: expected ${expectedConfig.templates}, '
          'but runtime template.getProjectTemplates reported $runtimeTemplateNames.',
        );
      }
    }
  } finally {
    await harness.dispose();
  }
}

Uri _resolveEntrypointUri({
  required ExtensionPackageConfig? expectedConfig,
  required ExtensionFileSystem fileSystem,
  required Uri rootUri,
}) {
  if (expectedConfig != null) {
    final Uri configuredUri = rootUri.resolve(expectedConfig.entrypoint);
    final ExtensionFile configuredFile = fileSystem.file(configuredUri);
    if (!configuredFile.existsSync()) {
      throw StateError(
        'Declared extension entrypoint "${expectedConfig.entrypoint}" does not exist '
        'at ${configuredFile.path}.',
      );
    }
    return configuredUri;
  }

  final Uri conventionalUri = rootUri.resolve(_defaultEntrypointRelativePath);
  if (fileSystem.file(conventionalUri).existsSync()) {
    return conventionalUri;
  }

  throw StateError(
    'Extension entrypoint not found under ${fileSystem.directory(rootUri).path} '
    '(expected $_defaultEntrypointRelativePath).',
  );
}

bool _setsEqual(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
