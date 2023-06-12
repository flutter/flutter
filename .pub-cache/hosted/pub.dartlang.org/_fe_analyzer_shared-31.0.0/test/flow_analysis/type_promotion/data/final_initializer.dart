// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that final variables aren't promoted to a type of interest
// based on their initializer, but non-final variables are.

nonFinalPromotesWhenInitializerNonNullable(int i) {
  num? n = i;
  /*num*/ n;
}

nonFinalDoesNotPromoteWhenInitializerNullable(int? i) {
  num? n = i;
  n;
}

finalDoesNotPromote(int i) {
  final num? n = i;
  n;
}

lateNonFinalPromotesWhenInitializerNonNullable(int i) {
  late num? n = i;
  /*num*/ n;
}

lateNonFinalDoesNotPromoteWhenInitializerNullable(int? i) {
  late num? n = i;
  n;
}

lateFinalDoesNotPromote(int i) {
  late final num? n = i;
  n;
}
