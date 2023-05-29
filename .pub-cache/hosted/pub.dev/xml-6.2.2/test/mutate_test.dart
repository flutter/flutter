import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'utils/assertions.dart';
import 'utils/matchers.dart';

@isTest
void mutatingTest(String description, String before,
    void Function(XmlElement node) action, String after) {
  test(description, () {
    final document = XmlDocument.parse(before);
    action(document.rootElement);
    document.normalize();
    expect(document.toXmlString(), after, reason: 'should have been modified');
    assertDocumentTreeInvariants(document);
  });
}

@isTest
void throwingTest(String description, String before,
    void Function(XmlElement node) action, Matcher matcher) {
  test(description, () {
    final document = XmlDocument.parse(before);
    expect(() => action(document.rootElement), matcher);
    expect(document.toXmlString(), before,
        reason: 'should not have been modified');
    assertDocumentTreeInvariants(document);
  });
}

void main() {
  group('update', () {
    mutatingTest(
      'element (attribute value)',
      '<element attr="value"/>',
      (node) => node.attributes.first.value = 'update',
      '<element attr="update"/>',
    );
    mutatingTest(
      'cdata (text)',
      '<element><![CDATA[text]]></element>',
      (node) {
        final cdata = node.children.first as XmlCDATA;
        cdata.text = 'update';
      },
      '<element><![CDATA[update]]></element>',
    );
    mutatingTest(
      'comment (text)',
      '<element><!--comment--></element>',
      (node) {
        final comment = node.children.first as XmlComment;
        comment.text = 'update';
      },
      '<element><!--update--></element>',
    );
    mutatingTest(
      'element (self-closing: false)',
      '<element/>',
      (node) => node.isSelfClosing = false,
      '<element></element>',
    );
    mutatingTest(
      'element (self-closing: true)',
      '<element></element>',
      (node) => node.isSelfClosing = true,
      '<element/>',
    );
    test('processing (text)', () {
      final document = XmlDocument.parse('<?xml processing?><element/>');
      final processing = document.firstChild! as XmlProcessing;
      processing.text = 'update';
      expect(document.toXmlString(), '<?xml update?><element/>');
    });
    mutatingTest(
      'text (text)',
      '<element>Hello World</element>',
      (node) {
        final text = node.children.first as XmlText;
        text.text = 'Dart rocks';
      },
      '<element>Dart rocks</element>',
    );
  });
  group('add', () {
    mutatingTest(
      'element (attributes)',
      '<element/>',
      (node) => node.attributes.add(XmlAttribute(XmlName('attr'), 'value')),
      '<element attr="value"/>',
    );
    mutatingTest(
      'element (children)',
      '<element/>',
      (node) => node.children.add(XmlText('Hello World')),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr="value"><element2/></element1>',
      (node) =>
          node.children.first.attributes.add(node.attributes.first.copy()),
      '<element1 attr="value"><element2 attr="value"/></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2/></element1>',
      (node) => node.children.add(node.children.first.copy()),
      '<element1><element2/><element2/></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1/>',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element2')),
          XmlComment('comment'),
        ]);
        node.children.add(fragment);
      },
      '<element1>Hello<element2/><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1/>',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element2'))]);
        node.children
          ..add(fragment)
          ..add(fragment);
      },
      '<element1><element2/><element2/></element1>',
    );
    final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
    throwingTest(
      'element (attribute children)',
      '<element/>',
      (node) => node.children.add(wrong),
      throwsA(isXmlNodeTypeException(
          node: wrong, types: contains(XmlNodeType.ELEMENT))),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2/></element1>',
      (node) => node.children.add(node.firstChild!),
      throwsA(isXmlParentException()),
    );
  });
  group('addAll', () {
    mutatingTest(
      'element (attributes)',
      '<element/>',
      (node) =>
          node.attributes.addAll([XmlAttribute(XmlName('attr'), 'value')]),
      '<element attr="value"/>',
    );
    mutatingTest(
      'element (children)',
      '<element/>',
      (node) => node.children.addAll([XmlText('Hello World')]),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr="value"><element2/></element1>',
      (node) =>
          node.children.first.attributes.addAll([node.attributes.first.copy()]),
      '<element1 attr="value"><element2 attr="value"/></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2/></element1>',
      (node) => node.children.addAll([node.children.first.copy()]),
      '<element1><element2/><element2/></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1/>',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element2')),
          XmlComment('comment'),
        ]);
        node.children.addAll([fragment]);
      },
      '<element1>Hello<element2/><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1/>',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element2'))]);
        node.children.addAll([fragment, fragment]);
      },
      '<element1><element2/><element2/></element1>',
    );
    final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
    throwingTest(
      'element (attribute children)',
      '<element/>',
      (node) => node.children.addAll([wrong]),
      throwsA(isXmlNodeTypeException(
          node: wrong, types: contains(XmlNodeType.ELEMENT))),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2/></element1>',
      (node) => node.children.addAll([node.firstChild!]),
      throwsA(isXmlParentException()),
    );
  });
  group('innerText', () {
    mutatingTest(
      'empty with text',
      '<element/>',
      (node) {
        expect(node.innerText, '');
        node.innerText = 'inner text';
        expect(node.innerText, 'inner text');
      },
      '<element>inner text</element>',
    );
    mutatingTest(
      'empty with text (encoded)',
      '<element/>',
      (node) {
        expect(node.innerText, '');
        node.innerText = '<child>';
        expect(node.innerText, '<child>');
      },
      '<element>&lt;child></element>',
    );
    mutatingTest(
      'multiple with text',
      '<element>multiple <child/>nodes</element>',
      (node) {
        expect(node.innerText, 'multiple nodes');
        node.innerText = 'replaced';
        expect(node.innerText, 'replaced');
      },
      '<element>replaced</element>',
    );
    mutatingTest(
      'text with empty',
      '<element>contents</element>',
      (node) {
        expect(node.innerText, 'contents');
        node.innerText = '';
        expect(node.children, isEmpty);
        expect(node.innerText, '');
      },
      '<element/>',
    );
    throwingTest(
      'unsupported text node',
      '<element>contents</element>',
      (node) {
        expect(node.firstChild, isA<XmlText>());
        node.firstChild!.innerText = 'error';
      },
      throwsA(isXmlNodeTypeException(
        message: 'XmlNodeType.TEXT cannot have child nodes.',
        node: isA<XmlText>(),
        types: isEmpty,
      )),
    );
  });
  group('innerXml', () {
    mutatingTest(
      'empty with multiple',
      '<element/>',
      (node) {
        expect(node.innerXml, '');
        node.innerXml = '<child1/> and <child2/>';
        expect(node.innerXml, '<child1/> and <child2/>');
      },
      '<element><child1/> and <child2/></element>',
    );
    mutatingTest(
      'multiple with empty',
      '<element><child1/> and <child2/></element>',
      (node) {
        expect(node.innerXml, '<child1/> and <child2/>');
        node.innerXml = '';
        expect(node.children, isEmpty);
        expect(node.innerXml, '');
      },
      '<element/>',
    );
    throwingTest(
      'unsupported text node',
      '<element>contents</element>',
      (node) {
        expect(node.firstChild, isA<XmlText>());
        node.firstChild!.innerXml = 'error';
      },
      throwsA(isXmlNodeTypeException(
        message: 'XmlNodeType.TEXT cannot have child nodes.',
        node: isA<XmlText>(),
        types: isEmpty,
      )),
    );
  });
  group('outerXml', () {
    mutatingTest(
      'single with other',
      '<element><child/></element>',
      (node) {
        expect(node.firstChild!.outerXml, '<child/>');
        node.firstChild!.outerXml = '<other/>';
        expect(node.firstChild!.outerXml, '<other/>');
      },
      '<element><other/></element>',
    );
    mutatingTest(
      'single with multiple',
      '<element><child/></element>',
      (node) {
        final child = node.firstChild!;
        expect(child.outerXml, '<child/>');
        child.outerXml = '<child1/> and <child2/>';
      },
      '<element><child1/> and <child2/></element>',
    );
    mutatingTest(
      'multiple with empty',
      '<element><child1/> and <child2/></element>',
      (node) {
        expect(node.children[1].outerXml, ' and ');
        node.children[1].outerXml = '';
        expect(node.children.length, 2);
      },
      '<element><child1/><child2/></element>',
    );
  });
  group('insert', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1"/>',
      (node) =>
          node.attributes.insert(1, XmlAttribute(XmlName('attr2'), 'value2')),
      '<element attr1="value1" attr2="value2"/>',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello</element>',
      (node) => node.children.insert(1, XmlText(' World')),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr1="value1"><element2 attr2="value2"/></element1>',
      (node) => node.children.first.attributes
          .insert(1, node.attributes.first.copy()),
      '<element1 attr1="value1"><element2 attr2="value2" attr1="value1"/></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2/></element1>',
      (node) => node.children.insert(1, node.children.first.copy()),
      '<element1><element2/><element2/></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1><element2/></element1>',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element3')),
          XmlComment('comment'),
        ]);
        node.children.insert(1, fragment);
      },
      '<element1><element2/>Hello<element3/><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1><element2/></element1>',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element3'))]);
        node.children
          ..insert(0, fragment)
          ..insert(2, fragment);
      },
      '<element1><element3/><element2/><element3/></element1>',
    );
    throwingTest(
      'element (attribute range error)',
      '<element attr1="value1"/>',
      (node) =>
          node.attributes.insert(2, XmlAttribute(XmlName('attr2'), 'value2')),
      throwsRangeError,
    );
    throwingTest(
      'element (children range error)',
      '<element>Hello</element>',
      (node) => node.children.insert(2, XmlText(' World')),
      throwsRangeError,
    );
    final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
    throwingTest(
      'element (attribute children)',
      '<element/>',
      (node) => node.children.insert(0, wrong),
      throwsA(isXmlNodeTypeException(
          node: wrong, types: contains(XmlNodeType.ELEMENT))),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2/></element1>',
      (node) => node.children.insert(0, node.firstChild!),
      throwsA(isXmlParentException()),
    );
  });
  group('insertAll', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1"/>',
      (node) => node.attributes
          .insertAll(1, [XmlAttribute(XmlName('attr2'), 'value2')]),
      '<element attr1="value1" attr2="value2"/>',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello</element>',
      (node) => node.children.insertAll(1, [XmlText(' World')]),
      '<element>Hello World</element>',
    );
    mutatingTest(
      'element (copy attribute)',
      '<element1 attr1="value1"><element2 attr2="value2"/></element1>',
      (node) => node.children.first.attributes
          .insertAll(1, [node.attributes.first.copy()]),
      '<element1 attr1="value1"><element2 attr2="value2" attr1="value1"/></element1>',
    );
    mutatingTest(
      'element (copy children)',
      '<element1><element2/></element1>',
      (node) => node.children.insertAll(1, [node.children.first.copy()]),
      '<element1><element2/><element2/></element1>',
    );
    mutatingTest(
      'element (fragment children)',
      '<element1><element2/></element1>',
      (node) {
        final fragment = XmlDocumentFragment([
          XmlText('Hello'),
          XmlElement(XmlName('element3')),
          XmlComment('comment'),
        ]);
        node.children.insertAll(1, [fragment]);
      },
      '<element1><element2/>Hello<element3/><!--comment--></element1>',
    );
    mutatingTest(
      'element (repeated fragment children)',
      '<element1><element2/></element1>',
      (node) {
        final fragment = XmlDocumentFragment([XmlElement(XmlName('element3'))]);
        node.children.insertAll(0, [fragment, fragment]);
      },
      '<element1><element3/><element3/><element2/></element1>',
    );
    throwingTest(
      'element (attribute range error)',
      '<element attr1="value1"/>',
      (node) => node.attributes
          .insertAll(2, [XmlAttribute(XmlName('attr2'), 'value2')]),
      throwsRangeError,
    );
    throwingTest(
      'element (children range error)',
      '<element>Hello</element>',
      (node) => node.children.insertAll(2, [XmlText(' World')]),
      throwsRangeError,
    );
    final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
    throwingTest(
      'element (attribute children)',
      '<element/>',
      (node) => node.children.insertAll(0, [wrong]),
      throwsA(isXmlNodeTypeException(
          node: wrong, types: contains(XmlNodeType.ELEMENT))),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2/></element1>',
      (node) => node.children.insertAll(0, [node.firstChild!]),
      throwsA(isXmlParentException()),
    );
  });
  group('[]=', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1"/>',
      (node) => node.attributes[0] = XmlAttribute(XmlName('attr2'), 'value2'),
      '<element attr2="value2"/>',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children[0] = XmlText('Dart rocks'),
      '<element>Dart rocks</element>',
    );
    throwingTest(
      'element (attribute range error)',
      '<element attr1="value1"/>',
      (node) => node.attributes[2] = XmlAttribute(XmlName('attr2'), 'value2'),
      throwsRangeError,
    );
    throwingTest(
      'element (children range error)',
      '<element>Hello</element>',
      (node) => node.children[2] = XmlText(' World'),
      throwsRangeError,
    );
    final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
    throwingTest(
      'element (attribute children)',
      '<element1><element2/></element1>',
      (node) => node.children[0] = wrong,
      throwsA(isXmlNodeTypeException(
          node: wrong, types: contains(XmlNodeType.ELEMENT))),
    );
    throwingTest(
      'element (parent error)',
      '<element1><element2/></element1>',
      (node) => node.children[0] = node.firstChild!,
      throwsA(isXmlParentException()),
    );
  });
  group('remove', () {
    mutatingTest(
      'element (attributes)',
      '<element attr="value"/>',
      (node) => node.attributes.remove(node.attributes.first),
      '<element/>',
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children.remove(node.children.first),
      '<element/>',
    );
    mutatingTest(
      'element (attribute children)',
      '<element>Hello World</element>',
      (node) {
        final wrong = XmlAttribute(XmlName('invalid'), 'invalid');
        node.children.remove(wrong);
      },
      '<element>Hello World</element>',
    );
  });
  group('removeAt', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.removeAt(1),
      '<element attr1="value1"/>',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.removeAt(2),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children.removeAt(0),
      '<element/>',
    );
    throwingTest(
      'element (children range error',
      '<element>Hello World</element>',
      (node) => node.children.removeAt(2),
      throwsRangeError,
    );
  });
  group('removeWhere', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) =>
          node.attributes.removeWhere((node) => node.localName == 'attr2'),
      '<element attr1="value1"/>',
    );
    mutatingTest(
      'element (children)',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.removeWhere(
          (node) => node is XmlElement && node.localName == 'element3'),
      '<element1><element2/></element1>',
    );
  });
  group('retainWhere', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) =>
          node.attributes.retainWhere((node) => node.localName == 'attr1'),
      '<element attr1="value1"/>',
    );
    mutatingTest(
      'element (children)',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.retainWhere(
          (node) => node is XmlElement && node.localName == 'element2'),
      '<element1><element2/></element1>',
    );
  });
  group('clear', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.clear(),
      '<element/>',
    );
    mutatingTest(
      'element (children)',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.clear(),
      '<element1/>',
    );
  });
  group('removeLast', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.removeLast(),
      '<element attr1="value1"/>',
    );
    throwingTest(
      'element (attributes range error)',
      '<element/>',
      (node) => node.attributes.removeLast(),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element>Hello World</element>',
      (node) => node.children.removeLast(),
      '<element/>',
    );
    throwingTest(
      'element (children range error',
      '<element/>',
      (node) => node.children.removeLast(),
      throwsRangeError,
    );
  });
  group('removeRange', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.removeRange(0, 1),
      '<element attr2="value2"/>',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.removeRange(0, 3),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.removeRange(1, 2),
      '<element1><element2/></element1>',
    );
    throwingTest(
      'element (children range error',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.removeRange(0, 3),
      throwsRangeError,
    );
  });
  group('setRange', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.setRange(0, 1, [
        XmlAttribute(XmlName('attr3'), 'value3'),
      ]),
      '<element attr3="value3" attr2="value2"/>',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.setRange(0, 3, [
        XmlAttribute(XmlName('attr3'), 'value3'),
        XmlAttribute(XmlName('attr4'), 'value4'),
        XmlAttribute(XmlName('attr5'), 'value5'),
      ]),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.setRange(1, 2, [
        XmlElement(XmlName('element4')),
      ]),
      '<element1><element2/><element4/></element1>',
    );
    throwingTest(
      'element (children range error',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.setRange(0, 3, [
        XmlElement(XmlName('element4')),
        XmlElement(XmlName('element5')),
        XmlElement(XmlName('element6')),
      ]),
      throwsRangeError,
    );
  });
  group('replace', () {
    mutatingTest(
      'element node with text',
      '<element><child/></element>',
      (node) => node.firstChild!.replace(XmlText('child')),
      '<element>child</element>',
    );
    mutatingTest(
      'element text with node',
      '<element>child</element>',
      (node) => node.firstChild!.replace(XmlElement(XmlName('child'))),
      '<element><child/></element>',
    );
    mutatingTest(
      'element text with empty fragment',
      '<element><child/></element>',
      (node) => node.firstChild!.replace(XmlDocumentFragment()),
      '<element/>',
    );
    mutatingTest(
      'element text with one element fragment',
      '<element><child/></element>',
      (node) => node.firstChild!.replace(XmlDocumentFragment([
        XmlText('child'),
      ])),
      '<element>child</element>',
    );
    mutatingTest(
      'element text with multiple element fragment',
      '<element><child/></element>',
      (node) => node.firstChild!.replace(XmlDocumentFragment([
        XmlElement(XmlName('child1')),
        XmlElement(XmlName('child2')),
      ])),
      '<element><child1/><child2/></element>',
    );
    mutatingTest(
      'element node with multiple element fragment',
      '<element>before<child/>after</element>',
      (node) => node.children[1].replace(XmlDocumentFragment([
        XmlElement(XmlName('child1')),
        XmlElement(XmlName('child2')),
      ])),
      '<element>before<child1/><child2/>after</element>',
    );
  });
  group('replaceRange', () {
    mutatingTest(
      'element (attributes)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes
          .replaceRange(0, 1, [XmlAttribute(XmlName('attr3'), 'value3')]),
      '<element attr3="value3" attr2="value2"/>',
    );
    throwingTest(
      'element (attributes range error)',
      '<element attr1="value1" attr2="value2"/>',
      (node) => node.attributes.replaceRange(0, 3, [
        XmlAttribute(XmlName('attr3'), 'value3'),
        XmlAttribute(XmlName('attr4'), 'value4'),
        XmlAttribute(XmlName('attr5'), 'value5')
      ]),
      throwsRangeError,
    );
    mutatingTest(
      'element (children)',
      '<element1><element2/><element3/></element1>',
      (node) =>
          node.children.replaceRange(1, 2, [XmlElement(XmlName('element4'))]),
      '<element1><element2/><element4/></element1>',
    );
    throwingTest(
      'element (children range error',
      '<element1><element2/><element3/></element1>',
      (node) => node.children.replaceRange(0, 3, [
        XmlElement(XmlName('element4')),
        XmlElement(XmlName('element5')),
        XmlElement(XmlName('element6')),
      ]),
      throwsRangeError,
    );
  });
  group('unsupported method', () {
    throwingTest(
      'fillRange',
      '<element/>',
      (node) => node.children.fillRange(0, 1),
      throwsUnsupportedError,
    );
    throwingTest(
      'setAll',
      '<element/>',
      (node) => node.children.setAll(0, []),
      throwsUnsupportedError,
    );
    throwingTest(
      'length',
      '<element/>',
      (node) => node.children.length = 2,
      throwsUnsupportedError,
    );
  });
}
