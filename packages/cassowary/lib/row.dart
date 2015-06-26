// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class _Row {
  final Map<_Symbol, double> cells;
  double constant = 0.0;

  _Row(this.constant) : this.cells = new Map<_Symbol, double>();
  _Row.fromRow(_Row row)
      : this.cells = new Map<_Symbol, double>.from(row.cells),
        this.constant = row.constant;

  double add(double value) => constant += value;

  void insertSymbol(_Symbol symbol, [double coefficient = 1.0]) {
    double val = _elvis(cells[symbol], 0.0);

    if (_nearZero(val + coefficient)) {
      cells.remove(symbol);
    } else {
      cells[symbol] = val + coefficient;
    }
  }

  void insertRow(_Row other, [double coefficient = 1.0]) {
    constant += other.constant * coefficient;
    other.cells.forEach((s, v) => insertSymbol(s, v * coefficient));
  }

  void removeSymbol(_Symbol symbol) {
    cells.remove(symbol);
  }

  void reverseSign() {
    constant = -constant;
    cells.forEach((s, v) => cells[s] = -v);
  }

  void solveForSymbol(_Symbol symbol) {
    assert(cells.containsKey(symbol));
    double coefficient = -1.0 / cells[symbol];
    cells.remove(symbol);
    constant *= coefficient;
    cells.forEach((s, v) => cells[s] = v * coefficient);
  }

  void solveForSymbols(_Symbol lhs, _Symbol rhs) {
    insertSymbol(lhs, -1.0);
    solveForSymbol(rhs);
  }

  double coefficientForSymbol(_Symbol symbol) => _elvis(cells[symbol], 0.0);

  void substitute(_Symbol symbol, _Row row) {
    double coefficient = cells[symbol];

    if (coefficient == null) {
      return;
    }

    cells.remove(symbol);
    insertRow(row, coefficient);
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();

    buffer.write(constant);

    cells.forEach((symbol, value) =>
        buffer.write(" + " + value.toString() + " * " + symbol.toString()));

    return buffer.toString();
  }
}
