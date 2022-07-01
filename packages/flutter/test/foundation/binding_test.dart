// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// based on the sample code in foundation/binding.dart

mixin FooBinding on BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  static FooBinding get instance => BindingBase.checkInstance(_instance);
  static FooBinding? _instance;
}

class FooLibraryBinding extends BindingBase with FooBinding {
  static FooBinding ensureInitialized() {
    if (FooBinding._instance == null) {
      FooLibraryBinding();
    }
    return FooBinding.instance;
  }
}


void main() {
  test('BindingBase.debugBindingType', () async {
    expect(BindingBase.debugBindingType(), isNull);
    FooLibraryBinding.ensureInitialized();
    expect(BindingBase.debugBindingType(), FooLibraryBinding);
  });
}
