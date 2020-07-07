// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Semantics update', () async {
    final SemanticsUpdateTestBinding binding = SemanticsUpdateTestBinding();
    binding.pipelineOwner.ensureSemantics();
    await binding.runTest(() async {
      binding.attachRootWidget(
        MaterialApp(
          home: MergeSemantics(
            child: Semantics(
              value: 'test 1',
              textField: true,
              // This semantics b
              child: MergeSemantics(
                child: Semantics(
                  value: 'test 2',
                  textField: true,
                  child: const Text('test 3'),
                ),
              ),
            ),
          ),
        ),
      );
      SemanticsUpdateBuilderSpy.observations.clear();
      binding.scheduleFrame();
      await binding.pump(null, EnginePhase.sendSemanticsUpdate);

      // Checks all nodes are connected.
      // Starts with root node.
      int currentNode = 0;
      while(SemanticsUpdateBuilderSpy.observations.containsKey(currentNode)) {
        final SemanticsNodeUpdateObservation observation =  SemanticsUpdateBuilderSpy.observations.remove(currentNode)!;
        if (observation.childrenInTraversalOrder.isEmpty)
          break;
        expect(observation.childrenInTraversalOrder.length, 1);
        currentNode = observation.childrenInTraversalOrder[0];
      }
      // We should have looped through the all the observations.
      expect(SemanticsUpdateBuilderSpy.observations.isEmpty, isTrue);
    }, () { });

    SemanticsUpdateBuilderSpy.observations.clear();
  });

}

typedef UpdateSemantics = void Function(ui.SemanticsUpdate);

class SemanticsUpdateTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ui.SemanticsUpdateBuilder generateSemanticsUpdateBuilder() {
    return SemanticsUpdateBuilderSpy();
  }
}


class SemanticsUpdateBuilderSpy extends ui.SemanticsUpdateBuilder {
  static Map<int, SemanticsNodeUpdateObservation> observations = <int, SemanticsNodeUpdateObservation>{};

  @override
  void updateNode({
    required int id,
    required int flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required double elevation,
    required double thickness,
    required Rect rect,
    required String label,
    required String hint,
    required String value,
    required String increasedValue,
    required String decreasedValue,
    TextDirection? textDirection,
    required Float64List transform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
  }) {
    // Makes sure we don't send the same id twice.
    assert(!observations.containsKey(id));
    observations[id] = SemanticsNodeUpdateObservation(
      id: id,
      flags: flags,
      actions: actions,
      maxValueLength: maxValueLength,
      currentValueLength: currentValueLength,
      textSelectionBase: textSelectionBase,
      textSelectionExtent: textSelectionExtent,
      platformViewId: platformViewId,
      scrollChildren: scrollChildren,
      scrollIndex: scrollIndex,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
      elevation: elevation,
      thickness: thickness,
      rect: rect,
      label: label,
      hint: hint,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      textDirection: textDirection,
      transform: transform,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions: additionalActions,
    );
  }
}

class SemanticsNodeUpdateObservation {
  const SemanticsNodeUpdateObservation({
    required this.id,
    required this.flags,
    required this.actions,
    required this.maxValueLength,
    required this.currentValueLength,
    required this.textSelectionBase,
    required this.textSelectionExtent,
    required this.platformViewId,
    required this.scrollChildren,
    required this.scrollIndex,
    required this.scrollPosition,
    required this.scrollExtentMax,
    required this.scrollExtentMin,
    required this.elevation,
    required this.thickness,
    required this.rect,
    required this.label,
    required this.hint,
    required this.value,
    required this.increasedValue,
    required this.decreasedValue,
    this.textDirection,
    required this.transform,
    required this.childrenInTraversalOrder,
    required this.childrenInHitTestOrder,
    required this.additionalActions,
  });

  final int id;
  final int flags;
  final int actions;
  final int maxValueLength;
  final int currentValueLength;
  final int textSelectionBase;
  final int textSelectionExtent;
  final int platformViewId;
  final int scrollChildren;
  final int scrollIndex;
  final double scrollPosition;
  final double scrollExtentMax;
  final double scrollExtentMin;
  final double elevation;
  final double thickness;
  final Rect rect;
  final String label;
  final String hint;
  final String value;
  final String increasedValue;
  final String decreasedValue;
  final TextDirection? textDirection;
  final Float64List transform;
  final Int32List childrenInTraversalOrder;
  final Int32List childrenInHitTestOrder;
  final Int32List additionalActions;
}
