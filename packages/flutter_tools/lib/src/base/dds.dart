// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart' as dds;

import '../globals.dart' as globals;
import 'io.dart' as io;

class DartDevelopmentService {
  Future<Stream<Uri>> startDartDevelopmentService(
    Uri observatoryUri,
    int hostVmServicePort,
    bool disableServiceAuthCodes,
    bool ipv6,
    ) async {
    final Uri ddsUri = Uri(
      scheme: 'http',
      host: (ipv6 ?
        io.InternetAddress.loopbackIPv6 :
        io.InternetAddress.loopbackIPv4
      ).host,
      port: hostVmServicePort ?? 0,
    );
    globals.printTrace(
      'Launching a Dart Developer Service (DDS) instance at $ddsUri, '
      'connecting to VM service at $observatoryUri.'
    );
    final dds.DartDevelopmentService service =
      await dds.DartDevelopmentService.startDartDevelopmentService(
        observatoryUri,
        serviceUri: ddsUri,
        enableAuthCodes: disableServiceAuthCodes,
      );
    globals.printTrace('DDS is listening at ${service.uri}.');
    return Stream<Uri>
      .value(service.uri)
      .asBroadcastStream();
  }
}
