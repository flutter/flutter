// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// Compares image pixels against a golden image file on the host system.
///
/// This comparator will send a request, using the VM service protocol, to a
/// host script (i.e. the _driver_ script, running in a Dart VM on the host
/// desktop OS), which will then forward the comparison to a concrete
/// [GoldenFileComparator].
///
/// To use, run [useIfRunningOnDevice] in the `main()` of a test file or similar:
///
/// ```dart
/// import 'package:integration_test/integration_test.dart';
///
/// void main() {
///   VmServiceProxyGoldenFileComparator.useIfRunningOnDevice();
///
///   // Actual tests and such below.
/// }
/// ```
///
/// When either [compare] or [update] is called, the following event is sent
/// with [dev.postEvent]:
///
/// ```dart
/// postEvent('compare' /* or 'update' */, {
///   'id':    1001,                 // a valid unique integer, often incrementing;
///   'path':  'path/to/image.png',  // golden key created by matchesGoldenFile;
///   'bytes': '...base64encoded',   // base64 encoded bytes representing the current image.
/// }, stream: 'integration_test.VmServiceProxyGoldenFileComparator');
/// ```
///
/// The comparator expects a response at the service extension
/// `ext.integration_test.VmServiceProxyGoldenFileComparator` that is either
/// of the following formats:
///
/// ```dart
/// {
///   'error': 'Description of why the operation failed'
/// }
/// ```
///
/// or:
///
/// ```dart
/// {
///   'result': true /* or possibly false, in the case of 'compare' calls */
/// }
/// ```
///
/// See also:
///
///   * [matchesGoldenFile], the function that invokes the comparator.
@experimental
final class VmServiceProxyGoldenFileComparator extends GoldenFileComparator {
  VmServiceProxyGoldenFileComparator._() {
    dev.registerExtension(_kServiceName, _postEventResponseHandler);
  }

  static bool get _isRunningOnHost {
    if (kIsWeb) {
      return false;
    }
    return !io.Platform.isAndroid && !io.Platform.isIOS;
  }

  static void _assertNotRunningOnFuchsia() {
    if (!kIsWeb && io.Platform.isFuchsia) {
      throw UnsupportedError('Fuchsia is not supported');
    }
  }

  /// Conditionally sets [goldenFileComparator] to [VmServiceProxyGoldenFileComparator].
  ///
  /// If running on a non-mobile non-web platform (i.e. desktop), this method has no effect.
  static void useIfRunningOnDevice() {
    if (_isRunningOnHost) {
      return;
    }
    _assertNotRunningOnFuchsia();
    goldenFileComparator = _kInstance;
  }

  static final GoldenFileComparator _kInstance = VmServiceProxyGoldenFileComparator._();
  static const String _kServiceName = 'ext.$_kEventName';
  static const String _kEventName = 'integration_test.VmServiceProxyGoldenFileComparator';

  Future<dev.ServiceExtensionResponse> _postEventResponseHandler(
    String method,
    Map<String, String> parameters,
  ) async {
    // Treat the method as the ID number of the pending request.
    final int? methodId = int.tryParse(method);
    if (methodId == null) {
      return dev.ServiceExtensionResponse.error(
        dev.ServiceExtensionResponse.extensionError,
        'Not a valid (integer) method (id): "$method".',
      );
    }
    final Completer<bool>? completer = _pendingRequests[methodId];
    if (completer == null) {
      return dev.ServiceExtensionResponse.error(
        dev.ServiceExtensionResponse.extensionError,
        'No pending request with method ID "$method".',
      );
    }
    if (completer.isCompleted) {
      return dev.ServiceExtensionResponse.error(
        dev.ServiceExtensionResponse.extensionError,
        'Result already received for method ID "$method".',
      );
    }
    final String? error = parameters['error'];
    if (error != null) {
      completer.completeError(error);
      return dev.ServiceExtensionResponse.result('{}');
    }
    final String? result = parameters['result'];
    if (result == null) {
      return dev.ServiceExtensionResponse.error(
        dev.ServiceExtensionResponse.invalidParams,
        'Required parameter "result" not present in response.',
      );
    }
    if (bool.tryParse(result) case final bool result) {
      completer.complete(result);
      return dev.ServiceExtensionResponse.result('{}');
    } else {
      return dev.ServiceExtensionResponse.error(
        dev.ServiceExtensionResponse.invalidParams,
        'Required parameter "result" not a valid boolean: "$result".',
      );
    }
  }

  int _nextId = 0;
  final Map<int, Completer<bool>> _pendingRequests = <int, Completer<bool>>{};

  Future<bool> _postAndWait(Uint8List imageBytes, Uri golden, {required String operation}) async {
    final int nextId = ++_nextId;
    assert(!_pendingRequests.containsKey(nextId));

    final Completer<bool> completer = Completer<bool>();
    dev.postEvent(operation, <String, Object?>{
      'id': nextId,
      'path': '$golden',
      'bytes': base64.encode(imageBytes),
    }, stream: _kEventName);

    _pendingRequests[nextId] = completer;
    return completer.future;
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    return _postAndWait(imageBytes, golden, operation: 'compare');
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await _postAndWait(imageBytes, golden, operation: 'update');
  }
}
