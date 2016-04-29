// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sprites/flutter_sprites.dart';
import 'package:test/test.dart';

void main() {
  test("Node - adding and removing children", () {
    // Create root node.
    NodeWithSize rootNode = new NodeWithSize(const Size(1024.0, 1024.0));

    expect(rootNode.spriteBox, isNull);
    expect(rootNode.children.length, equals(0));

    // Create children.
    Node child0 = new Node();
    Node child1 = new Node();

    expect(child0.parent, isNull);
    expect(child1.parent, isNull);
    expect(child0.spriteBox, isNull);
    expect(child1.spriteBox, isNull);

    // Create sprite box.
    SpriteBox spriteBox = new SpriteBox(rootNode);
    expect(rootNode.spriteBox, equals(spriteBox));

    // Add children.
    rootNode.addChild(child0);
    rootNode.addChild(child1);

    expect(child0, isIn(rootNode.children));
    expect(child1, isIn(rootNode.children));
    expect(rootNode.children.length, equals(2));
    expect(child0.parent, equals(rootNode));
    expect(child1.parent, equals(rootNode));
    expect(child0.spriteBox, equals(spriteBox));
    expect(child1.spriteBox, equals(spriteBox));

    // Remove one of the children.
    rootNode.removeChild(child0);

    expect(child1, isIn(rootNode.children));
    expect(child1.parent, equals(rootNode));
    expect(rootNode.children.length, equals(1));
    expect(child0.parent, isNull);
    expect(child0.spriteBox, isNull);

    // Add a child back in.
    rootNode.addChild(child0);
    expect(child0, isIn(rootNode.children));
    expect(child1, isIn(rootNode.children));
    expect(rootNode.children.length, equals(2));
    expect(child0.parent, equals(rootNode));
    expect(child1.parent, equals(rootNode));
    expect(child0.spriteBox, equals(spriteBox));
    expect(child1.spriteBox, equals(spriteBox));

    // Remove all children.
    rootNode.removeAllChildren();
    expect(rootNode.children.length, equals(0));
    expect(child0.parent, isNull);
    expect(child1.parent, isNull);
    expect(child0.spriteBox, isNull);
    expect(child1.spriteBox, isNull);
  });

  testWidgets("Node - transformations", (WidgetTester tester) {
    const double epsilon = 0.01;

    NodeWithSize rootNode = new NodeWithSize(const Size(1024.0, 1024.0));
    tester.pumpWidget(new SpriteWidget(rootNode));

    // Translations and transformations adding up correctly.
    Node child0 = new Node();
    child0.position = const Point(100.0, 0.0);
    rootNode.addChild(child0);

    Node child1 = new Node();
    child1.position = const Point(200.0, 0.0);
    child0.addChild(child1);

    Point rootPoint = rootNode.convertPointFromNode(Point.origin, child1);
    expect(rootPoint.x, closeTo(300.0, epsilon));
    expect(rootPoint.y, closeTo(0.0, epsilon));

    // Rotations.
    Node rotatedChild = new Node();
    rotatedChild.rotation = 90.0;
    rootNode.addChild(rotatedChild);

    rootPoint = rootNode.convertPointFromNode(const Point(1.0, 0.0), rotatedChild);
    expect(rootPoint.x, closeTo(0.0, epsilon));
    expect(rootPoint.y, closeTo(1.0, epsilon));

    // Scale.
    Node scaledChild = new Node();
    scaledChild.scale = 2.0;
    rootNode.addChild(scaledChild);

    rootPoint = rootNode.convertPointFromNode(const Point(1.0, 1.0), scaledChild);
    expect(rootPoint.x, closeTo(2.0, epsilon));
    expect(rootPoint.y, closeTo(2.0, epsilon));

    // Scale x-axis only.
    Node scaledXChild = new Node();
    scaledXChild.scaleX = 2.0;
    rootNode.addChild(scaledXChild);

    rootPoint = rootNode.convertPointFromNode(const Point(1.0, 1.0), scaledXChild);
    expect(rootPoint.x, closeTo(2.0, epsilon));
    expect(rootPoint.y, closeTo(1.0, epsilon));

    // Scale y-axis only.
    Node scaledYChild = new Node();
    scaledYChild.scaleY = 2.0;
    rootNode.addChild(scaledYChild);

    rootPoint = rootNode.convertPointFromNode(const Point(1.0, 1.0), scaledYChild);
    expect(rootPoint.x, closeTo(1.0, epsilon));
    expect(rootPoint.y, closeTo(2.0, epsilon));

    // Skew x-axis.
    Node skewedXChild = new Node();
    skewedXChild.skewX = 45.0;
    rootNode.addChild(skewedXChild);

    rootPoint = rootNode.convertPointFromNode(const Point(1.0, 1.0), skewedXChild);
    expect(rootPoint.x, closeTo(1.0, epsilon));
    expect(rootPoint.y, closeTo(2.0, epsilon));

    // Skew y-axis.
    Node skewedYChild = new Node();
    skewedYChild.skewY = 45.0;
    rootNode.addChild(skewedYChild);

    rootPoint = rootNode.convertPointFromNode(const Point(1.0, 1.0), skewedYChild);
    expect(rootPoint.x, closeTo(2.0, epsilon));
    expect(rootPoint.y, closeTo(1.0, epsilon));
  });

  test("Node - zOrder", () {
    // Ensure zOrder takes president over order added.
    {
      Node rootNode = new Node();

      Node node0 = new Node();
      Node node1 = new Node();
      Node node2 = new Node()..zPosition = 1.0;
      Node node3 = new Node()..zPosition = 1.0;

      rootNode.addChild(node0);
      rootNode.addChild(node2);
      rootNode.addChild(node1);
      rootNode.addChild(node3);

      expect(rootNode.children[0], equals(node0));
      expect(rootNode.children[1], equals(node1));
      expect(rootNode.children[2], equals(node2));
      expect(rootNode.children[3], equals(node3));
    }

    // Test negative zOrder.
    {
      Node rootNode = new Node();

      Node node0 = new Node()..zPosition = -1.0;;
      Node node1 = new Node();
      Node node2 = new Node()..zPosition = 1.0;

      rootNode.addChild(node2);
      rootNode.addChild(node1);
      rootNode.addChild(node0);

      expect(rootNode.children[0], equals(node0));
      expect(rootNode.children[1], equals(node1));
      expect(rootNode.children[2], equals(node2));
    }
  });

  test("Node - isPointInside", () {
    Node node = new Node();

    expect(node.isPointInside(Point.origin), equals(false));

    NodeWithSize nodeWithSize = new NodeWithSize(const Size(10.0, 10.0));
    nodeWithSize.pivot = Point.origin;

    expect(nodeWithSize.isPointInside(const Point(1.0, 1.0)), isTrue);
    expect(nodeWithSize.isPointInside(const Point(9.0, 9.0)), isTrue);
    expect(nodeWithSize.isPointInside(const Point(11.0, 1.0)), isFalse);
    expect(nodeWithSize.isPointInside(const Point(-1.0, -1.0)), isFalse);

    nodeWithSize.pivot = const Point(0.5, 0.5);

    expect(nodeWithSize.isPointInside(const Point(1.0, 1.0)), isTrue);
    expect(nodeWithSize.isPointInside(const Point(9.0, 9.0)), isFalse);
    expect(nodeWithSize.isPointInside(const Point(11.0, 1.0)), isFalse);
    expect(nodeWithSize.isPointInside(const Point(-1.0, -1.0)), isTrue);
  });
}
