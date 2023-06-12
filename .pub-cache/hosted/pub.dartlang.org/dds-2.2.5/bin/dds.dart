// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';

/// A simple program which starts a [DartDevelopmentService] instance with a
/// basic configuration.
///
/// Takes the following positional arguments:
///   - VM service URI
///   - DDS bind address
///   - DDS port
///   - Disable service authentication codes
///   - Start DevTools
///   - DevTools build directory
///   - Enable logging
///   - Enable service port fallback
Future<void> main(List<String> args) async {
  if (args.isEmpty) return;

  // This URI is provided by the VM service directly so don't bother doing a
  // lookup.
  final remoteVmServiceUri = Uri.parse(args.first);

  // Resolve the address which is potentially provided by the user.
  late InternetAddress address;
  final addresses = await InternetAddress.lookup(args[1]);
  // Prefer IPv4 addresses.
  for (int i = 0; i < addresses.length; i++) {
    address = addresses[i];
    if (address.type == InternetAddressType.IPv4) break;
  }
  final serviceUri = Uri(
    scheme: 'http',
    host: address.address,
    port: int.parse(args[2]),
  );
  final disableServiceAuthCodes = args[3] == 'true';

  final startDevTools = args[4] == 'true';
  Uri? devToolsBuildDirectory;
  if (args[5].isNotEmpty) {
    devToolsBuildDirectory = Uri.file(args[5]);
  }
  final logRequests = args[6] == 'true';
  final enableServicePortFallback = args[7] == 'true';
  try {
    // TODO(bkonyi): add retry logic similar to that in vmservice_server.dart
    // See https://github.com/dart-lang/sdk/issues/43192.
    final dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
      serviceUri: serviceUri,
      enableAuthCodes: !disableServiceAuthCodes,
      ipv6: address.type == InternetAddressType.IPv6,
      devToolsConfiguration: startDevTools && devToolsBuildDirectory != null
          ? DevToolsConfiguration(
              enable: startDevTools,
              customBuildDirectoryPath: devToolsBuildDirectory,
            )
          : null,
      logRequests: logRequests,
      enableServicePortFallback: enableServicePortFallback,
    );
    stderr.write(json.encode({
      'state': 'started',
      if (dds.devToolsUri != null) 'devToolsUri': dds.devToolsUri.toString(),
    }));
  } catch (e, st) {
    stderr.write(json.encode({
      'state': 'error',
      'error': '$e',
      'stacktrace': '$st',
    }));
  }
}
