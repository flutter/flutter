// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mojom/keyboard/keyboard.mojom.dart';

import '../framework/shell.dart' as shell;

class _KeyboardConnection {
  KeyboardServiceProxy proxy;

  _KeyboardConnection() {
    proxy = new KeyboardServiceProxy.unbound();
    shell.requestService("mojo:keyboard", proxy);
  }

  KeyboardService get keyboard => proxy.ptr;
}

final _KeyboardConnection _connection = new _KeyboardConnection();
final KeyboardService keyboard = _connection.keyboard;
