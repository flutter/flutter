// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class WebParagraphDebug {
  static bool logging = false;
  static bool apiLogging = false;

  static void log(String arg) {
    assert(() {
      if (logging) {
        print(arg);
      }
      return true;
    }());
  }

  static void apiTrace(String arg) {
    assert(() {
      if (apiLogging || logging) {
        print(arg);
      }
      return true;
    }());
  }

  static void warning(String arg) {
    assert(() {
      print('WARNING: $arg');
      return true;
    }());
  }

  static void error(String arg) {
    assert(() {
      print('ERROR: $arg');
      return true;
    }());
  }
}
