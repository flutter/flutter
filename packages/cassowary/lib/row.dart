// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Row {
  final Map<Symbol, double> _cells = new Map<Symbol, double>();
  double _constant = 0.0;

  double get constant => _constant;
  Map<Symbol, double> get cells => _cells;

  double add(double value) => _constant += value;

  void insertSymbol(Symbol symbol, [double coefficient = 1.0]) {
    double val = _elvis(_cells[symbol], 0.0) + coefficient;

    if (_nearZero(val)) {
      _cells.remove(symbol);
    } else {
      _cells[symbol] = val + coefficient;
    }
  }

  void insertRow(Row other, [double coefficient = 1.0]) {
    _constant += other.constant * coefficient;
    other.cells.forEach((s, v) => insertSymbol(s, v * coefficient));
  }

  void removeSymbol(Symbol symbol) {
    _cells.remove(symbol);
  }

  void reverseSign() => _cells.forEach((s, v) => _cells[s] = -v);

  void solveForSymbol(Symbol symbol) {
    assert(_cells.containsKey(symbol));
    double coefficient = -1.0 / _cells[symbol];
    _cells.remove(symbol);
    _constant *= coefficient;
    _cells.forEach((s, v) => _cells[s] = v * coefficient);
  }

  void solveForSymbols(Symbol lhs, Symbol rhs) {
    insertSymbol(lhs, -1.0);
    solveForSymbol(rhs);
  }

  double coefficientForSymbol(Symbol symbol) => _elvis(_cells[symbol], 0.0);

  void substitute(Symbol symbol, Row row) {
    double coefficient = _cells[symbol];

    if (coefficient == null) {
      return;
    }

    _cells.remove(symbol);
    insertRow(row, coefficient);
  }
}
