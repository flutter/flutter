// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/fn.dart';
import '../../framework/components/button.dart';

class WidgetsApp extends App {
  Node build() {
    return new Button(content: new Text('Go'), level: 1);
  }
}
