// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../build.dart';
import '../protocol_base/provider.dart';
import '../protocol_base/service.dart';
import '../templates.dart';

const _defaultEntrypointRelativePath = 'extension/flutter_tools/extension.dart';
const _defaultTimeout = Duration(seconds: 5);
const _shutdownTimeout = Duration(seconds: 2);

/// Validates a tool extension package's isolate entrypoint, handshake
/// capabilities, contributed build/assemble target identifiers, and template
/// directory URIs.
Future<void> verifyExtensionPackage({
  required Uri packageRoot,
  String entrypointRelativePath = _defaultEntrypointRelativePath,
  Duration timeout = _defaultTimeout,
}) async {
  final Uri rootUri = packageRoot.path.endsWith('/')
      ? packageRoot
      : packageRoot.replace(path: '${packageRoot.path}/');
  final Uri entrypointUri = rootUri.resolve(entrypointRelativePath);
  if (!File.fromUri(entrypointUri).existsSync()) {
    throw StateError(
      'Extension entrypoint not found under ${Directory.fromUri(rootUri).path} '
      '(expected $entrypointRelativePath).',
    );
  }

  final receivePort = ReceivePort();
  final errorPort = ReceivePort();
  final exitPort = ReceivePort();
  final errorCompleter = Completer<void>();
  Isolate? isolate;
  json_rpc.Peer? peer;
  var handshakeCompleted = false;
  var isolateExited = false;
  var verified = false;
  StateError? unhandledError;

  final StreamSubscription<Object?> errorSub = errorPort.listen((Object? message) {
    final error = StateError('Extension isolate unhandled error: $message');
    if (!handshakeCompleted) {
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(error);
      }
      return;
    }
    unhandledError ??= error;
  });

  final StreamSubscription<Object?> exitSub = exitPort.listen((Object? _) {
    isolateExited = true;
    if (!handshakeCompleted) {
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(
          StateError('Extension isolate exited before completing handshake.'),
        );
      }
      return;
    }
    receivePort.close();
  });

  Future<void> cleanup() async {
    await errorSub.cancel();
    await exitSub.cancel();
    errorPort.close();
    exitPort.close();
    receivePort.close();
    if (handshakeCompleted && peer != null) {
      await peer.close();
    }
    isolate?.kill(priority: Isolate.immediate);
  }

  try {
    final Uri? packageConfig = await Isolate.packageConfig;
    isolate = await Isolate.spawnUri(
      entrypointUri,
      const <String>[],
      receivePort.sendPort,
      packageConfig: packageConfig,
      automaticPackageResolution: packageConfig == null,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    final channel = IsolateChannel<Object?>.connectReceive(receivePort);
    final rpcPeer = json_rpc.Peer.withoutJson(channel);
    peer = rpcPeer;
    unawaited(rpcPeer.listen());

    final Object? rawCapabilities = await Future.any<Object?>(<Future<Object?>>[
      rpcPeer.sendRequest(ToolExtensionEntryPoint.getCapabilitiesMethod),
      errorCompleter.future,
    ]).timeout(timeout);
    handshakeCompleted = true;

    if (rawCapabilities is! Map<String, Object?>) {
      throw const FormatException('Invalid extension.getCapabilities response: expected object.');
    }
    final capabilities = ToolExtensionCapabilities.fromJson(rawCapabilities);
    final Set<String> runtimeServices = _validateCapabilities(capabilities);

    if (capabilities.supportsHostPlatform(Platform.operatingSystem)) {
      if (runtimeServices.contains(BuildService.serviceNamespace)) {
        await _verifyBuildTargets(rpcPeer, timeout);
      }
      if (runtimeServices.contains(TemplateService.serviceNamespace)) {
        await _verifyTemplates(rpcPeer, timeout);
      }
    }

    if (unhandledError != null) {
      throw unhandledError!;
    }
    verified = true;
  } finally {
    try {
      if (verified && !isolateExited && peer != null && !peer.isClosed) {
        await peer.sendRequest(ToolExtensionEntryPoint.shutdownMethod).timeout(_shutdownTimeout);
      }
    } finally {
      await cleanup();
    }
  }
}

Set<String> _validateCapabilities(ToolExtensionCapabilities capabilities) {
  final runtimeServices = <String>{};
  for (final String service in capabilities.services) {
    if (!runtimeServices.add(service)) {
      throw StateError('Extension reported duplicate service namespace "$service".');
    }
  }
  if (capabilities.supportedPlatforms.isEmpty) {
    throw StateError('Runtime supportedPlatforms must not be empty.');
  }
  return runtimeServices;
}

Future<void> _verifyBuildTargets(json_rpc.Peer peer, Duration timeout) async {
  final List<ExtensionBuildTarget> buildTargets = ExtensionBuildTarget.listFromJson(
    await peer.sendRequest(BuildService.getBuildTargetsMethod).timeout(timeout),
  );
  final buildNames = <String>{};
  for (final target in buildTargets) {
    if (!buildNames.add(target.name)) {
      throw StateError(
        'Duplicate build target name "${target.name}" reported by build.getBuildTargets.',
      );
    }
  }

  final List<ExtensionAssembleTarget> assembleTargets = ExtensionAssembleTarget.listFromJson(
    await peer.sendRequest(BuildService.getAssembleTargetsMethod).timeout(timeout),
  );
  final assembleNames = <String>{};
  for (final target in assembleTargets) {
    if (!assembleNames.add(target.name)) {
      throw StateError(
        'Duplicate assemble target name "${target.name}" reported by build.getAssembleTargets.',
      );
    }
  }
}

List<String> _parseTemplateUriList(Object? raw, String method) {
  if (raw is! List<Object?>) {
    throw FormatException('Invalid $method response: expected list.');
  }
  return <String>[
    for (final Object? item in raw)
      if (item is String)
        item
      else
        throw FormatException('Invalid $method entry: expected String, got ${item.runtimeType}.'),
  ];
}

Future<void> _verifyTemplates(json_rpc.Peer peer, Duration timeout) async {
  final List<String> appTemplates = _parseTemplateUriList(
    await peer.sendRequest(TemplateService.getAppTemplatesMethod).timeout(timeout),
    TemplateService.getAppTemplatesMethod,
  );
  final List<String> pluginTemplates = _parseTemplateUriList(
    await peer.sendRequest(TemplateService.getPluginTemplatesMethod).timeout(timeout),
    TemplateService.getPluginTemplatesMethod,
  );
  for (final templateUri in <String>{...appTemplates, ...pluginTemplates}) {
    final Uri? parsedUri = Uri.tryParse(templateUri);
    if (parsedUri == null || !parsedUri.isScheme('package')) {
      continue;
    }
    final Uri? resolvedUri = await Isolate.resolvePackageUri(parsedUri);
    if (resolvedUri == null ||
        !resolvedUri.isScheme('file') ||
        !Directory.fromUri(resolvedUri).existsSync()) {
      throw StateError(
        'Template directory "$templateUri" does not exist '
        '(resolved to "${resolvedUri ?? 'unresolvable package URI'}").',
      );
    }
  }
}
