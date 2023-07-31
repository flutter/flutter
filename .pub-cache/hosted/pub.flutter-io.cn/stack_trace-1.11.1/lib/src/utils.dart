// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The line used in the string representation of stack chains to represent
/// the gap between traces.
const chainGap = '===== asynchronous gap ===========================\n';

/// The line used in the string representation of VM stack chains to represent
/// the gap between traces.
final vmChainGap = RegExp(r'^<asynchronous suspension>\n?$', multiLine: true);

// TODO(nweiz): When cross-platform imports work, use them to set this.
/// Whether we're running in a JS context.
const bool inJS = 0.0 is int;
