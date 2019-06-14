// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  FlutterError.reportError(FlutterErrorDetails(exception: 'OH NO DID IT FAIL'));
  runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));
  throw 'An exception!';
}
