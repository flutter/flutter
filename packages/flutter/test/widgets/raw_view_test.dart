// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RawView.builder rebuilds on dependency changes', (WidgetTester tester) async {
    final List<String> texts = <String>[];
    final Widget child = RawView(
      view: tester.view,
      builder: (BuildContext context, PipelineOwner owner) {
        texts.add(InheritedText.of(context));
        return const SizedBox();
      },
    );


    await pumpWidgetWithoutViewWrapper(
        tester: tester,
        widget: InheritedText(
          text: 'Hello',
          child: child,
        ),
    );
    expect(texts.single, 'Hello');
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: InheritedText(
        text: 'Hello',
        child: child,
      ),
    );
    expect(texts.single, 'Hello');

    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: InheritedText(
        text: 'World',
        child: child,
      ),
    );
    expect(texts, hasLength(2));
    expect(texts.last, 'World');
  });
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}


class InheritedText extends InheritedWidget {
  const InheritedText({
    super.key,
    required this.text,
    required super.child,
  });

  final String text;

  static String of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedText>()!.text;
  }

  @override
  bool updateShouldNotify(InheritedText oldWidget) => text != oldWidget.text;
}
