// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Solver {
  final Map<Constraint, _Tag> _constraints = new Map<Constraint, _Tag>();
  final Map<_Symbol, _Row> _rows = new Map<_Symbol, _Row>();
  final Map<Variable, _Symbol> _vars = new Map<Variable, _Symbol>();
  final Map<Variable, _EditInfo> _edits = new Map<Variable, _EditInfo>();
  final List<_Symbol> _infeasibleRows = new List<_Symbol>();
  final _Row _objective = new _Row(0.0);
  _Row _artificial = new _Row(0.0);
  int tick = 1;

  /// Attempts to add the constraints in the list to the solver. If it cannot
  /// add any for some reason, a cleanup is attempted so that either all
  /// constraints will be added or none.
  Result addConstraints(List<Constraint> constraints) {
    _SolverBulkUpdate applier = (Constraint c) => addConstraint(c);
    _SolverBulkUpdate undoer = (Constraint c) => removeConstraint(c);

    return _bulkEdit(constraints, applier, undoer);
  }

  Result addConstraint(Constraint constraint) {
    if (_constraints.containsKey(constraint)) {
      return Result.duplicateConstraint;
    }

    _Tag tag = new _Tag(new _Symbol(_SymbolType.invalid, 0),
        new _Symbol(_SymbolType.invalid, 0));

    _Row row = _createRow(constraint, tag);

    _Symbol subject = _chooseSubjectForRow(row, tag);

    if (subject.type == _SymbolType.invalid && _allDummiesInRow(row)) {
      if (!_nearZero(row.constant)) {
        return Result.unsatisfiableConstraint;
      } else {
        subject = tag.marker;
      }
    }

    if (subject.type == _SymbolType.invalid) {
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

  Result removeConstraints(List<Constraint> constraints) {
    _SolverBulkUpdate applier = (Constraint c) => removeConstraint(c);
    _SolverBulkUpdate undoer = (Constraint c) => addConstraint(c);

    return _bulkEdit(constraints, applier, undoer);
  }

  Result removeConstraint(Constraint constraint) {
    _Tag tag = _constraints[constraint];
    if (tag == null) {
      return Result.unknownConstraint;
    }

    tag = new _Tag.fromTag(tag);
    _constraints.remove(constraint);

    _removeConstraintEffects(constraint, tag);

    _Row row = _rows[tag.marker];
    if (row != null) {
      _rows.remove(tag.marker);
    } else {
      _Pair<_Symbol, _Row> rowPair = _leavingRowPairForMarkerSymbol(tag.marker);

      if (rowPair == null) {
        return Result.internalSolverError;
      }

      _Symbol leaving = rowPair.first;
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

  Result addEditVariables(List<Variable> variables, double priority) {
    _SolverBulkUpdate applier = (Variable v) => addEditVariable(v, priority);
    _SolverBulkUpdate undoer = (Variable v) => removeEditVariable(v);

    return _bulkEdit(variables, applier, undoer);
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
    constraint.priority = priority;

    if (addConstraint(constraint) != Result.success) {
      return Result.internalSolverError;
    }

    _EditInfo info = new _EditInfo();
    info.tag = _constraints[constraint];
    info.constraint = constraint;
    info.constant = 0.0;

    _edits[variable] = info;

    return Result.success;
  }

  Result removeEditVariables(List<Variable> variables) {
    _SolverBulkUpdate applier = (Variable v) => removeEditVariable(v);
    _SolverBulkUpdate undoer = (Variable v) =>
        addEditVariable(v, _edits[v].constraint.priority);

    return _bulkEdit(variables, applier, undoer);
  }

  Result removeEditVariable(Variable variable) {
    _EditInfo info = _edits[variable];
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

  Set flushUpdates() {
    Set updates = new Set();

    for (Variable variable in _vars.keys) {
      _Symbol symbol = _vars[variable];
      _Row row = _rows[symbol];

      double updatedValue = row == null ? 0.0 : row.constant;

      if (variable._applyUpdate(updatedValue) && variable._owner != null) {
        dynamic context = variable._owner.context;

        if (context != null) {
          updates.add(context);
        }
      }
    }

    return updates;
  }

  Result _bulkEdit(Iterable items,
                   _SolverBulkUpdate applier,
                   _SolverBulkUpdate undoer) {
    List applied = new List();
    bool needsCleanup = false;

    Result result = Result.success;

    for (dynamic item in items) {
      result = applier(item);
      if (result == Result.success) {
        applied.add(item);
      } else {
        needsCleanup = true;
        break;
      }
    }

    if (needsCleanup) {
      for (dynamic item in applied.reversed) {
        undoer(item);
      }
    }

    return result;
  }

  _Symbol _symbolForVariable(Variable variable) {
    _Symbol symbol = _vars[variable];

    if (symbol != null) {
      return symbol;
    }

    symbol = new _Symbol(_SymbolType.external, tick++);
    _vars[variable] = symbol;

    return symbol;
  }

  _Row _createRow(Constraint constraint, _Tag tag) {
    Expression expr = new Expression.fromExpression(constraint.expression);
    _Row row = new _Row(expr.constant);

    expr.terms.forEach((term) {
      if (!_nearZero(term.coefficient)) {
        _Symbol symbol = _symbolForVariable(term.variable);

        _Row foundRow = _rows[symbol];

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

          _Symbol slack = new _Symbol(_SymbolType.slack, tick++);
          tag.marker = slack;
          row.insertSymbol(slack, coefficient);

          if (constraint.priority < Priority.required) {
            _Symbol error = new _Symbol(_SymbolType.error, tick++);
            tag.other = error;
            row.insertSymbol(error, -coefficient);
            _objective.insertSymbol(error, constraint.priority);
          }
        }
        break;
      case Relation.equalTo:
        if (constraint.priority < Priority.required) {
          _Symbol errPlus = new _Symbol(_SymbolType.error, tick++);
          _Symbol errMinus = new _Symbol(_SymbolType.error, tick++);
          tag.marker = errPlus;
          tag.other = errMinus;
          row.insertSymbol(errPlus, -1.0);
          row.insertSymbol(errMinus, 1.0);
          _objective.insertSymbol(errPlus, constraint.priority);
          _objective.insertSymbol(errMinus, constraint.priority);
        } else {
          _Symbol dummy = new _Symbol(_SymbolType.dummy, tick++);
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

  _Symbol _chooseSubjectForRow(_Row row, _Tag tag) {
    for (_Symbol symbol in row.cells.keys) {
      if (symbol.type == _SymbolType.external) {
        return symbol;
      }
    }

    if (tag.marker.type == _SymbolType.slack ||
        tag.marker.type == _SymbolType.error) {
      if (row.coefficientForSymbol(tag.marker) < 0.0) {
        return tag.marker;
      }
    }

    if (tag.other.type == _SymbolType.slack ||
        tag.other.type == _SymbolType.error) {
      if (row.coefficientForSymbol(tag.other) < 0.0) {
        return tag.other;
      }
    }

    return new _Symbol(_SymbolType.invalid, 0);
  }

  bool _allDummiesInRow(_Row row) {
    for (_Symbol symbol in row.cells.keys) {
      if (symbol.type != _SymbolType.dummy) {
        return false;
      }
    }
    return true;
  }

  bool _addWithArtificialVariableOnRow(_Row row) {
    _Symbol artificial = new _Symbol(_SymbolType.slack, tick++);
    _rows[artificial] = new _Row.fromRow(row);
    _artificial = new _Row.fromRow(row);

    Result result = _optimizeObjectiveRow(_artificial);

    if (result.error) {
      // FIXME(csg): Propagate this up!
      return false;
    }

    bool success = _nearZero(_artificial.constant);
    _artificial = new _Row(0.0);

    _Row foundRow = _rows[artificial];
    if (foundRow != null) {
      _rows.remove(artificial);
      if (foundRow.cells.isEmpty) {
        return success;
      }

      _Symbol entering = _anyPivotableSymbol(foundRow);
      if (entering.type == _SymbolType.invalid) {
        return false;
      }

      foundRow.solveForSymbols(artificial, entering);
      _substitute(entering, foundRow);
      _rows[entering] = foundRow;
    }

    for (_Row row in _rows.values) {
      row.removeSymbol(artificial);
    }
    _objective.removeSymbol(artificial);
    return success;
  }

  Result _optimizeObjectiveRow(_Row objective) {
    while (true) {
      _Symbol entering = _enteringSymbolForObjectiveRow(objective);
      if (entering.type == _SymbolType.invalid) {
        return Result.success;
      }

      _Pair<_Symbol, _Row> leavingPair = _leavingRowForEnteringSymbol(entering);

      if (leavingPair == null) {
        return Result.internalSolverError;
      }

      _Symbol leaving = leavingPair.first;
      _Row row = leavingPair.second;
      _rows.remove(leavingPair.first);
      row.solveForSymbols(leaving, entering);
      _substitute(entering, row);
      _rows[entering] = row;
    }
  }

  _Symbol _enteringSymbolForObjectiveRow(_Row objective) {
    Map<_Symbol, double> cells = objective.cells;

    for (_Symbol symbol in cells.keys) {
      if (symbol.type != _SymbolType.dummy && cells[symbol] < 0.0) {
        return symbol;
      }
    }

    return new _Symbol(_SymbolType.invalid, 0);
  }

  _Pair<_Symbol, _Row> _leavingRowForEnteringSymbol(_Symbol entering) {
    double ratio = double.MAX_FINITE;
    _Pair<_Symbol, _Row> result = new _Pair(null, null);

    _rows.forEach((symbol, row) {
      if (symbol.type != _SymbolType.external) {
        double temp = row.coefficientForSymbol(entering);

        if (temp < 0.0) {
          double tempRatio = -row.constant / temp;

          if (tempRatio < ratio) {
            ratio = tempRatio;
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

  void _substitute(_Symbol symbol, _Row row) {
    _rows.forEach((first, second) {
      second.substitute(symbol, row);
      if (first.type != _SymbolType.external && second.constant < 0.0) {
        _infeasibleRows.add(first);
      }
    });

    _objective.substitute(symbol, row);
    if (_artificial != null) {
      _artificial.substitute(symbol, row);
    }
  }

  _Symbol _anyPivotableSymbol(_Row row) {
    for (_Symbol symbol in row.cells.keys) {
      if (symbol.type == _SymbolType.slack ||
          symbol.type == _SymbolType.error) {
        return symbol;
      }
    }
    return new _Symbol(_SymbolType.invalid, 0);
  }

  void _removeConstraintEffects(Constraint cn, _Tag tag) {
    if (tag.marker.type == _SymbolType.error) {
      _removeMarkerEffects(tag.marker, cn.priority);
    }
    if (tag.other.type == _SymbolType.error) {
      _removeMarkerEffects(tag.other, cn.priority);
    }
  }

  void _removeMarkerEffects(_Symbol marker, double strength) {
    _Row row = _rows[marker];
    if (row != null) {
      _objective.insertRow(row, -strength);
    } else {
      _objective.insertSymbol(marker, -strength);
    }
  }

  _Pair<_Symbol, _Row> _leavingRowPairForMarkerSymbol(_Symbol marker) {
    double r1 = double.MAX_FINITE;
    double r2 = double.MAX_FINITE;

    _Pair<_Symbol, _Row> first, second, third;

    _rows.forEach((symbol, row) {
      double c = row.coefficientForSymbol(marker);

      if (c == 0.0) {
        return;
      }

      if (symbol.type == _SymbolType.external) {
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
      _EditInfo info, double value) {
    double delta = value - info.constant;
    info.constant = value;

    {
      _Symbol symbol = info.tag.marker;
      _Row row = _rows[info.tag.marker];

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

    for (_Symbol symbol in _rows.keys) {
      _Row row = _rows[symbol];
      double coeff = row.coefficientForSymbol(info.tag.marker);
      if (coeff != 0.0 &&
          row.add(delta * coeff) < 0.0 &&
          symbol.type != _SymbolType.external) {
        _infeasibleRows.add(symbol);
      }
    }
  }

  Result _dualOptimize() {
    while (_infeasibleRows.length != 0) {
      _Symbol leaving = _infeasibleRows.removeLast();
      _Row row = _rows[leaving];

      if (row != null && row.constant < 0.0) {
        _Symbol entering = _dualEnteringSymbolForRow(row);

        if (entering.type == _SymbolType.invalid) {
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

  _Symbol _dualEnteringSymbolForRow(_Row row) {
    _Symbol entering;

    double ratio = double.MAX_FINITE;

    Map<_Symbol, double> rowCells = row.cells;

    for (_Symbol symbol in rowCells.keys) {
      double value = rowCells[symbol];

      if (value > 0.0 && symbol.type != _SymbolType.dummy) {
        double coeff = _objective.coefficientForSymbol(symbol);
        double r = coeff / value;
        if (r < ratio) {
          ratio = r;
          entering = symbol;
        }
      }
    }

    return _elvis(entering, new _Symbol(_SymbolType.invalid, 0));
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    String separator = "\n~~~~~~~~~";

    // Objective
    buffer.writeln(separator + " Objective");
    buffer.writeln(_objective.toString());

    // Tableau
    buffer.writeln(separator + " Tableau");
    _rows.forEach((symbol, row) {
      buffer.write(symbol.toString());
      buffer.write(" | ");
      buffer.writeln(row.toString());
    });

    // Infeasible
    buffer.writeln(separator + " Infeasible");
    _infeasibleRows.forEach((symbol) => buffer.writeln(symbol.toString()));

    // Variables
    buffer.writeln(separator + " Variables");
    _vars.forEach((variable, symbol) =>
        buffer.writeln("${variable.toString()} = ${symbol.toString()}"));

    // Edit Variables
    buffer.writeln(separator + " Edit Variables");
    _edits.forEach((variable, editinfo) => buffer.writeln(variable));

    // Constraints
    buffer.writeln(separator + " Constraints");
    _constraints.forEach((constraint, _) => buffer.writeln(constraint));

    return buffer.toString();
  }
}

class _Tag {
  _Symbol marker;
  _Symbol other;

  _Tag(this.marker, this.other);
  _Tag.fromTag(_Tag tag)
      : this.marker = tag.marker,
        this.other = tag.other;
}

class _EditInfo {
  _Tag tag;
  Constraint constraint;
  double constant;
}

bool _isValidNonRequiredPriority(double priority) {
  return (priority >= 0.0 && priority < Priority.required);
}

typedef Result _SolverBulkUpdate(dynamic item);
