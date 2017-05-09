// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/executable.dart' as executable;

// Temporary workaround for https://github.com/flutter/flutter/issues/9727
bool get initializeLibNotify {
  final DateTime date = new DateTime.now();
  return date.month == 1;
}

void main(List<String> args) {
  // ignore: UNUSED_LOCAL_VARIABLE
  final bool x = initializeLibNotify;
  executable.main(args);
}
