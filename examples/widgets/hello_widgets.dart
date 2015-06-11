// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/widgets/wrappers.dart';

class HelloWorldApp extends App {
  UINode build() {
    return new Text('Hello, fn2!');
  }
}

void main() {
  new HelloWorldApp();
}
