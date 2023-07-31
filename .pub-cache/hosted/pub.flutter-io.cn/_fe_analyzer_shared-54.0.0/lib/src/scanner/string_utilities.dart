// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'interner.dart';

class StringUtilities {
  static Interner INTERNER = new NullInterner();

  static String intern(String string) => INTERNER.intern(string);
}
