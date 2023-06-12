// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library wip.console_test;

import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/dom_model.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'test_setup.dart';

void main() {
  group('WipDomModel', () {
    WipDom? dom;

    setUp(() async {
      dom = WipDomModel((await navigateToPage('dom_model_test.html')).dom);
    });

    tearDown(() async {
      dom = null;
      await closeConnection();
    });

    test('maintains model across getDocument calls', () async {
      var document1 = await dom!.getDocument();
      var document2 = await dom!.getDocument();
      expect(document2.nodeId, document1.nodeId);
    });

    test('requestChildNodes updates children', () async {
      Node htmlNode = (await dom!.getDocument()).children![1];
      for (var child in htmlNode.children!) {
        expect(child.children, isNull);
        await dom!.requestChildNodes(child.nodeId);
      }
      // wait for children to be updated
      for (var child in htmlNode.children!) {
        expect(child.children, isNotNull);
      }
    });

    test('removing a node updates children', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      await dom!.requestChildNodes(bodyNode.nodeId);
      var childCount = bodyNode.childNodeCount!;
      await dom!.removeNode(bodyNode.children!.first.nodeId);

      expect(bodyNode.children, hasLength(childCount - 1));
      expect(bodyNode.childNodeCount, childCount - 1);
    });

    test('Moving a node updates children', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      await dom!.requestChildNodes(bodyNode.nodeId);
      Node div1 = bodyNode.children![0];
      Node div2 = bodyNode.children![1];

      expect(div1.childNodeCount, 1);
      expect(div2.childNodeCount, 0);

      await dom!.requestChildNodes(div1.nodeId);
      await dom!.requestChildNodes(div2.nodeId);

      await dom!.moveTo(div1.children!.first.nodeId, div2.nodeId);

      expect(div1.childNodeCount, 0);
      expect(div2.childNodeCount, 1);
      expect(div2.children, hasLength(1));
    }, skip: 'google/webkit_inspection_protocol.dart/issues/52');

    test('Setting node value updates value', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      await dom!.requestChildNodes(bodyNode.nodeId);

      Node div1 = bodyNode.children![0];
      await dom!.requestChildNodes(div1.nodeId);

      Node h1 = div1.children![0];
      await dom!.requestChildNodes(h1.nodeId);

      Node text = h1.children![0];

      expect(text.nodeValue, 'test');

      await dom!.setNodeValue(text.nodeId, 'some new text');

      expect(text.nodeValue, 'some new text');
    });

    test('Adding attribute updates attributes', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      expect(bodyNode.attributes!.containsKey('my-attr'), isFalse);
      await dom!.setAttributeValue(bodyNode.nodeId, 'my-attr', 'my-value');
      expect(bodyNode.attributes!['my-attr'], 'my-value');
    });

    test('Changing attribute updates attributes', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      expect(bodyNode.attributes!['test-attr'], 'test-attr-value');
      await dom!.setAttributeValue(bodyNode.nodeId, 'test-attr', 'my-value');
      expect(bodyNode.attributes!['test-attr'], 'my-value');
    });

    test('Removing attribute updates attributes', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      expect(bodyNode.attributes!['test-attr'], 'test-attr-value');
      await dom!.removeAttribute(bodyNode.nodeId, 'test-attr');
      expect(bodyNode.attributes!.containsKey('test-attr'), isFalse);
    });

    test('refreshing resets document', () async {
      var document1 = await dom!.getDocument();
      await navigateToPage('dom_model_test.html');
      var document2 = await dom!.getDocument();
      expect(document2.nodeId, isNot(document1.nodeId));
    });

    test('getting attributes works', () async {
      Node bodyNode = (await dom!.getDocument()).children![1].children![1];
      var attributes = bodyNode.attributes;
      var getAttributes = await dom!.getAttributes(bodyNode.nodeId);

      expect(getAttributes, attributes);
      expect(bodyNode.attributes, attributes);
    }, skip: 'google/webkit_inspection_protocol.dart/issues/52');
  });
}
