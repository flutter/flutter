// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show CommentToken, Token;

/// Search for the token before [target] starting the search with [start].
/// Return `null` if [target] is a comment token
/// or the previous token cannot be found.
Token? findPrevious(Token start, Token? target) {
  if (start == target || target is CommentToken) {
    return null;
  }
  Token token = start is CommentToken ? start.parent! : start;
  do {
    Token next = token.next!;
    if (next == target) {
      return token;
    }
    token = next;
  } while (!token.isEof);
  return null;
}
