// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@_debugAssert
library;

const String _debugAssert = '';

String globalVaraibleFromDebugLib = '';

void globalFunctionFromDebugLib() { }

mixin MixinFromDebugLib {
  static int staticVarFromDebugLib = 0;

  static void staticMethodFromDebugLib() {  }

  int fieldFromDebugLib = 0;

  int get debugGetSet => _debugGetSet;
  int _debugGetSet = 0;
  set debugGetSet(int value) => _debugGetSet = value;

  void methodFromDebugLib() { }

  MixinFromDebugLib operator +(covariant MixinFromDebugLib rhs);

  int operator ~() => ~debugGetSet;

  int operator [](int index) => index;
}

class ClassFromDebugLibWithNamedConstructor {
  ClassFromDebugLibWithNamedConstructor.constructor();
}

class ClassFromDebugLibWithImplicitDefaultConstructor { }

class ClassFromDebugLibWithExplicitDefaultConstructor {
  ClassFromDebugLibWithExplicitDefaultConstructor();
}
