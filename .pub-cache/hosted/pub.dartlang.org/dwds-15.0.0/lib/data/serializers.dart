// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'build_result.dart';
import 'connect_request.dart';
import 'debug_event.dart';
import 'devtools_request.dart';
import 'error_response.dart';
import 'extension_request.dart';
import 'isolate_events.dart';
import 'register_event.dart';
import 'run_request.dart';

part 'serializers.g.dart';

/// Serializers for all the types used in DWDS communication.
@SerializersFor([
  BatchedEvents,
  BatchedDebugEvents,
  BuildResult,
  ConnectRequest,
  DebugEvent,
  DevToolsRequest,
  DevToolsResponse,
  IsolateExit,
  IsolateStart,
  ExtensionRequest,
  ExtensionResponse,
  ExtensionEvent,
  ErrorResponse,
  RegisterEvent,
  RunRequest,
])
final Serializers serializers = _$serializers;
