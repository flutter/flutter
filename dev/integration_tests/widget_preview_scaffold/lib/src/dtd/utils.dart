// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @docImport: package:dtd/dtd.dart
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

extension WidgetPreviewScaffoldDtdUtils on DartToolingDaemon {
  /// A [streamListen] implementation that ignores already subscribed exceptions.
  Future<void> safeStreamListen(String streamId) async {
    try {
      await streamListen(streamId);
    } on RpcException catch (e) {
      if (e.code != RpcErrorCodes.kStreamAlreadySubscribed) {
        // TODO(bkonyi): consider logging an error.
        rethrow;
      }
    }
  }

  /// A [call] implementation that returns `null` if the service disappears or the method is not
  /// found.
  Future<DTDResponse?> safeCall(
    String? serviceName,
    String methodName, {
    Map<String, Object?>? params,
  }) async {
    try {
      return await call(serviceName, methodName, params: params);
    } on RpcException catch (e) {
      if (e.code != RpcErrorCodes.kMethodNotFound &&
          e.code != RpcErrorCodes.kServiceDisappeared) {
        rethrow;
      }
      return null;
    }
  }
}
