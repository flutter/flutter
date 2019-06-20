// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

/// Creates a console connection to an Android emulator that can be used to run
/// commands such as "avd name" which are not available to ADB.
class AndroidConsole {
  AndroidConsole._(this.socket):
    queue = StreamQueue<String>(socket.asyncMap(ascii.decode));

  final Socket socket;
  final StreamQueue<String> queue;

  static Future<AndroidConsole> connect(String host, int port) async {
    final Socket socket = await Socket.connect(host, port);
    final AndroidConsole console = AndroidConsole._(socket);
    // Discard initial connection text.
    await console._readResponse();
    return console;
  }

  Future<String> getAvdName() async {
    _write('avd name\n');
    return _readResponse();
  }

  void destroy()  => socket.destroy();

  Future<String> _readResponse() async {
    String text = (await queue.next).trim();
    if (text.endsWith('\nOK')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  void _write(String text) {
    socket.add(ascii.encode(text));
  }
}
