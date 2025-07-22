// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains annotations for JS interop on Wasm.

class JS {
  final String? name;
  const JS([this.name]);
}

class _Anonymous {
  const _Anonymous();
}

class _StaticInterop {
  const _StaticInterop();
}

const _Anonymous anonymous = _Anonymous();

const _StaticInterop staticInterop = _StaticInterop();
