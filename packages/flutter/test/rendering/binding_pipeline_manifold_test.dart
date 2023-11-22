// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  MyTestRenderingFlutterBinding.ensureInitialized();

  tearDown(() {
    final List<PipelineOwner> children = <PipelineOwner>[];
<<<<<<< HEAD
    RendererBinding.instance.pipelineOwner.visitChildren((PipelineOwner child) {
      children.add(child);
    });
    children.forEach(RendererBinding.instance.pipelineOwner.dropChild);
=======
    RendererBinding.instance.rootPipelineOwner.visitChildren((PipelineOwner child) {
      children.add(child);
    });
    children.forEach(RendererBinding.instance.rootPipelineOwner.dropChild);
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
  });

  test("BindingPipelineManifold notifies binding if render object managed by binding's PipelineOwner tree needs visual update", () {
    final PipelineOwner child = PipelineOwner();
<<<<<<< HEAD
    RendererBinding.instance.pipelineOwner.adoptChild(child);
=======
    RendererBinding.instance.rootPipelineOwner.adoptChild(child);
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a

    final RenderObject renderObject = TestRenderObject();
    child.rootNode = renderObject;
    renderObject.scheduleInitialLayout();
<<<<<<< HEAD
    RendererBinding.instance.pipelineOwner.flushLayout();
=======
    RendererBinding.instance.rootPipelineOwner.flushLayout();
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a

    MyTestRenderingFlutterBinding.instance.ensureVisualUpdateCount = 0;
    renderObject.markNeedsLayout();
    expect(MyTestRenderingFlutterBinding.instance.ensureVisualUpdateCount, 1);
  });

  test('Turning global semantics on/off creates semantics owners in PipelineOwner tree', () {
    final PipelineOwner child = PipelineOwner(
      onSemanticsUpdate: (_) { },
    );
<<<<<<< HEAD
    RendererBinding.instance.pipelineOwner.adoptChild(child);

    expect(child.semanticsOwner, isNull);
    expect(RendererBinding.instance.pipelineOwner.semanticsOwner, isNull);
=======
    RendererBinding.instance.rootPipelineOwner.adoptChild(child);

    expect(child.semanticsOwner, isNull);
    expect(RendererBinding.instance.rootPipelineOwner.semanticsOwner, isNull);
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a

    final SemanticsHandle handle = SemanticsBinding.instance.ensureSemantics();

    expect(child.semanticsOwner, isNotNull);
<<<<<<< HEAD
    expect(RendererBinding.instance.pipelineOwner.semanticsOwner, isNotNull);
=======
    expect(RendererBinding.instance.rootPipelineOwner.semanticsOwner, isNotNull);
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a

    handle.dispose();

    expect(child.semanticsOwner, isNull);
<<<<<<< HEAD
    expect(RendererBinding.instance.pipelineOwner.semanticsOwner, isNull);
=======
    expect(RendererBinding.instance.rootPipelineOwner.semanticsOwner, isNull);
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
  });
}

class MyTestRenderingFlutterBinding extends TestRenderingFlutterBinding {
  static MyTestRenderingFlutterBinding get instance => BindingBase.checkInstance(_instance);
  static MyTestRenderingFlutterBinding? _instance;

  static MyTestRenderingFlutterBinding ensureInitialized() {
    if (_instance != null) {
      return _instance!;
    }
    return MyTestRenderingFlutterBinding();
  }

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  int ensureVisualUpdateCount = 0;

  @override
  void ensureVisualUpdate() {
    super.ensureVisualUpdate();
    ensureVisualUpdateCount++;
  }
}

class TestRenderObject extends RenderObject {
  @override
  void debugAssertDoesMeetConstraints() { }

  @override
  Rect get paintBounds => Rect.zero;

  @override
  void performLayout() { }

  @override
  void performResize() { }

  @override
  Rect get semanticBounds => Rect.zero;
}
