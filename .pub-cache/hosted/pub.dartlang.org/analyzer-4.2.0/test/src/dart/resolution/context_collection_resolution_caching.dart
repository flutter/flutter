// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/byte_store.dart';

final _sharedByteStore = MemoryByteStore();
final _useSharedByteStore = true;

MemoryByteStore getContextResolutionTestByteStore() {
  if (_useSharedByteStore) {
    return _sharedByteStore;
  } else {
    return MemoryByteStore();
  }
}
