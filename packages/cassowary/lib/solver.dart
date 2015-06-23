// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Solver {
  bool addConstraint(Constraint c) {
    return false;
  }

  bool removeContraint(Constraint c) {
    return false;
  }

  bool hasConstraint(Constraint c) {
    return false;
  }

  bool addEditVariable(Variable v, double priority) {
    return false;
  }

  bool removeEditVariable(Variable v) {
    return false;
  }

  bool hasEditVariable(Variable v) {
    return false;
  }

  bool suggestVariable(Variable v, double value) {
    return false;
  }

  void updateVariable() {}

  Solver operator <<(Constraint c) => this..addConstraint(c);
}
