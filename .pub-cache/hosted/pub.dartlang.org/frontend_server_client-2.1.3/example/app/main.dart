// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as p;

Future<void> main() async {
  print(message);
  while (!message.contains('goodbye')) {
    print('waiting for hot reload to change message');
    await Future.delayed(const Duration(seconds: 1));
  }
  print(message);
}

String get message => p.join('hello', 'world');
