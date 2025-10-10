// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_update_tester.dart';

void main() {
  SemanticsUpdateTestBinding();

  testWidgets('Flush semantics synchronously', (WidgetTester tester) async {
    addTearDown(SemanticsUpdateBuilderSpy.observations.clear);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('appbar')),
          body: ElevatedButton(onPressed: () {}, child: const Text('button')),
        ),
      ),
    );

    expect(tester.binding.semanticsEnabled, isFalse);
    expect(SemanticsUpdateBuilderSpy.observations.length, 0);

    // EnsureSemantics should send update to engine synchronously.
    final SemanticsHandle handle = tester.binding.ensureSemantics();
    expect(SemanticsUpdateBuilderSpy.observations.length, 7);
    handle.dispose();
  }, semanticsEnabled: false);

  testWidgets('Flush semantics when tree is dirty', (WidgetTester tester) async {
    addTearDown(SemanticsUpdateBuilderSpy.observations.clear);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('appbar')),
          body: ElevatedButton(onPressed: () {}, child: const Text('button')),
        ),
      ),
    );

    RenderObject? root;
    void getRootNode(PipelineOwner child) {
      root ??= child.rootNode;
      if (root == null) {
        child.visitChildren(getRootNode);
      }
    }

    tester.binding.rootPipelineOwner.visitChildren(getRootNode);

    void markLayoutDirty(RenderObject object) {
      object.markNeedsLayout();
      object.visitChildren(markLayoutDirty);
    }

    root!.visitChildren(markLayoutDirty);
    expect(tester.binding.semanticsEnabled, isFalse);
    expect(SemanticsUpdateBuilderSpy.observations.length, 0);

    // EnsureSemantics should send update to engine synchronously.
    final SemanticsHandle handle = tester.binding.ensureSemantics();
    expect(SemanticsUpdateBuilderSpy.observations.length, 7);
    handle.dispose();
  }, semanticsEnabled: false);
}
