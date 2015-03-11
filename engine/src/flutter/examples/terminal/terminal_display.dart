// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

// Interface for a terminal display, able to accept bytes (from the computer)
// and typically displaying them (or possibly handling them as escape codes,
// etc.) and able to get bytes from the "user".
abstract class TerminalDisplay {
  void putChar(int byte);
  Future<int> getChar();

  // TODO(vtl): Should probably also have facilities for putting many bytes at a
  // time or getting as many bytes as available.
}
