// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'characters.dart';

extension StringCharacters on String {
  /// The [Characters] of this string.
  Characters get characters => Characters(this);
}
