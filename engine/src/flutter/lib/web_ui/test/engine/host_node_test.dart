// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  final DomElement rootNode = domDocument.createElement('div');
  domDocument.body!.append(rootNode);

  group('ShadowDomHostNode', () {
    final HostNode hostNode = ShadowDomHostNode(rootNode);

    test('Initializes and attaches a shadow root', () {
      expect(domInstanceOfString(hostNode.node, 'ShadowRoot'), isTrue);
      expect((hostNode.node as DomShadowRoot).host, rootNode);
      expect(hostNode.node, rootNode.shadowRoot);

      // The shadow root should be initialized with correct parameters.
      expect(rootNode.shadowRoot!.mode, 'open');
      if (browserEngine != BrowserEngine.firefox &&
          browserEngine != BrowserEngine.webkit) {
        // Older versions of Safari and Firefox don't support this flag yet.
        // See: https://caniuse.com/mdn-api_shadowroot_delegatesfocus
        expect(rootNode.shadowRoot!.delegatesFocus, isFalse);
      }
    });

    test('Attaches a stylesheet to the shadow root', () {
      final DomElement firstChild =
          (hostNode.node as DomShadowRoot).childNodes.toList()[0] as DomElement;

      expect(firstChild.tagName, equalsIgnoringCase('style'));
    });

    _runDomTests(hostNode);
  });

  group('ElementHostNode', () {
    final HostNode hostNode = ElementHostNode(rootNode);

    test('Initializes and attaches a child element', () {
      expect(domInstanceOfString(hostNode.node, 'Element'), isTrue);
      expect((hostNode.node as DomElement).shadowRoot, isNull);
      expect(hostNode.node.parentNode, rootNode);
    });

    _runDomTests(hostNode);
  });
}

// The common test suite that all types of HostNode implementations need to pass.
void _runDomTests(HostNode hostNode) {
  group('DOM operations', () {
    final DomElement target = domDocument.createElement('div')..id = 'yep';

    setUp(() {
      hostNode.appendAll(<DomNode>[
        domDocument.createElement('div'),
        target,
        domDocument.createElement('flt-span'),
        domDocument.createElement('div'),
      ]);
    });

    tearDown(() {
      hostNode.node.clearChildren();
    });

    test('querySelector', () {
      final DomElement? found = hostNode.querySelector('#yep');

      expect(identical(found, target), isTrue);
    });

    test('.contains and .append', () {
      final DomElement another = domDocument.createElement('div')
        ..id = 'another';

      expect(hostNode.contains(target), isTrue);
      expect(hostNode.contains(another), isFalse);
      expect(hostNode.contains(null), isFalse);

      hostNode.append(another);
      expect(hostNode.contains(another), isTrue);
    });

    test('querySelectorAll', () {
      final List<DomNode> found = hostNode.querySelectorAll('div').toList();

      expect(found.length, 3);
      expect(found[1], target);
    });
  });
}
