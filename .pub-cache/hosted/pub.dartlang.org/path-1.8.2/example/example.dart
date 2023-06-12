// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

void main() {
  print('Current path style: ${p.style}');

  print('Current process path: ${p.current}');

  print('Separators');
  for (var entry in [p.posix, p.windows, p.url]) {
    print('  ${entry.style.toString().padRight(7)}: ${entry.separator}');
  }
}
