// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart' as dds;

import '../globals.dart' as globals;
import 'io.dart' as io;

class DartDevelopmentService {
  Future<void> startDartDevelopmentService(
    Uri observatoryUri,
    bool ipv6,
    ) async {
    final Uri ddsUri = Uri(
      scheme: 'http',
      host: (ipv6 ?
        io.InternetAddress.loopbackIPv6 :
        io.InternetAddress.loopbackIPv4
      ).host,
      port: 0,
    );
    globals.printTrace(
      'Launching a Dart Developer Service (DDS) instance at $ddsUri, '
      'connecting to VM service at $observatoryUri.'
      '\n${StackTrace.current}'
    );
    try {
      _ddsInstance =
        await dds.DartDevelopmentService.startDartDevelopmentService(
          observatoryUri,
          serviceUri: ddsUri,
        );
      globals.printTrace('DDS is listening at ${_ddsInstance.uri}.');
    } on dds.DartDevelopmentServiceException catch (e) {
      globals.printError('Warning: Failed to start DDS: ${e.message}');
    }
  }

  Future<void> shutdown() async => await _ddsInstance?.shutdown();

  dds.DartDevelopmentService _ddsInstance;
}