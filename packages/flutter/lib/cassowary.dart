// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An implementation of the Cassowary constraint solving algorithm in Dart.
///
/// To use, import `package:flutter/cassowary.dart`.
///
/// This is used by the [RenderAutoLayout] render object in the rendering
/// library and by the [AutoLayout] widget in the widget library.
///
/// See also:
///
/// * <https://en.wikipedia.org/wiki/Cassowary_(software)>
/// * <https://constraints.cs.washington.edu/solvers/cassowary-tochi.pdf>
library cassowary;

export 'src/cassowary/constraint.dart';
export 'src/cassowary/expression.dart';
export 'src/cassowary/term.dart';
export 'src/cassowary/equation_member.dart';
export 'src/cassowary/constant_member.dart';
export 'src/cassowary/solver.dart';
export 'src/cassowary/result.dart';
export 'src/cassowary/parser_exception.dart';
export 'src/cassowary/param.dart';
export 'src/cassowary/priority.dart';
