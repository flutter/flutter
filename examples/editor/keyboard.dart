// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/shell.dart' as shell;
import 'package:sky/services/keyboard/keyboard.mojom.dart';

class _KeyboardConnection {
  KeyboardServiceProxy proxy;

  _KeyboardConnection() {
    proxy = new KeyboardServiceProxy.unbound();
    shell.requestService(proxy);
  }

  KeyboardService get keyboard => proxy.ptr;
}

final _KeyboardConnection _connection = new _KeyboardConnection();
final KeyboardService keyboard = _connection.keyboard;
