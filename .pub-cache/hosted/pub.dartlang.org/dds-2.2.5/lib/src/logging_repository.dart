// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'client.dart';
import 'common/ring_buffer.dart';

/// [LoggingRepository] is used to store historical log messages from the
/// target VM service. Clients which connect to DDS and subscribe to the
/// `Logging` stream will be sent all messages contained within this repository
/// upon initial subscription.
class LoggingRepository extends RingBuffer<Map<String, dynamic>> {
  LoggingRepository([int logHistoryLength = 10000]) : super(logHistoryLength) {
    // TODO(bkonyi): enforce log history limit when DartDevelopmentService
    // allows for this to be set via Dart code.
  }

  void sendHistoricalLogs(DartDevelopmentServiceClient client) {
    // Only send historical log messages when the client first subscribes to
    // the logging stream.
    if (_sentHistoricLogsClientSet.contains(client)) {
      return;
    }
    _sentHistoricLogsClientSet.add(client);
    for (final log in this()) {
      client.sendNotification('streamNotify', log);
    }
  }

  @override
  void resize(int size) {
    if (size > _kMaxLogBufferSize) {
      throw json_rpc.RpcException.invalidParams(
        "'size' must be less than $_kMaxLogBufferSize",
      );
    }
    super.resize(size);
  }

  // The set of clients which have subscribed to the Logging stream at some
  // point in time.
  final Set<DartDevelopmentServiceClient> _sentHistoricLogsClientSet = {};
  static const int _kMaxLogBufferSize = 100000;
}
