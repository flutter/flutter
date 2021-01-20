// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart' as dds;
import 'package:meta/meta.dart';

import 'common.dart';
import 'io.dart' as io;
import 'logger.dart';

@visibleForTesting
Future<dds.DartDevelopmentService> Function(
  Uri,
  {bool enableAuthCodes,
  bool ipv6,
  Uri serviceUri,
}) ddsLauncherCallback = dds.DartDevelopmentService.startDartDevelopmentService;

/// Helper class to launch a [dds.DartDevelopmentService]. Allows for us to
/// mock out this functionality for testing purposes.
class DartDevelopmentService {
  DartDevelopmentService({@required this.logger});

  final Logger logger;
  dds.DartDevelopmentService _ddsInstance;

  Uri get uri => _ddsInstance?.uri ?? _existingDdsUri;
  Uri _existingDdsUri;

  Future<void> get done => _completer.future;
  final Completer<void> _completer = Completer<void>();

  Future<void> startDartDevelopmentService(
    Uri observatoryUri,
    int hostPort,
    bool ipv6,
    bool disableServiceAuthCodes,
  ) async {
    final Uri ddsUri = Uri(
      scheme: 'http',
      host: (ipv6 ?
        io.InternetAddress.loopbackIPv6 :
        io.InternetAddress.loopbackIPv4
      ).host,
      port: hostPort ?? 0,
    );
    logger.printTrace(
      'Launching a Dart Developer Service (DDS) instance at $ddsUri, '
      'connecting to VM service at $observatoryUri.',
    );
    try {
      _ddsInstance = await ddsLauncherCallback(
          observatoryUri,
          serviceUri: ddsUri,
          enableAuthCodes: !disableServiceAuthCodes,
          ipv6: ipv6,
        );
      unawaited(_ddsInstance.done.whenComplete(() {
        if (!_completer.isCompleted) {
          _completer.complete();
        }
      }));
      logger.printTrace('DDS is listening at ${_ddsInstance.uri}.');
    } on dds.DartDevelopmentServiceException catch (e) {
      logger.printTrace('Warning: Failed to start DDS: ${e.message}');
      if (e.errorCode == dds.DartDevelopmentServiceException.existingDdsInstanceError) {
        try {
          _existingDdsUri = Uri.parse(
            e.message.split(' ').firstWhere((String e) => e.startsWith('http'))
          );
        } on StateError {
          logger.printError(
            'DDS has failed to start and there is not an existing DDS instance '
            'available to connect to. Please comment on '
            'https://github.com/flutter/flutter/issues/72385 with output from '
            '"flutter doctor -v" and the following error message:\n\n ${e.message}.'
          );
          // Wrap the DDS error message in a StateError so it can be collected
          // by the crash handler.
          throw StateError(e.message);
        }
      }
      if (!_completer.isCompleted) {
        _completer.complete();
      }
      rethrow;
    }
  }

  Future<void> shutdown() async => await _ddsInstance?.shutdown();
}
