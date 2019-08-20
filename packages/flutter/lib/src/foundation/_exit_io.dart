// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

/// The dart:io implementation of an exit call.
///
/// This should only be invoked by service extensions in debug or profile mode.
void exit() {
  io.exit(0);
}
