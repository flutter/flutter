// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/rendering.dart';
import '../../common/test_initialization.dart';
import 'semantics_tester.dart';

const String _rootStyle = 'style="filter: opacity(0%); color: rgba(0, 0, 0, 0)"';
DateTime _testTime = DateTime(2023, 2, 17);
EngineSemantics semantics() => EngineSemantics.instance;
EngineSemanticsOwner owner() => EnginePlatformDispatcher.instance.implicitView!.semantics;

void main() {
  internalBootstrapBrowserTest(() {
    return testMain;
  });
}

Future<void> testMain() async {
  await bootstrapAndRunApp(withImplicitView: true);
  setUpRenderingForTests();

  test('renders label text as DOM', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // Add a node with a label - expect a <span>
    {
      final SemanticsTester tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'Hello',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem role="text" $_rootStyle>Hello</sem>'''
      );

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      expect(node.primaryRole?.role, PrimaryRole.generic);
      expect(
        reason: 'A node with a label should get a LabelAndValue role',
        node.primaryRole!.debugSecondaryRoles,
        contains(Role.labelAndValue),
      );
    }

    // Change label - expect both <span> and aria-label to be updated.
    {
      final SemanticsTester tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'World',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem role="text" $_rootStyle>World</sem>'''
      );
    }

    // Empty the label - expect the <span> to be removed.
    {
      final SemanticsTester tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: '',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree(owner(), '<sem role="text" $_rootStyle></sem>');
    }

    semantics().semanticsEnabled = false;
  });

  test('does not add a span in container nodes', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final SemanticsTester tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      label: 'I am a parent',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          label: 'I am a child',
          transform: Matrix4.identity().toFloat64(),
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
      <sem aria-label="I am a parent" role="group" $_rootStyle>
        <sem-c>
          <sem role="text">I am a child</sem>
        </sem-c>
      </sem>'''
    );

    semantics().semanticsEnabled = false;
  });

  test('adds a span when a leaf becomes a parent, and vice versa', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // A leaf node with a label - expect <span>
    {
      final SemanticsTester tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'I am a leaf',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem role="text" $_rootStyle>I am a leaf</sem>'''
      );
    }

    // Add a child - expect <span> to be removed from the parent.
    {
      final SemanticsTester tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'I am a parent',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            label: 'I am a child',
            transform: Matrix4.identity().toFloat64(),
            rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          ),
        ],
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem aria-label="I am a parent" role="group" $_rootStyle>
          <sem-c>
            <sem role="text">I am a child</sem>
          </sem-c>
        </sem>'''
      );
    }

    // Remove the child - expect the <span> to be readded to the former parent.
    {
      final SemanticsTester tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'I am a leaf again',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem role="text" $_rootStyle>I am a leaf again</sem>'''
      );
    }

    semantics().semanticsEnabled = false;
  });
}
