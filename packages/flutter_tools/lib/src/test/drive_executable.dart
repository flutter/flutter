// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test_core/src/executable.dart' as executable; // ignore: implementation_imports

// A trivial wrapper around test_core.
Future<void> main(List<String> args) async {
  await executable.main(args);
}
