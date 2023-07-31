// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

abstract class RpcErrorCodes {
  static json_rpc.RpcException buildRpcException(int code, {dynamic data}) {
    return json_rpc.RpcException(
      code,
      errorMessages[code]!,
      data: data,
    );
  }

  // These error codes must be kept in sync with those in vm/json_stream.h and
  // vmservice.dart.
  // static const kParseError = -32700;
  // static const kInvalidRequest = -32600;
  static const kMethodNotFound = -32601;

  // static const kInvalidParams = -32602;
  // static const kInternalError = -32603;

  // static const kExtensionError = -32000;

  static const kFeatureDisabled = 100;

  // static const kCannotAddBreakpoint = 102;
  static const kStreamAlreadySubscribed = 103;
  static const kStreamNotSubscribed = 104;

  // static const kIsolateMustBeRunnable = 105;
  // static const kIsolateMustBePaused = 106;
  // static const kCannotResume = 107;
  // static const kIsolateIsReloading = 108;
  // static const kIsolateReloadBarred = 109;
  // static const kIsolateMustHaveReloaded = 110;
  static const kServiceAlreadyRegistered = 111;
  static const kServiceDisappeared = 112;
  static const kExpressionCompilationError = 113;

  // static const kInvalidTimelineRequest = 114;

  // Experimental (used in private rpcs).
  // static const kFileSystemAlreadyExists = 1001;
  // static const kFileSystemDoesNotExist = 1002;
  // static const kFileDoesNotExist = 1003;

  static const errorMessages = {
    kFeatureDisabled: 'Feature is disabled',
    kStreamAlreadySubscribed: 'Stream already subscribed',
    kStreamNotSubscribed: 'Stream not subscribed',
    kServiceAlreadyRegistered: 'Service already registered',
    kServiceDisappeared: 'Service has disappeared',
    kExpressionCompilationError: 'Expression compilation error',
  };
}
