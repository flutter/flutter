// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  final html.Element rootNode = html.document.createElement('div');
  html.document.body!.append(rootNode);

  group('ShadowDomHostNode', () {
    final HostNode hostNode = ShadowDomHostNode(rootNode);

    test('Initializes and attaches a shadow root', () {
      expect(hostNode.node, isA<html.ShadowRoot>());
      expect((hostNode.node as html.ShadowRoot).host, rootNode);
      expect(hostNode.node, rootNode.shadowRoot);
    });

    test('Attaches a stylesheet to the shadow root', () {
      final html.Element firstChild =
          (hostNode.node as html.ShadowRoot).children.first;

      expect(firstChild.tagName, equalsIgnoringCase('style'));
    });

    _runDomTests(hostNode);
  });

  group('ElementHostNode', () {
    final HostNode hostNode = ElementHostNode(rootNode);

    test('Initializes and attaches a child element', () {
      expect(hostNode.node, isA<html.Element>());
      expect((hostNode.node as html.Element).shadowRoot, isNull);
      expect(hostNode.node.parent, rootNode);
    });

    _runDomTests(hostNode);
  });
}

// The common test suite that all types of HostNode implementations need to pass.
void _runDomTests(HostNode hostNode) {
  group('DOM operations', () {
    final html.Element target = html.document.createElement('div')..id = 'yep';

    setUp(() {
      hostNode.nodes.addAll([
        html.document.createElement('div'),
        target,
        html.document.createElement('span'),
        html.document.createElement('div'),
      ]);
    });

    tearDown(() {
      hostNode.nodes.clear();
    });

    test('querySelector', () {
      final html.Element? found = hostNode.querySelector('#yep');

      expect(identical(found, target), isTrue);
    });

    test('.contains and .append', () {
      final html.Element another = html.document.createElement('div')
        ..id = 'another';

      expect(hostNode.contains(target), isTrue);
      expect(hostNode.contains(another), isFalse);
      expect(hostNode.contains(null), isFalse);

      hostNode.append(another);
      expect(hostNode.contains(another), isTrue);
    });

    test('querySelectorAll', () {
      final List<html.Node> found = hostNode.querySelectorAll('div');

      expect(found.length, 3);
      expect(found[1], target);
    });
  });
}
