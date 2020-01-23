// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  const Text text = Text('Hello, world!', textDirection: TextDirection.ltr);
  // These calls must not result in an error. They behave differently in
  // release mode compared to debug or profile.
  // The test will grep logcat for any errors emitted by Flutter.
  print(text.toDiagnosticsNode());
  print(text.toStringDeep());
  runApp(
    const Center(
      child: text,
    ),
  );
}
