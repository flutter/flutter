// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'priority.dart';
import 'expression.dart';

enum Relation {
  equalTo,
  lessThanOrEqualTo,
  greaterThanOrEqualTo,
}

class Constraint {
  Constraint(this.expression, this.relation);

  final Relation relation;

  final Expression expression;

  double priority = Priority.required;

  Constraint operator |(double p) => this..priority = p;

  @override
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

    if (priority == Priority.required)
      buffer.write(' (required)');

    return buffer.toString();
  }
}
