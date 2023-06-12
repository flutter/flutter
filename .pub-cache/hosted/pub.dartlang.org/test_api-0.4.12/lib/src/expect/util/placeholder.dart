// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A class that's used as a default argument to detect whether an argument was
/// passed.
///
/// We use a custom class for this rather than just `const Object()` so that
/// callers can't accidentally pass the placeholder value.
class _Placeholder {
  const _Placeholder();
}

/// A placeholder to use as a default argument value to detect whether an
/// argument was passed.
const placeholder = _Placeholder();
