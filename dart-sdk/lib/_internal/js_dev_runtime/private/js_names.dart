// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_names;

import 'dart:_runtime' as dart show typeTagSymbol;
import 'dart:_foreign_helper' show JS;

// TODO(nshahan) Is this ever useful for DDC?
String? unmangleGlobalNameIfPreservedAnyways(String name) => null;

/// Forwards to runtime library to get the unique JavaScript symbol for the
/// provided [name].
Object getSpecializedTestTag(String name) => dart.typeTagSymbol(name);
