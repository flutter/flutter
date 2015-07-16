// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

main() {
  (new Timer(new Duration(seconds: 1), () {
    print("Hello, world after one second!");
  }));
}
