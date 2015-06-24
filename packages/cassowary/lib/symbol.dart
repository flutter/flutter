// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

enum SymbolType { invalid, external, slack, error, dummy, }

class Symbol {
  final SymbolType type;
  int tick;

  Symbol(this.type, this.tick);
}
