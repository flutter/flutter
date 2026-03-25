// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlutterErrorDetails.element is populated when a StatelessWidget throws in build', (WidgetTester tester) async {
    Element? capturedElement;
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      capturedElement = details.element;
    };

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ThrowingStatelessWidget(),
      ),
    );

    expect(capturedElement, isA<StatelessElement>());
    expect(capturedElement!.widget, isA<ThrowingStatelessWidget>());

    FlutterError.onError = oldOnError;
  });

  testWidgets('FlutterErrorDetails.element is populated when a StatefulWidget throws in build', (WidgetTester tester) async {
    Element? capturedElement;
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      capturedElement = details.element;
    };

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ThrowingStatefulWidget(),
      ),
    );

    expect(capturedElement, isA<StatefulElement>());
    expect(capturedElement!.widget, isA<ThrowingStatefulWidget>());

    FlutterError.onError = oldOnError;
  });

  testWidgets('FlutterErrorDetails.element is populated when LayoutBuilder.builder throws', (WidgetTester tester) async {
    Element? capturedElement;
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      capturedElement = details.element;
    };

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            throw UnsupportedError('LayoutBuilder error');
          },
        ),
      ),
    );

    expect(capturedElement, isNotNull);
    // LayoutBuilder uses a private _LayoutBuilderElement
    expect(capturedElement!.widget, isA<LayoutBuilder>());

    FlutterError.onError = oldOnError;
  });

  testWidgets('FlutterErrorDetails.renderObject is populated when RenderObject.paint throws', (WidgetTester tester) async {
    RenderObject? capturedRenderObject;
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      capturedRenderObject = details.renderObject;
    };

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ThrowingRenderObjectWidget(),
      ),
    );

    // Initial pump might not trigger paint if it's not needed, but here it should.
    // Wait, paint happens during the frame.
    
    expect(capturedRenderObject, isA<ThrowingRenderObject>());

    FlutterError.onError = oldOnError;
  });
}

class ThrowingStatelessWidget extends StatelessWidget {
  const ThrowingStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    throw UnsupportedError('Stateless build error');
  }
}

class ThrowingStatefulWidget extends StatefulWidget {
  const ThrowingStatefulWidget({super.key});

  @override
  State<ThrowingStatefulWidget> createState() => _ThrowingStatefulWidgetState();
}

class _ThrowingStatefulWidgetState extends State<ThrowingStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    throw UnsupportedError('Stateful build error');
  }
}

class ThrowingRenderObjectWidget extends LeafRenderObjectWidget {
  const ThrowingRenderObjectWidget({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => ThrowingRenderObject();
}

class ThrowingRenderObject extends RenderBox {
  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    throw UnsupportedError('RenderObject paint error');
  }
}
