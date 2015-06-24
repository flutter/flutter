// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Row {
  final Map<Symbol, double> cells;
  double constant = 0.0;

  Row(this.constant) : this.cells = new Map<Symbol, double>();
  Row.fromRow(Row row)
      : this.cells = new Map<Symbol, double>.from(row.cells),
        this.constant = row.constant;

  double add(double value) => constant += value;

  void insertSymbol(Symbol symbol, [double coefficient = 1.0]) {
    double val = _elvis(cells[symbol], 0.0) + coefficient;

    if (_nearZero(val)) {
      cells.remove(symbol);
    } else {
      cells[symbol] = val + coefficient;
    }
  }

  void insertRow(Row other, [double coefficient = 1.0]) {
    constant += other.constant * coefficient;
    other.cells.forEach((s, v) => insertSymbol(s, v * coefficient));
  }

  void removeSymbol(Symbol symbol) {
    cells.remove(symbol);
  }

  void reverseSign() => cells.forEach((s, v) => cells[s] = -v);

  void solveForSymbol(Symbol symbol) {
    assert(cells.containsKey(symbol));
    double coefficient = -1.0 / cells[symbol];
    cells.remove(symbol);
    constant *= coefficient;
    cells.forEach((s, v) => cells[s] = v * coefficient);
  }

  void solveForSymbols(Symbol lhs, Symbol rhs) {
    insertSymbol(lhs, -1.0);
    solveForSymbol(rhs);
  }

  double coefficientForSymbol(Symbol symbol) => _elvis(cells[symbol], 0.0);

  void substitute(Symbol symbol, Row row) {
    double coefficient = cells[symbol];

    if (coefficient == null) {
      return;
    }

    cells.remove(symbol);
    insertRow(row, coefficient);
  }
}
