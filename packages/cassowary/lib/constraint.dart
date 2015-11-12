// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

enum Relation { equalTo, lessThanOrEqualTo, greaterThanOrEqualTo, }

class Constraint {
  final Relation relation;
  final Expression expression;
  double priority = Priority.required;

  Constraint(this.expression, this.relation);

  Constraint operator |(double p) => this..priority = p;

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(expression.toString());

    switch (relation) {
      case Relation.equalTo:
        buffer.write(' == 0 ');
        break;
      case Relation.greaterThanOrEqualTo:
        buffer.write(' >= 0 ');
        break;
      case Relation.lessThanOrEqualTo:
        buffer.write(' <= 0 ');
        break;
    }

    buffer.write(' | priority = $priority');

    if (priority == Priority.required) {
      buffer.write(' (required)');
    }

    return buffer.toString();
  }
}
