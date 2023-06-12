// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test validates integration of "why not promoted" when the user tries to
// promote `this`.

// TODO(paulberry): once we support adding "why not promoted" information to
// errors that aren't related to null safety, test references to `this` in
// classes and mixins.

extension on int? {
  extension_explicit_this() {
    if (this == null) return;
    this. /*notPromoted(thisNotPromoted)*/ isEven;
  }

  extension_implicit_this() {
    if (this == null) return;
    /*notPromoted(thisNotPromoted)*/ isEven;
  }
}
