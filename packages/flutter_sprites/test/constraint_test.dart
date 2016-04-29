// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_sprites/flutter_sprites.dart';
import 'package:test/test.dart';

const double epsilon = 0.01;

void main() {
  test("Constraints - ConstraintPositionToNode", () {
    Node parent = new Node();

    Node node0 = new Node();
    Node node1 = new Node();

    parent.addChild(node0);
    parent.addChild(node1);

    node1.constraints = [(new ConstraintPositionToNode(node0))];

    node0.position = const Point(100.0, 50.0);
    node1.applyConstraints(0.1);

    expect(node1.position.x, closeTo(100.0, epsilon));
    expect(node1.position.y, closeTo(50.0, epsilon));
  });

  test("Constraints - ConstraintRotationToNode", () {
    Node parent = new Node();

    Node node0 = new Node();
    Node node1 = new Node()..position = const Point(0.0, 100.0);

    parent.addChild(node0);
    parent.addChild(node1);

    node1.constraints = [(new ConstraintRotationToNode(node0))];

    node1.applyConstraints(0.1);

    expect(node1.rotation, closeTo(-90.0, epsilon));
  });

  test("Constraints - ConstraintRotationToNodeRotation", () {
    Node parent = new Node();

    Node node0 = new Node();
    Node node1 = new Node();

    parent.addChild(node0);
    parent.addChild(node1);

    node1.constraints = [(new ConstraintRotationToNodeRotation(node0, baseRotation: 10.0))];

    node0.rotation = 90.0;
    node1.applyConstraints(0.1);

    expect(node1.rotation, closeTo(100.0, epsilon));
  });

  test("Constraints - ConstraintRotationToMovement", () {
    Node parent = new Node();

    Node node0 = new Node();

    parent.addChild(node0);

    Constraint constraint = new ConstraintRotationToMovement();
    node0.constraints = [constraint];

    node0.position = const Point(0.0, 0.0);
    constraint.preUpdate(node0, 0.1);

    node0.position = const Point(0.0, 100.0);
    node0.applyConstraints(0.1);

    expect(node0.rotation, closeTo(90.0, epsilon));
  });
}
