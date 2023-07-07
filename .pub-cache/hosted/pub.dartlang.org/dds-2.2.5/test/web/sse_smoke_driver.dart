// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file must be compiled for changes to be picked up.
//
// Run the following command from the root of this package if this file is
// updated:
//
// dart2js -o test/web/sse_smoke_driver.dart.js test/web/sse_smoke_driver.dart

import 'dart:convert';

import 'package:async/async.dart';
import 'package:sse/client/sse_client.dart';
import 'package:vm_service/vm_service.dart';

Future<void> main() async {
  // Connect to test server
  final channel = SseClient('/test');
  final testerStream = StreamQueue<String>(channel.stream);

  // Connect to DDS
  final ddsUri = await testerStream.next;
  final ddsChannel = SseClient(ddsUri);

  final vmService = VmService(
    ddsChannel.stream,
    (e) => ddsChannel.sink.add(e),
  );
  final version = await vmService.getVersion();
  channel.sink.add(json.encode(version.json));
  ddsChannel.close();
}
