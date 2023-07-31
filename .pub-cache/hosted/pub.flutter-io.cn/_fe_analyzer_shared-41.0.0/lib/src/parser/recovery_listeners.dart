// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../scanner/token.dart' show Token;

import 'forwarding_listener.dart' show ForwardingListener;

class ClassHeaderRecoveryListener extends ForwardingListener {
  Token? extendsKeyword;
  Token? implementsKeyword;
  Token? withKeyword;

  void clear() {
    extendsKeyword = null;
    implementsKeyword = null;
    withKeyword = null;
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    this.extendsKeyword = extendsKeyword;
    super.handleClassExtends(extendsKeyword, typeCount);
  }

  @override
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    this.implementsKeyword = implementsKeyword;
    super.handleImplements(implementsKeyword, interfacesCount);
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    this.withKeyword = withKeyword;
    super.handleClassWithClause(withKeyword);
  }
}

class ImportRecoveryListener extends ForwardingListener {
  Token? asKeyword;
  Token? deferredKeyword;
  Token? ifKeyword;
  bool hasCombinator = false;

  void clear() {
    asKeyword = null;
    deferredKeyword = null;
    ifKeyword = null;
    hasCombinator = false;
  }

  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    this.ifKeyword = ifKeyword;
    super.endConditionalUri(ifKeyword, leftParen, equalSign);
  }

  void endHide(Token hideKeyword) {
    this.hasCombinator = true;
    super.endHide(hideKeyword);
  }

  void endShow(Token showKeyword) {
    this.hasCombinator = true;
    super.endShow(showKeyword);
  }

  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    this.deferredKeyword = deferredKeyword;
    this.asKeyword = asKeyword;
    super.handleImportPrefix(deferredKeyword, asKeyword);
  }
}

class MixinHeaderRecoveryListener extends ForwardingListener {
  Token? onKeyword;
  Token? implementsKeyword;

  void clear() {
    onKeyword = null;
    implementsKeyword = null;
  }

  @override
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    this.implementsKeyword = implementsKeyword;
    super.handleImplements(implementsKeyword, interfacesCount);
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    this.onKeyword = onKeyword;
    super.handleMixinOn(onKeyword, typeCount);
  }
}
