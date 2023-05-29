import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'utils/assertions.dart';
import 'utils/matchers.dart';

void main() {
  group('element', () {
    test('basic', () {
      final document = XmlDocument.parse(
          '<ns:data key="value">Am I or are the other crazy?</ns:data>');
      final node = document.rootElement;
      // expect(node.name, XmlName.fromString('ns:data'));
      expect(node.parent, same(document));
      expect(node.parentElement, isNull);
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.depth, 1);
      expect(node.attributes, hasLength(1));
      expect(node.children, hasLength(1));
      expect(node.descendants, hasLength(2));
      expect(node.text, 'Am I or are the other crazy?');
      expect(node.nodeType, XmlNodeType.ELEMENT);
      expect(node.nodeType.toString(), 'XmlNodeType.ELEMENT');
      expect(node.isSelfClosing, isTrue);
      expect(node.toString(),
          '<ns:data key="value">Am I or are the other crazy?</ns:data>');
    });
    test('self-closing', () {
      final document = XmlDocument.parse('<data/>');
      final node = document.rootElement;
      // expect(node.name, XmlName.fromString('data'));
      expect(node.parent, same(document));
      expect(node.parentElement, isNull);
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.depth, 1);
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.descendants, isEmpty);
      expect(node.text, '');
      expect(node.nodeType, XmlNodeType.ELEMENT);
      expect(node.nodeType.toString(), 'XmlNodeType.ELEMENT');
      expect(node.isSelfClosing, isTrue);
      expect(node.toString(), '<data/>');
    });
    test('empty', () {
      final document = XmlDocument.parse('<data></data>');
      final node = document.rootElement;
      expect(node.name.qualified, 'data');
      expect(node.parent, same(document));
      expect(node.parentElement, isNull);
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.depth, 1);
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.descendants, isEmpty);
      expect(node.text, '');
      expect(node.nodeType, XmlNodeType.ELEMENT);
      expect(node.nodeType.toString(), 'XmlNodeType.ELEMENT');
      expect(node.isSelfClosing, isFalse);
      expect(node.toString(), '<data></data>');
    });
    test('nested', () {
      final document = XmlDocument.parse('<outer><inner/></outer>');
      final outer = document.rootElement;
      expect(outer.toString(), '<outer><inner/></outer>');
      final inner = outer.firstChild!;
      expect(outer.getElement('inner'), same(inner));
      expect(inner.parentElement, same(outer));
      expect(inner.toString(), '<inner/>');
    });
    test('constructor error', () {
      final document =
          XmlDocument.parse('<element attr="value1">text</element>');
      final node = document.rootElement;
      expect(() => XmlElement(node.name), throwsA(isXmlParentException()));
      expect(() => XmlElement(XmlName('data'), node.attributes),
          throwsA(isXmlParentException()));
      expect(() => XmlElement(XmlName('data'), [], node.children),
          throwsA(isXmlParentException()));
    });
    test('add attribute', () {
      final document = XmlDocument.parse('<data/>');
      final node = document.rootElement;
      expect(node.getAttribute('attr'), isNull);
      expect(node.getAttributeNode('attr'), isNull);
      node.setAttribute('attr', 'value');
      expect(node.getAttribute('attr'), 'value');
      expect(node.getAttributeNode('attr')?.value, 'value');
      expect(node.toString(), '<data attr="value"/>');
    });
    test('add attribute with namespace', () {
      final document = XmlDocument.parse('<data xmlns:ns="uri" />');
      final node = document.rootElement;
      expect(node.getAttribute('attr', namespace: 'uri'), isNull);
      expect(node.getAttributeNode('attr', namespace: 'uri'), isNull);
      node.setAttribute('attr', 'value', namespace: 'uri');
      expect(node.getAttribute('attr', namespace: 'uri'), 'value');
      expect(node.getAttributeNode('attr', namespace: 'uri')?.value, 'value');
      expect(node.toString(), '<data xmlns:ns="uri" ns:attr="value"/>');
    });
    test('add attribute with default namespace', () {
      final document = XmlDocument.parse('<data xmlns="uri" />');
      final node = document.rootElement;
      expect(node.getAttribute('attr', namespace: 'uri'), isNull);
      expect(node.getAttributeNode('attr', namespace: 'uri'), isNull);
      node.setAttribute('attr', 'value', namespace: 'uri');
      expect(node.getAttribute('attr', namespace: 'uri'), 'value');
      expect(node.getAttributeNode('attr', namespace: 'uri')?.value, 'value');
      expect(node.toString(), '<data xmlns="uri" attr="value"/>');
    });
    test('update attribute', () {
      final document = XmlDocument.parse('<data attr="old"/>');
      final node = document.rootElement;
      node.setAttribute('attr', 'new');
      expect(node.getAttribute('attr'), 'new');
      expect(node.getAttributeNode('attr')?.value, 'new');
      expect(node.toString(), '<data attr="new"/>');
    });
    test('update attribute with namespace', () {
      final document =
          XmlDocument.parse('<data xmlns:ns="uri" ns:attr="old"/>');
      final node = document.rootElement;
      node.setAttribute('attr', 'new', namespace: 'uri');
      expect(node.getAttribute('attr', namespace: 'uri'), 'new');
      expect(node.getAttributeNode('attr', namespace: 'uri')?.value, 'new');
      expect(node.toString(), '<data xmlns:ns="uri" ns:attr="new"/>');
    });
    test('update attribute with default namespace', () {
      final document = XmlDocument.parse('<data xmlns="uri" attr="old"/>');
      final node = document.rootElement;
      node.setAttribute('attr', 'new', namespace: 'uri');
      expect(node.getAttribute('attr', namespace: 'uri'), 'new');
      expect(node.getAttributeNode('attr', namespace: 'uri')?.value, 'new');
      expect(node.toString(), '<data xmlns="uri" attr="new"/>');
    });
    test('update attribute with qualified name', () {
      final document = XmlDocument.parse('<data unknown:attr="old"/>');
      final node = document.rootElement;
      node.setAttribute('unknown:attr', 'new');
      expect(node.getAttribute('unknown:attr'), 'new');
      expect(node.getAttributeNode('unknown:attr')?.value, 'new');
      expect(node.toString(), '<data unknown:attr="new"/>');
    });
    test('remove attribute', () {
      final document = XmlDocument.parse('<data attr="old"/>');
      final node = document.rootElement;
      node.removeAttribute('attr');
      expect(node.getAttribute('attr'), isNull);
      expect(node.getAttributeNode('attr'), isNull);
      expect(node.toString(), '<data/>');
    });
    test('remove attribute with namespace', () {
      final document =
          XmlDocument.parse('<data xmlns:ns="uri" ns:attr="old"/>');
      final node = document.rootElement;
      node.removeAttribute('attr', namespace: 'uri');
      expect(node.getAttribute('attr', namespace: 'uri'), isNull);
      expect(node.getAttributeNode('attr', namespace: 'uri'), isNull);
      expect(node.toString(), '<data xmlns:ns="uri"/>');
    });
    test('remove attribute with default namespace', () {
      final document = XmlDocument.parse('<data xmlns="uri" attr="old"/>');
      final node = document.rootElement;
      node.removeAttribute('attr', namespace: 'uri');
      expect(node.getAttribute('attr', namespace: 'uri'), isNull);
      expect(node.getAttributeNode('attr', namespace: 'uri'), isNull);
      expect(node.toString(), '<data xmlns="uri"/>');
    });
  });
  group('attribute', () {
    group('double quote', () {
      test('basic', () {
        final document = XmlDocument.parse(
            '<data ns:attr="Am I or are the other crazy?" />');
        final node = document.rootElement.attributes.single;
        expect(node.name.qualified, 'ns:attr');
        expect(node.value, 'Am I or are the other crazy?');
        expect(node.attributeType, XmlAttributeType.DOUBLE_QUOTE);
        expect(node.parent, same(document.rootElement));
        expect(node.parentElement, same(document.rootElement));
        expect(node.root, same(document));
        expect(node.document, same(document));
        expect(node.depth, 2);
        expect(node.attributes, isEmpty);
        expect(node.children, isEmpty);
        expect(node.descendants, isEmpty);
        expect(node.text, isEmpty);
        expect(node.nodeType, XmlNodeType.ATTRIBUTE);
        expect(node.nodeType.toString(), 'XmlNodeType.ATTRIBUTE');
        expect(node.toString(), 'ns:attr="Am I or are the other crazy?"');
      });
      test('empty', () {
        final document = XmlDocument.parse('<data attr="" />');
        final node = document.rootElement.attributes.single;
        expect(node.value, '');
        expect(node.toString(), 'attr=""');
      });
      test('character references', () {
        final document = XmlDocument.parse(
            '<data ns:attr="&lt;&gt;&amp;&apos;&quot;&#xA;&#xD;&#x9;" />');
        final node = document.rootElement.attributes.single;
        expect(node.value, '<>&\'"\n\r\t');
        expect(node.toString(), 'ns:attr="&lt;>&amp;\'&quot;&#xA;&#xD;&#x9;"');
      });
    });
    group('single quote', () {
      test('basic', () {
        final document = XmlDocument.parse(
            '<data ns:attr=\'Am I or are the other crazy?\' />');
        final node = document.rootElement.attributes.single;
        expect(node.name.qualified, 'ns:attr');
        expect(node.value, 'Am I or are the other crazy?');
        expect(node.attributeType, XmlAttributeType.SINGLE_QUOTE);
        expect(node.parent, same(document.rootElement));
        expect(node.parentElement, same(document.rootElement));
        expect(node.root, same(document));
        expect(node.document, same(document));
        expect(node.depth, 2);
        expect(node.attributes, isEmpty);
        expect(node.children, isEmpty);
        expect(node.descendants, isEmpty);
        expect(node.text, isEmpty);
        expect(node.nodeType, XmlNodeType.ATTRIBUTE);
        expect(node.nodeType.toString(), 'XmlNodeType.ATTRIBUTE');
        expect(node.toString(), "ns:attr='Am I or are the other crazy?'");
      });
      test('empty)', () {
        final document = XmlDocument.parse('<data attr=\'\' />');
        final node = document.rootElement.attributes.single;
        expect(node.value, '');
        expect(node.toString(), "attr=''");
      });
      test('character references)', () {
        final document = XmlDocument.parse(
            '<data ns:attr=\'&lt;&gt;&amp;&apos;&quot;&#xA;&#xD;&#x9;\' />');
        final node = document.rootElement.attributes.single;
        expect(node.value, '<>&\'"\n\r\t');
        expect(node.toString(), "ns:attr='&lt;>&amp;&apos;\"&#xA;&#xD;&#x9;'");
      });
    });
    test('constructor error', () {
      final document = XmlDocument.parse('<data ns:attr=""/>');
      final node = document.rootElement.attributes.single;
      expect(
          () => XmlAttribute(node.name, ''), throwsA(isXmlParentException()));
    });
  });
  group('text', () {
    test('basic', () {
      final document =
          XmlDocument.parse('<data>Am I or are the other crazy?</data>');
      final node = document.rootElement.children.single as XmlText;
      expect(node.text, 'Am I or are the other crazy?');
      expect(node.parent, same(document.rootElement));
      expect(node.parentElement, same(document.rootElement));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.depth, 2);
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.nodeType, XmlNodeType.TEXT);
      expect(node.nodeType.toString(), 'XmlNodeType.TEXT');
      expect(node.toString(), 'Am I or are the other crazy?');
    });
    test('character references', () {
      final document =
          XmlDocument.parse('<data>&lt;&gt;&amp;&apos;&quot;</data>');
      final node = document.rootElement.children.single;
      expect(node.text, '<>&\'"');
      expect(node.toString(), '&lt;>&amp;\'"');
    });
    test('nested', () {
      final root = XmlDocument.parse(
          '<p>Am <i>I</i> or are the <b>other</b><!-- very --> crazy?</p>');
      expect(root.rootElement.text, 'Am I or are the other crazy?');
    });
  });
  test('cdata', () {
    final document = XmlDocument.parse('<data>'
        '<![CDATA[Methinks <word> it <word> is like a weasel!]]>'
        '</data>');
    expect(document.rootElement.text,
        'Methinks <word> it <word> is like a weasel!');
    final node = document.rootElement.children.single;
    expect(node.text, 'Methinks <word> it <word> is like a weasel!');
    expect(node.parent, same(document.rootElement));
    expect(node.parentElement, same(document.rootElement));
    expect(node.root, same(document));
    expect(node.document, same(document));
    expect(node.depth, 2);
    expect(node.attributes, isEmpty);
    expect(node.children, isEmpty);
    expect(node.nodeType, XmlNodeType.CDATA);
    expect(node.nodeType.toString(), 'XmlNodeType.CDATA');
    expect(node.toString(),
        '<![CDATA[Methinks <word> it <word> is like a weasel!]]>');
  });
  group('declaration', () {
    test('declaration', () {
      final document =
          XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?><data/>');
      final node = document.declaration!;
      expect(node.version, '1.0');
      expect(node.encoding, 'UTF-8');
      expect(node.standalone, isFalse);
      expect(node.parent, same(document));
      expect(node.parentElement, isNull);
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.depth, 1);
      expect(node.attributes, hasLength(2));
      expect(node.children, isEmpty);
      expect(node.nodeType, XmlNodeType.DECLARATION);
      expect(node.nodeType.toString(), 'XmlNodeType.DECLARATION');
      expect(node.toString(), '<?xml version="1.0" encoding="UTF-8"?>');
    });
    test('add attribute', () {
      final document = XmlDocument.parse('<?xml?><data/>');
      final node = document.declaration!;
      node.setAttribute('other', 'value');
      expect(node.toString(), '<?xml other="value"?>');
    });
    test('update attribute', () {
      final document = XmlDocument.parse('<?xml other="value"?><data/>');
      final node = document.declaration!;
      node.setAttribute('other', 'some');
      expect(node.toString(), '<?xml other="some"?>');
    });
    test('remove attribute', () {
      final document =
          XmlDocument.parse('<?xml version="1.0" other="value"?><data/>');
      final node = document.declaration!;
      node.removeAttribute('other');
      expect(node.toString(), '<?xml version="1.0"?>');
    });
    test('version', () {
      final document = XmlDocument.parse('<?xml?><data/>');
      final node = document.declaration!;
      expect(node.version, isNull);
      node.version = '1.1';
      expect(node.version, '1.1');
      expect(node.toString(), '<?xml version="1.1"?>');
      node.version = null;
      expect(node.version, isNull);
      expect(node.toString(), '<?xml?>');
    });
    test('encoding', () {
      final document = XmlDocument.parse('<?xml?><data/>');
      final node = document.declaration!;
      expect(node.encoding, isNull);
      node.encoding = 'utf-16';
      expect(node.encoding, 'utf-16');
      expect(node.toString(), '<?xml encoding="utf-16"?>');
      node.encoding = null;
      expect(node.encoding, isNull);
      expect(node.toString(), '<?xml?>');
    });
    test('standalone', () {
      final document = XmlDocument.parse('<?xml?><data/>');
      final node = document.declaration!;
      node.standalone = true;
      expect(node.standalone, isTrue);
      expect(node.toString(), '<?xml standalone="yes"?>');
      node.standalone = false;
      expect(node.standalone, isFalse);
      expect(node.toString(), '<?xml standalone="no"?>');
      node.standalone = null;
      expect(node.standalone, isFalse);
      expect(node.toString(), '<?xml?>');
    });
  });
  test('processing', () {
    final document =
        XmlDocument.parse('<?xml-stylesheet href="style.css"?><data/>');
    final node = document.firstChild! as XmlProcessing;
    expect(node.target, 'xml-stylesheet');
    expect(node.text, 'href="style.css"');
    expect(node.parent, same(document));
    expect(node.parentElement, isNull);
    expect(node.root, same(document));
    expect(node.document, same(document));
    expect(node.depth, 1);
    expect(node.attributes, isEmpty);
    expect(node.children, isEmpty);
    expect(node.nodeType, XmlNodeType.PROCESSING);
    expect(node.nodeType.toString(), 'XmlNodeType.PROCESSING');
    expect(node.toString(), '<?xml-stylesheet href="style.css"?>');
  });
  test('comment', () {
    final document =
        XmlDocument.parse('<data><!--Am I or are the other crazy?--></data>');
    final node = document.rootElement.children.single;
    expect(node.parent, same(document.rootElement));
    expect(node.parentElement, same(document.rootElement));
    expect(node.root, same(document));
    expect(node.document, same(document));
    expect(node.depth, 2);
    expect(node.attributes, isEmpty);
    expect(node.children, isEmpty);
    expect(node.text, 'Am I or are the other crazy?');
    expect(node.nodeType, XmlNodeType.COMMENT);
    expect(node.nodeType.toString(), 'XmlNodeType.COMMENT');
    expect(node.toString(), '<!--Am I or are the other crazy?-->');
  });
  group('document', () {
    test('basic', () {
      final node = XmlDocument.parse('<data/>');
      expect(node.parent, isNull);
      expect(node.parentElement, isNull);
      expect(node.root, same(node));
      expect(node.document, same(node));
      expect(node.depth, 0);
      expect(node.attributes, isEmpty);
      expect(node.children, hasLength(1));
      expect(node.text, '');
      expect(node.nodeType, XmlNodeType.DOCUMENT);
      expect(node.nodeType.toString(), 'XmlNodeType.DOCUMENT');
      expect(node.toString(), '<data/>');
    });
    test('definition', () {
      final node = XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?>'
          '<element/>');
      expect(node.children, hasLength(2));
      expect(
          node.toString(),
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<element/>');
    });
    test('comments and whitespace', () {
      final node = XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?> '
          '<!-- before -->\n<element/>\t<!-- after -->');
      expect(node.attributes, isEmpty);
      expect(node.children, hasLength(7));
      expect(
          node.toString(),
          '<?xml version="1.0" encoding="UTF-8"?> '
          '<!-- before -->\n<element/>\t<!-- after -->');
      expect(
          node.toXmlString(pretty: true),
          '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<!-- before -->\n<element/>\n<!-- after -->');
    });
    test('empty', () {
      final document = XmlDocument();
      expect(document.declaration, isNull);
      expect(document.doctypeElement, isNull);
      expect(() => document.rootElement, throwsStateError);
    });
    test('attributes', () {
      final document = XmlDocument();
      expect(document.attributes, isEmpty);
      expect(document.getAttribute('attr'), isNull);
      expect(document.getAttributeNode('attr'), isNull);
      expect(
          () => document.setAttribute('attr', 'value'), throwsUnsupportedError);
      expect(() => document.removeAttribute('attr'), throwsUnsupportedError);
      expect(
          () => document.attributes
              .add(XmlAttribute(XmlName.fromString('attr'), 'value')),
          throwsUnsupportedError);
    });
  });
  test('document type', () {
    final document =
        XmlDocument.parse('<!DOCTYPE html [<!-- internal subset -->]><data />');
    final node = document.doctypeElement!;
    expect(node.parent, same(document));
    expect(node.parentElement, isNull);
    expect(node.document, same(document));
    expect(node.depth, 1);
    expect(node.attributes, isEmpty);
    expect(node.children, isEmpty);
    expect(node.name, 'html');
    expect(node.externalId, isNull);
    expect(node.internalSubset, '<!-- internal subset -->');
    expect(node.nodeType, XmlNodeType.DOCUMENT_TYPE);
    expect(node.nodeType.toString(), 'XmlNodeType.DOCUMENT_TYPE');
    expect(node.toString(), '<!DOCTYPE html [<!-- internal subset -->]>');
  });
  group('document fragment', () {
    test('basic', () {
      final node = XmlDocumentFragment.parse('<!--Am I a joke to you?-->No');
      assertCopyInvariants(node);
      expect(node.parent, isNull);
      expect(node.parentElement, isNull);
      expect(node.root, node);
      expect(node.document, isNull);
      expect(node.depth, 0);
      expect(node.attributes, isEmpty);
      expect(node.children, hasLength(2));
      expect(node.text, 'No');
      expect(node.nodeType, XmlNodeType.DOCUMENT_FRAGMENT);
      expect(node.nodeType.toString(), 'XmlNodeType.DOCUMENT_FRAGMENT');
      expect(node.toString(), '#document-fragment');
    });
    test('empty', () {
      final node = XmlDocumentFragment();
      assertCopyInvariants(node);
      expect(node.parent, isNull);
      expect(node.parentElement, isNull);
      expect(node.root, node);
      expect(node.document, isNull);
      expect(node.depth, 0);
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.text, '');
      expect(node.nodeType, XmlNodeType.DOCUMENT_FRAGMENT);
      expect(node.nodeType.toString(), 'XmlNodeType.DOCUMENT_FRAGMENT');
      expect(node.toString(), '#document-fragment');
    });
  });
}
