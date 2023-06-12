// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'visitors.dart';

abstract class Spec {
  R accept<R>(SpecVisitor<R> visitor, [R context]);
}

/// Returns a generic [Spec] that is lazily generated when visited.
Spec lazySpec(Spec Function() generate) => _LazySpec(generate);

class _LazySpec implements Spec {
  final Spec Function() generate;

  const _LazySpec(this.generate);

  @override
  R accept<R>(SpecVisitor<R> visitor, [R context]) =>
      generate().accept(visitor, context);
}
