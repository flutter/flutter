// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Solver {
  final Map<Constraint, Tag> _constraints = new Map<Constraint, Tag>();
  final Map<Symbol, Row> _rows = new Map<Symbol, Row>();
  final Map<Variable, Symbol> _vars = new Map<Variable, Symbol>();
  final Map<Variable, EditInfo> _edits = new Map<Variable, EditInfo>();
  final List<Symbol> _infeasibleRows = new List<Symbol>();
  final Row _objective = new Row(0.0);
  Row _artificial = new Row(0.0);
  int tick = 0;

  Result addConstraint(Constraint constraint) {
    if (_constraints.containsKey(constraint)) {
      return Result.duplicateConstraint;
    }

    Tag tag = new Tag(
        new Symbol(SymbolType.invalid, 0), new Symbol(SymbolType.invalid, 0));

    Row row = _createRow(constraint, tag);

    Symbol subject = _chooseSubjectForRow(row, tag);

    if (subject.type == SymbolType.invalid && _allDummiesInRow(row)) {
      if (!_nearZero(row.constant)) {
        return Result.unsatisfiableConstraint;
      } else {
        subject = tag.marker;
      }
    }

    if (subject.type == SymbolType.invalid) {
      if (!_addWithArtificialVariableOnRow(row)) {
        return Result.unsatisfiableConstraint;
      }
    } else {
      row.solveForSymbol(subject);
      _substitute(subject, row);
      _rows[subject] = row;
    }

    _constraints[constraint] = tag;

    return _optimizeObjectiveRow(_objective);
  }

  Result removeConstraint(Constraint constraint) {
    Tag tag = _constraints[constraint];
    if (tag == null) {
      return Result.unknownConstraint;
    }

    tag = new Tag.fromTag(tag);
    _constraints.remove(constraint);

    _removeConstraintEffects(constraint, tag);

    Row row = _rows[tag.marker];
    if (row != null) {
      _rows.remove(tag.marker);
    } else {
      _Pair<Symbol, Row> rowPair =
          _getLeavingRowPairForMarkerSymbol(tag.marker);

      if (rowPair == null) {
        return Result.internalSolverError;
      }

      Symbol leaving = rowPair.first;
      row = rowPair.second;
      var removed = _rows.remove(rowPair.first);
      assert(removed != null);
      row.solveForSymbols(leaving, tag.marker);
      _substitute(tag.marker, row);
    }

    return _optimizeObjectiveRow(_objective);
  }

  bool hasConstraint(Constraint constraint) {
    return _constraints.containsKey(constraint);
  }

  Result addEditVariable(Variable variable, double priority) {
    if (_edits.containsKey(variable)) {
      return Result.duplicateEditVariable;
    }

    if (!_isValidNonRequiredPriority(priority)) {
      return Result.badRequiredStrength;
    }

    Constraint constraint = new Constraint(
        new Expression([new Term(variable, 1.0)], 0.0), Relation.equalTo);

    if (addConstraint(constraint) != Result.success) {
      return Result.internalSolverError;
    }

    EditInfo info = new EditInfo();
    info.tag = _constraints[constraint];
    info.constraint = constraint;
    info.constant = 0.0;

    _edits[variable] = info;

    return Result.success;
  }

  Result removeEditVariable(Variable variable) {
    EditInfo info = _edits[variable];
    if (info == null) {
      return Result.unknownEditVariable;
    }

    if (removeConstraint(info.constraint) != Result.success) {
      return Result.internalSolverError;
    }

    _edits.remove(variable);
    return Result.success;
  }

  bool hasEditVariable(Variable variable) {
    return _edits.containsKey(variable);
  }

  Result suggestValueForVariable(Variable variable, double value) {
    if (!_edits.containsKey(variable)) {
      return Result.unknownEditVariable;
    }

    _suggestValueForEditInfoWithoutDualOptimization(_edits[variable], value);

    return _dualOptimize();
  }

  void updateVariable() {
    for (Variable variable in _vars.keys) {
      Symbol symbol = _vars[variable];
      Row row = _rows[symbol];
      if (row == null) {
        variable.value = 0.0;
      } else {
        variable.value = row.constant;
      }
    }
  }

  Solver operator <<(Constraint c) => this..addConstraint(c);

  Symbol _getSymbolForVariable(Variable variable) {
    Symbol symbol = _vars[variable];

    if (symbol != null) {
      return symbol;
    }

    symbol = new Symbol(SymbolType.external, tick++);
    _vars[variable] = symbol;

    return symbol;
  }

  Row _createRow(Constraint constraint, Tag tag) {
    Expression expr = new Expression.fromExpression(constraint.expression);
    Row row = new Row(expr.constant);

    expr.terms.forEach((term) {
      if (!_nearZero(term.coefficient)) {
        Symbol symbol = _getSymbolForVariable(term.variable);

        Row foundRow = _rows[symbol];

        if (foundRow != null) {
          row.insertRow(foundRow, term.coefficient);
        } else {
          row.insertSymbol(symbol, term.coefficient);
        }
      }
    });

    switch (constraint.relation) {
      case Relation.lessThanOrEqualTo:
      case Relation.greaterThanOrEqualTo:
        {
          double coefficient =
              constraint.relation == Relation.lessThanOrEqualTo ? 1.0 : -1.0;

          Symbol slack = new Symbol(SymbolType.slack, tick++);
          tag.marker = slack;
          row.insertSymbol(slack, coefficient);

          if (!constraint.required) {
            Symbol error = new Symbol(SymbolType.error, tick++);
            tag.other = error;
            row.insertSymbol(error, -coefficient);
            _objective.insertSymbol(error, constraint.priority);
          }
        }
        break;
      case Relation.equalTo:
        if (!constraint.required) {
          Symbol errPlus = new Symbol(SymbolType.error, tick++);
          Symbol errMinus = new Symbol(SymbolType.error, tick++);
          tag.marker = errPlus;
          tag.other = errMinus;
          row.insertSymbol(errPlus, -1.0);
          row.insertSymbol(errMinus, 1.0);
          _objective.insertSymbol(errPlus, constraint.priority);
          _objective.insertSymbol(errMinus, constraint.priority);
        } else {
          Symbol dummy = new Symbol(SymbolType.dummy, tick++);
          tag.marker = dummy;
          row.insertSymbol(dummy);
        }
        break;
    }

    if (row.constant < 0.0) {
      row.reverseSign();
    }

    return row;
  }

  Symbol _chooseSubjectForRow(Row row, Tag tag) {
    for (Symbol symbol in row.cells.keys) {
      if (symbol.type == SymbolType.external) {
        return symbol;
      }
    }

    if (tag.marker.type == SymbolType.slack ||
        tag.marker.type == SymbolType.error) {
      if (row.coefficientForSymbol(tag.marker) < 0.0) {
        return tag.marker;
      }
    }

    if (tag.other.type == SymbolType.slack ||
        tag.other.type == SymbolType.error) {
      if (row.coefficientForSymbol(tag.other) < 0.0) {
        return tag.other;
      }
    }

    return new Symbol(SymbolType.invalid, 0);
  }

  bool _allDummiesInRow(Row row) {
    for (Symbol symbol in row.cells.keys) {
      if (symbol.type != SymbolType.dummy) {
        return false;
      }
    }
    return true;
  }

  bool _addWithArtificialVariableOnRow(Row row) {
    Symbol artificial = new Symbol(SymbolType.slack, tick++);
    _rows[artificial] = new Row.fromRow(row);
    _artificial = new Row.fromRow(row);

    Result result = _optimizeObjectiveRow(_artificial);

    if (result.error) {
      // FIXME(csg): Propagate this up!
      return false;
    }

    bool success = _nearZero(_artificial.constant);
    _artificial = new Row(0.0);

    Row foundRow = _rows[artificial];
    if (foundRow != null) {
      _rows.remove(artificial);
      if (foundRow.cells.isEmpty) {
        return success;
      }

      Symbol entering = _anyPivotableSymbol(foundRow);
      if (entering.type == SymbolType.invalid) {
        return false;
      }

      foundRow.solveForSymbols(artificial, entering);
      _substitute(entering, foundRow);
      _rows[entering] = foundRow;
    }

    for (Row row in _rows.values) {
      row.removeSymbol(artificial);
    }
    _objective.removeSymbol(artificial);
    return success;
  }

  Result _optimizeObjectiveRow(Row objective) {
    while (true) {
      Symbol entering = _getEnteringSymbolForObjectiveRow(objective);
      if (entering.type == SymbolType.invalid) {
        return Result.success;
      }

      _Pair<Symbol, Row> leavingPair =
          _getLeavingRowForEnteringSymbol(entering);

      if (leavingPair == null) {
        return Result.internalSolverError;
      }

      Symbol leaving = leavingPair.first;
      Row row = leavingPair.second;
      _rows.remove(leavingPair.first);
      row.solveForSymbols(leaving, entering);
      _substitute(entering, row);
      _rows[entering] = row;
    }
  }

  Symbol _getEnteringSymbolForObjectiveRow(Row objective) {
    Map<Symbol, double> cells = objective.cells;

    for (Symbol symbol in cells.keys) {
      if (symbol.type != SymbolType.dummy && cells[symbol] < 0.0) {
        return symbol;
      }
    }

    return new Symbol(SymbolType.invalid, 0);
  }

  _Pair<Symbol, Row> _getLeavingRowForEnteringSymbol(Symbol entering) {
    double ratio = double.MAX_FINITE;
    _Pair<Symbol, Row> result = new _Pair(null, null);

    _rows.forEach((symbol, row) {
      if (symbol.type != SymbolType.external) {
        double temp = row.coefficientForSymbol(entering);

        if (temp < 0.0) {
          double temp_ratio = -row.constant / temp;

          if (temp_ratio < ratio) {
            ratio = temp_ratio;
            result.first = symbol;
            result.second = row;
          }
        }
      }
    });

    if (result.first == null || result.second == null) {
      return null;
    }

    return result;
  }

  void _substitute(Symbol symbol, Row row) {
    _rows.forEach((first, second) {
      second.substitute(symbol, row);
      if (first.type != SymbolType.external && second.constant < 0.0) {
        _infeasibleRows.add(first);
      }
    });

    _objective.substitute(symbol, row);
    if (_artificial != null) {
      _artificial.substitute(symbol, row);
    }
  }

  Symbol _anyPivotableSymbol(Row row) {
    for (Symbol symbol in row.cells.keys) {
      if (symbol.type == SymbolType.slack || symbol.type == SymbolType.error) {
        return symbol;
      }
    }
    return new Symbol(SymbolType.invalid, 0);
  }

  void _removeConstraintEffects(Constraint cn, Tag tag) {
    if (tag.marker.type == SymbolType.error) {
      _removeMarkerEffects(tag.marker, cn.priority);
    }
    if (tag.other.type == SymbolType.error) {
      _removeMarkerEffects(tag.other, cn.priority);
    }
  }

  void _removeMarkerEffects(Symbol marker, double strength) {
    Row row = _rows[marker];
    if (row != null) {
      _objective.insertRow(row, -strength);
    } else {
      _objective.insertSymbol(marker, -strength);
    }
  }

  _Pair<Symbol, Row> _getLeavingRowPairForMarkerSymbol(Symbol marker) {
    double r1 = double.MAX_FINITE;
    double r2 = double.MAX_FINITE;

    _Pair<Symbol, Row> first, second, third;

    _rows.forEach((symbol, row) {
      double c = row.coefficientForSymbol(marker);

      if (c == 0.0) {
        return;
      }

      if (symbol.type == SymbolType.external) {
        third = new _Pair(symbol, row);
      } else if (c < 0.0) {
        double r = -row.constant / c;
        if (r < r1) {
          r1 = r;
          first = new _Pair(symbol, row);
        }
      } else {
        double r = row.constant / c;
        if (r < r2) {
          r2 = r;
          second = new _Pair(symbol, row);
        }
      }
    });

    if (first != null) {
      return first;
    }
    if (second != null) {
      return second;
    }
    return third;
  }

  void _suggestValueForEditInfoWithoutDualOptimization(
      EditInfo info, double value) {
    double delta = value - info.constant;
    info.constant = value;

    {
      Symbol symbol = info.tag.marker;
      Row row = _rows[info.tag.marker];

      if (row != null) {
        if (row.add(-delta) < 0.0) {
          _infeasibleRows.add(symbol);
        }
        return;
      }

      symbol = info.tag.other;
      row = _rows[info.tag.other];

      if (row != null) {
        if (row.add(delta) < 0.0) {
          _infeasibleRows.add(symbol);
        }
        return;
      }
    }

    for (Symbol symbol in _rows.keys) {
      Row row = _rows[symbol];
      double coeff = row.coefficientForSymbol(info.tag.marker);
      if (coeff != 0.0 &&
          row.add(delta * coeff) < 0.0 &&
          symbol.type != SymbolType.external) {
        _infeasibleRows.add(symbol);
      }
    }
  }

  Result _dualOptimize() {
    while (_infeasibleRows.length != 0) {
      Symbol leaving = _infeasibleRows.removeLast();
      Row row = _rows[leaving];

      if (row != null && row.constant < 0.0) {
        Symbol entering = _getDualEnteringSymbolForRow(row);

        if (entering.type == SymbolType.invalid) {
          return Result.internalSolverError;
        }

        _rows.remove(leaving);

        row.solveForSymbols(leaving, entering);
        _substitute(entering, row);
        _rows[entering] = row;
      }
    }
    return Result.success;
  }

  Symbol _getDualEnteringSymbolForRow(Row row) {
    Symbol entering;

    double ratio = double.MAX_FINITE;

    Map<Symbol, double> rowCells = row.cells;

    for (Symbol symbol in rowCells.keys) {
      double value = rowCells[symbol];

      if (value > 0.0 && symbol.type != SymbolType.dummy) {
        double coeff = _objective.coefficientForSymbol(symbol);
        double r = coeff / value;
        if (r < ratio) {
          ratio = r;
          entering = symbol;
        }
      }
    }

    return _elvis(entering, new Symbol(SymbolType.invalid, 0));
  }
}

class Tag {
  Symbol marker;
  Symbol other;

  Tag(this.marker, this.other);
  Tag.fromTag(Tag tag)
      : this.marker = tag.marker,
        this.other = tag.other;
}

class EditInfo {
  Tag tag;
  Constraint constraint;
  double constant;
}

bool _isValidNonRequiredPriority(double priority) {
  return (priority >= 0.0 && priority < Constraint.requiredPriority);
}
