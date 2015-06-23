// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

enum Relation { equalTo, lessThanOrEqualTo, greaterThanOrEqualTo, }

class Constraint {
  final Relation relation;
  final Expression expression;
  final bool required;

  static const double requiredPriority = 1000.0;
  double _priority = requiredPriority - 1.0;

  Constraint(this.expression, this.relation) : this.required = false;
  Constraint.Required(this.expression, this.relation) : this.required = true {
    this.priority = requiredPriority;
  }

  double get priority => required ? requiredPriority : _priority;
  set priority(double p) => _priority =
      required ? requiredPriority : p.clamp(0.0, requiredPriority - 1.0);

  Constraint operator |(double p) => this..priority = p;
}
