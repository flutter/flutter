// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Map the URI to a WebSocket URI for the VM service protocol.
///
/// If the URI is already a VM Service WebSocket URI it will not be modified.
Uri convertToWebSocketUrl({required Uri serviceProtocolUrl}) {
  final isSecure = serviceProtocolUrl.isScheme('wss') ||
      serviceProtocolUrl.isScheme('https');
  final scheme = isSecure ? 'wss' : 'ws';

  final path = serviceProtocolUrl.path.endsWith('/ws')
      ? serviceProtocolUrl.path
      : (serviceProtocolUrl.path.endsWith('/')
          ? '${serviceProtocolUrl.path}ws'
          : '${serviceProtocolUrl.path}/ws');

  return serviceProtocolUrl.replace(scheme: scheme, path: path);
}
