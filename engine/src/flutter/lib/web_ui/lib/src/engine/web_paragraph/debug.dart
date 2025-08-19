// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class WebParagraphDebug {
  static const bool logging = false;

  static void log(String arg) {
    if (logging) {
      print(arg);
    }
  }

  static void error(String arg) {
    print('ERROR: $arg');
  }
}
