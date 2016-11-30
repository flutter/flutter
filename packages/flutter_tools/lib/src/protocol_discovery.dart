// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'device.dart';

/// Discover service protocol ports on devices.
class ProtocolDiscovery {
  /// [logReader] - a [DeviceLogReader] to look for service messages in.
  ProtocolDiscovery(DeviceLogReader logReader, String serviceName)
      : _logReader = logReader, _serviceName = serviceName {
    assert(_logReader != null);
    _subscription = _logReader.logLines.listen(_onLine);
  }

  static const String kObservatoryService = 'Observatory';
  static const String kDiagnosticService = 'Diagnostic server';

  final DeviceLogReader _logReader;
  final String _serviceName;

  Completer<Uri> _completer = new Completer<Uri>();
  StreamSubscription<String> _subscription;

  /// The [Future] returned by this function will complete when the next service
  /// Uri is found.
  Future<Uri> nextUri() => _completer.future;

  void cancel() {
    _subscription.cancel();
  }

  void _onLine(String line) {
    Uri uri;
    String prefix = '$_serviceName listening on ';
    int index = line.indexOf(prefix + 'http://');
    if (index >= 0) {
      try {
        uri = Uri.parse(line.substring(index + prefix.length));
      } catch (_) {
        // Ignore errors.
      }
    }
    if (uri != null)
      _located(uri);
  }

  void _located(Uri uri) {
    assert(_completer != null);
    assert(!_completer.isCompleted);

    _completer.complete(uri);
    _completer = new Completer<Uri>();
  }
}
