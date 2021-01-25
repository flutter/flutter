// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart' as dds;
import 'package:meta/meta.dart';

import 'io.dart' as io;
import 'logger.dart';

/// Helper class to launch a [dds.DartDevelopmentService]. Allows for us to
/// mock out this functionality for testing purposes.
class DartDevelopmentService {
  DartDevelopmentService({@required this.logger});

  // TODO(bkonyi): enable once VM service can handle SSE forwarding for
  // Devtools (https://github.com/flutter/flutter/issues/62507)
  static const bool ddsDisabled = true;
  final Logger logger;
  dds.DartDevelopmentService _ddsInstance;

  Future<void> startDartDevelopmentService(
    Uri observatoryUri,
    bool ipv6,
  ) async {
    if (ddsDisabled) {
      logger.printTrace(
        'DDS is currently disabled due to '
        'https://github.com/flutter/flutter/issues/62507'
      );
      return;
    }
    final Uri ddsUri = Uri(
      scheme: 'http',
      host: (ipv6 ?
        io.InternetAddress.loopbackIPv6 :
        io.InternetAddress.loopbackIPv4
      ).host,
      port: 0,
    );
    logger.printTrace(
      'Launching a Dart Developer Service (DDS) instance at $ddsUri, '
      'connecting to VM service at $observatoryUri.',
    );
    try {
      _ddsInstance = await dds.DartDevelopmentService.startDartDevelopmentService(
          observatoryUri,
          serviceUri: ddsUri,
        );
      logger.printTrace('DDS is listening at ${_ddsInstance.uri}.');
    } on dds.DartDevelopmentServiceException catch (e) {
      logger.printError('Warning: Failed to start DDS: ${e.message}');
      rethrow;
    }
  }

  Future<void> shutdown() async => await _ddsInstance?.shutdown();
}
