// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/core.dart';

main() async {
  var x = await (new Future.value(42));
  assert(x == 42);
}
