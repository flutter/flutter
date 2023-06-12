// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';

extension PageUtils on Page {
  void throwIfIsLast() {
    if (isLast) {
      throw StateError('Page.next() cannot be called when Page.isLast == true');
    }
  }
}
