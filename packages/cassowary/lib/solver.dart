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

  Result removeContraint(Constraint c) {
    return Result.unimplemented;
  }

  Result hasConstraint(Constraint c) {
    return Result.unimplemented;
  }

  Result addEditVariable(Variable v, double priority) {
    return Result.unimplemented;
  }

  Result removeEditVariable(Variable v) {
    return Result.unimplemented;
  }

  Result hasEditVariable(Variable v) {
    return Result.unimplemented;
  }

  Result suggestVariable(Variable v, double value) {
    return Result.unimplemented;
  }

  void updateVariable() {}

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
}

class Tag {
  Symbol marker;
  Symbol other;

  Tag(this.marker, this.other);
}

class EditInfo {
  Tag tag;
  Constraint constraint;
  double constant;
}
