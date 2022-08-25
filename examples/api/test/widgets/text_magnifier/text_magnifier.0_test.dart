// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/widgets/text_magnifier/text_magnifier.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

List<TextSelectionPoint> _globalize(
    Iterable<TextSelectionPoint> points, RenderBox box) {
  return points.map<TextSelectionPoint>((TextSelectionPoint point) {
    return TextSelectionPoint(
      box.localToGlobal(point.point),
      point.direction,
    );
  }).toList();
}

RenderEditable _findRenderEditable<T extends State<StatefulWidget>>(
    GlobalKey<T> key) {
  final T state = key.currentState!;
  assert(state is TextSelectionGestureDetectorBuilderDelegate,
      'State of textFieldKey must conform to TextSelectionGestureDetectorBuilderDelegate');
  final EditableTextState editableTextState =
      (state as TextSelectionGestureDetectorBuilderDelegate)
          .editableTextKey
          .currentState!;
  return editableTextState.renderEditable;
}

Offset _textOffsetToPosition<T extends State<StatefulWidget>>(
  // The global key's state must refer to a TextSelectionGestureDetectorBuilderDelegate.
  GlobalKey<T> textFieldKey,
  int offset,
) {
  final RenderEditable renderEditable = _findRenderEditable(textFieldKey);

  final List<TextSelectionPoint> endpoints = renderEditable
      .getEndpointsForSelection(
        TextSelection.collapsed(offset: offset),
      )
      .map<TextSelectionPoint>((TextSelectionPoint point) => TextSelectionPoint(
            renderEditable.localToGlobal(point.point),
            point.direction,
          ))
      .toList();

  return endpoints[0].point + const Offset(0.0, -2.0);
}

void main() {
  testWidgets('should show custom magnifier on drag',
      (WidgetTester tester) async {
    const Duration durationBetweenActons = Duration(milliseconds: 20);

    await tester.pumpWidget(const example.MyApp());

    final TextField textField = tester.firstWidget(find.byType(TextField));
    final GlobalKey<State<StatefulWidget>> textFieldKey =
        textField.key! as GlobalKey<State<StatefulWidget>>;

    final Offset tapOffset = _textOffsetToPosition(
      textFieldKey,
      example.MyApp.textFieldText.indexOf('e'),
    );

    // Double tap 'Magnifier' word to show the selection handles.
    final TestGesture testGesture = await tester.startGesture(tapOffset);
    await tester.pump(durationBetweenActons);
    await testGesture.up();
    await tester.pump(durationBetweenActons);
    await testGesture.down(tapOffset);
    await tester.pump(durationBetweenActons);
    await testGesture.up();
    await tester.pumpAndSettle();

    final TextSelection selection = textField.controller!.selection;

    final RenderEditable renderEditable = _findRenderEditable(textFieldKey);
    final List<TextSelectionPoint> endpoints = _globalize(
      renderEditable.getEndpointsForSelection(selection),
      renderEditable,
    );

    final Offset handlePos = endpoints.last.point + const Offset(10.0, 10.0);

    final TestGesture gesture = await tester.startGesture(handlePos);

    await gesture.moveTo(_textOffsetToPosition(
      textFieldKey,
      example.MyApp.textFieldText.length - 2,
    ));
    await tester.pump();

    expect(find.byType(example.CustomMagnifier), findsOneWidget);

    await expectLater(
      find.byType(example.MyApp),
      matchesGoldenFile('text_magnifier.0_test.png'),
    );
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.android }));
}
