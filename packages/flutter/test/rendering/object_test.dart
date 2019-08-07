// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/src/binding.dart' show TestWidgetsFlutterBinding;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ensure frame is scheduled for markNeedsSemanticsUpdate', () {
    // Initialize all bindings because owner.flushSemantics() requires a window
    TestWidgetsFlutterBinding.ensureInitialized();

    final TestRenderObject renderObject = TestRenderObject();
    int onNeedVisualUpdateCallCount = 0;
    final PipelineOwner owner = PipelineOwner(onNeedVisualUpdate: () {
      onNeedVisualUpdateCallCount +=1;
    });
    owner.ensureSemantics();
    renderObject.attach(owner);
    renderObject.layout(const BoxConstraints.tightForFinite());  // semantics are only calculated if layout information is up to date.
    owner.flushSemantics();

    expect(onNeedVisualUpdateCallCount, 1);
    renderObject.markNeedsSemanticsUpdate();
    expect(onNeedVisualUpdateCallCount, 2);
  });

  test('detached RenderObject does not do semantics', () {
    final TestRenderObject renderObject = TestRenderObject();
    expect(renderObject.attached, isFalse);
    expect(renderObject.describeSemanticsConfigurationCallCount, 0);

    renderObject.markNeedsSemanticsUpdate();
    expect(renderObject.describeSemanticsConfigurationCallCount, 0);
  });

  test('ensure errors processing render objects are well formatted', () {
    FlutterErrorDetails errorDetails;
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails = details;
    };
    final PipelineOwner owner = PipelineOwner();
    final TestThrowingRenderObject renderObject = TestThrowingRenderObject();
    try {
      renderObject.attach(owner);
      renderObject.layout(const BoxConstraints());
    } finally {
      FlutterError.onError = oldHandler;
    }

    expect(errorDetails, isNotNull);
    expect(errorDetails.stack, isNotNull);
    // Check the ErrorDetails without the stack trace
    final List<String> lines =  errorDetails.toString().split('\n');
    // The lines in the middle of the error message contain the stack trace
    // which will change depending on where the test is run.
    expect(lines.length, greaterThan(8));
    expect(
      lines.take(4).join('\n'),
      equalsIgnoringHashCodes(
        '══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞══════════════════════\n'
        'The following assertion was thrown during performLayout():\n'
        'TestThrowingRenderObject does not support performLayout.\n'
      )
    );

    expect(
      lines.getRange(lines.length - 8, lines.length).join('\n'),
      equalsIgnoringHashCodes(
        '\n'
        'The following RenderObject was being processed when the exception was fired:\n'
        '  TestThrowingRenderObject#00000 NEEDS-PAINT:\n'
        '  parentData: MISSING\n'
        '  constraints: BoxConstraints(unconstrained)\n'
        'This RenderObject has no descendants.\n'
        '═════════════════════════════════════════════════════════════════\n'
      ),
    );
  });

  test('ContainerParentDataMixin requires nulled out pointers to siblings before detach', () {
    expect(() => TestParentData().detach(), isNot(throwsAssertionError));

    final TestParentData data1 = TestParentData()
      ..nextSibling = RenderOpacity()
      ..previousSibling = RenderOpacity();
    expect(() => data1.detach(), throwsAssertionError);

    final TestParentData data2 = TestParentData()
      ..previousSibling = RenderOpacity();
    expect(() => data2.detach(), throwsAssertionError);

    final TestParentData data3 = TestParentData()
      ..nextSibling = RenderOpacity();
    expect(() => data3.detach(), throwsAssertionError);
  });
}

class TestParentData extends ParentData with ContainerParentDataMixin<RenderBox> { }

class TestRenderObject extends RenderObject {
  @override
  void debugAssertDoesMeetConstraints() { }

  @override
  Rect get paintBounds => null;

  @override
  void performLayout() { }

  @override
  void performResize() { }

  @override
  Rect get semanticBounds => const Rect.fromLTWH(0.0, 0.0, 10.0, 20.0);

  int describeSemanticsConfigurationCallCount = 0;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    describeSemanticsConfigurationCallCount++;
  }
}

class TestThrowingRenderObject extends RenderObject {
  @override
  void performLayout() {
    throw FlutterError('TestThrowingRenderObject does not support performLayout.');
  }

  @override
  void debugAssertDoesMeetConstraints() { }

  @override
  Rect get paintBounds => null;

  @override
  void performResize() { }

  @override
  Rect get semanticBounds => null;
}
