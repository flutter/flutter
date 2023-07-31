// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Interface representing a syntactic entity (either a token or an AST node)
 * which has a location and extent in the source file.
 */
abstract class SyntacticEntity {
  /**
   * Return the offset from the beginning of the file to the character after the
   * last character of the syntactic entity.
   */
  int get end;

  /**
   * Return the number of characters in the syntactic entity's source range.
   */
  int get length;

  /**
   * Return the offset from the beginning of the file to the first character in
   * the syntactic entity.
   */
  int get offset;
}
