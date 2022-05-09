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
  Uri remoteVmServiceUri, {
  bool enableAuthCodes,
  bool ipv6,
  Uri? serviceUri,
  List<String> cachedUserTags,
}) ddsLauncherCallback = dds.DartDevelopmentService.startDartDevelopmentService;

/// Helper class to launch a [dds.DartDevelopmentService]. Allows for us to
/// mock out this functionality for testing purposes.
class DartDevelopmentService {
  dds.DartDevelopmentService? _ddsInstance;

  Uri? get uri => _ddsInstance?.uri ?? _existingDdsUri;
  Uri? _existingDdsUri;

  Future<void> get done => _completer.future;
  final Completer<void> _completer = Completer<void>();

  Future<void> startDartDevelopmentService(
    Uri observatoryUri, {
    required Logger logger,
    int? hostPort,
    bool? ipv6,
    bool? disableServiceAuthCodes,
    bool cacheStartupProfile = false,
  }) async {
    final Uri ddsUri = Uri(
      scheme: 'http',
      host: ((ipv6 ?? false) ? io.InternetAddress.loopbackIPv6 : io.InternetAddress.loopbackIPv4).host,
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
          enableAuthCodes: disableServiceAuthCodes != true,
          ipv6: ipv6 ?? false,
          // Enables caching of CPU samples collected during application startup.
          cachedUserTags: cacheStartupProfile ? const <String>['AppStartUp'] : const <String>[],
        );
      unawaited(_ddsInstance?.done.whenComplete(() {
        if (!_completer.isCompleted) {
          _completer.complete();
        }
      }));
      logger.printTrace('DDS is listening at ${_ddsInstance?.uri}.');
    } on dds.DartDevelopmentServiceException catch (e) {
      logger.printTrace('Warning: Failed to start DDS: ${e.message}');
      if (e.errorCode == dds.DartDevelopmentServiceException.existingDdsInstanceError) {
        try {
          _existingDdsUri = Uri.parse(
            e.message.split(' ').firstWhere((String e) => e.startsWith('http'))
          );
        } on StateError {
          if (e.message.contains('Existing VM service clients prevent DDS from taking control.')) {
            throwToolExit('${e.message}. Please rebuild your application with a newer version of Flutter.');
          }
          logger.printError(
            'DDS has failed to start and there is not an existing DDS instance '
            'available to connect to. Please file an issue at https://github.com/flutter/flutter/issues '
            'with the following error message:\n\n ${e.message}.'
          );
          // DDS was unable to start for an unknown reason. Raise a StateError
          // so it can be reported by the crash reporter.
          throw StateError(e.message);
        }
      }
      if (!_completer.isCompleted) {
        _completer.complete();
      }
      rethrow;
    }
  }

  Future<void> shutdown() async => _ddsInstance?.shutdown();
}
