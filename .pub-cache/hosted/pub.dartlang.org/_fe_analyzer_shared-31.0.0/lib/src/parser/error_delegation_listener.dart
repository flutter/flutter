// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart' show Message;

import '../scanner/token.dart' show Token;

import 'listener.dart' show Listener;

/// A listener which forwards error reports to another listener but ignores
/// all other events.
class ErrorDelegationListener extends Listener {
  Listener delegate;

  ErrorDelegationListener(this.delegate);

  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    return delegate.handleRecoverableError(message, startToken, endToken);
  }
}
