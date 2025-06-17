// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

class SemanticsUpdateTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() {
    return SemanticsUpdateBuilderSpy();
  }
}

class SemanticsUpdateBuilderSpy extends Fake implements ui.SemanticsUpdateBuilder {
  final SemanticsUpdateBuilder _builder = ui.SemanticsUpdateBuilder();

  static Map<int, SemanticsNodeUpdateObservation> observations =
      <int, SemanticsNodeUpdateObservation>{};

  @override
  void updateNode({
    required int id,
    required SemanticsFlags flags,
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
    required Rect rect,
    required String identifier,
    required String label,
    List<StringAttribute>? labelAttributes,
    required String value,
    List<StringAttribute>? valueAttributes,
    required String increasedValue,
    List<StringAttribute>? increasedValueAttributes,
    required String decreasedValue,
    List<StringAttribute>? decreasedValueAttributes,
    required String hint,
    List<StringAttribute>? hintAttributes,
    String? tooltip,
    TextDirection? textDirection,
    required Float64List transform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
    int headingLevel = 0,
    String? linkUrl,
    SemanticsRole role = SemanticsRole.none,
    required List<String>? controlsNodes,
    SemanticsValidationResult validationResult = SemanticsValidationResult.none,
    required ui.SemanticsInputType inputType,
    required ui.Locale? locale,
  }) {
    // Makes sure we don't send the same id twice.
    assert(!observations.containsKey(id));
    observations[id] = SemanticsNodeUpdateObservation(
      label: label,
      labelAttributes: labelAttributes,
      hint: hint,
      hintAttributes: hintAttributes,
      value: value,
      valueAttributes: valueAttributes,
      childrenInTraversalOrder: childrenInTraversalOrder,
    );
  }

  @override
  void updateCustomAction({required int id, String? label, String? hint, int overrideId = -1}) =>
      _builder.updateCustomAction(id: id, label: label, hint: hint, overrideId: overrideId);

  @override
  ui.SemanticsUpdate build() => _builder.build();
}

class SemanticsNodeUpdateObservation {
  const SemanticsNodeUpdateObservation({
    required this.label,
    this.labelAttributes,
    required this.value,
    this.valueAttributes,
    required this.hint,
    this.hintAttributes,
    required this.childrenInTraversalOrder,
  });

  final String label;
  final List<StringAttribute>? labelAttributes;
  final String value;
  final List<StringAttribute>? valueAttributes;
  final String hint;
  final List<StringAttribute>? hintAttributes;
  final Int32List childrenInTraversalOrder;
}
