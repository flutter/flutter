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
  final Row _objective = new Row();
  final Row _artificial = new Row();

  Result addConstraint(Constraint c) {
    return Result.unimplemented;
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
