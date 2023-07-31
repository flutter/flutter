// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'cascade_test.dart' as cascade;
import 'create_middleware_test.dart' as create_middleware;
import 'hijack_test.dart' as hijack;
import 'log_middleware_test.dart' as log_middleware;
import 'message_change_test.dart' as message_change;
import 'message_test.dart' as message;
import 'pipeline_test.dart' as pipeline;
import 'request_test.dart' as request;
import 'response_test.dart' as response;
import 'shelf_io_test.dart' as shelf_io;

void main() {
  group('cascade', cascade.main);
  group('create_middleware', create_middleware.main);
  group('hijack', hijack.main);
  group('log_middleware', log_middleware.main);
  group('message_change', message_change.main);
  group('message', message.main);
  group('pipeline', pipeline.main);
  group('request', request.main);
  group('response', response.main);
  group('shelf_io', shelf_io.main);
}
