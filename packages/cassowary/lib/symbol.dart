// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

enum _SymbolType { invalid, external, slack, error, dummy, }

class _Symbol {
  final _SymbolType type;
  final int tick;

  _Symbol(this.type, this.tick);

  String toString() {
    String typeString = 'unknown';
    switch (type) {
      case _SymbolType.invalid:
        typeString = 'i';
        break;
      case _SymbolType.external:
        typeString = 'v';
        break;
      case _SymbolType.slack:
        typeString = 's';
        break;
      case _SymbolType.error:
        typeString = 'e';
        break;
      case _SymbolType.dummy:
        typeString = 'd';
        break;
    }
    return '$typeString$tick';
  }
}
