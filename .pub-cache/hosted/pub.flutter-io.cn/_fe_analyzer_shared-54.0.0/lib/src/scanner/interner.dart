// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The interface `Interner` defines the behavior of objects that can intern
 * strings.
 */
abstract class Interner {
  /**
   * Return a string that is identical to all of the other strings that have
   * been interned that are equal to the given [string].
   */
  String intern(String string);
}

/**
 * The class `NullInterner` implements an interner that does nothing (does not
 * actually intern any strings).
 */
class NullInterner implements Interner {
  @override
  String intern(String string) => string;
}
