import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('normalizer', () {
    test('remove empty text', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlText(''),
        XmlElement(XmlName('element1')),
        XmlText(''),
        XmlElement(XmlName('element2')),
        XmlText(''),
      ]);
      element.normalize();
      expect(element.children.length, 2);
      expect(
          element.toXmlString(), '<element><element1/><element2/></element>');
    });
    test('join adjacent text', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlText('aaa'),
        XmlText('bbb'),
        XmlText('ccc'),
      ]);
      element.normalize();
      expect(element.children.length, 1);
      expect(element.toXmlString(), '<element>aaabbbccc</element>');
    });
    test('trim whitespace', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlText(' a '),
        XmlText(' b '),
      ]);
      element.normalize(trimWhitespace: (node) => true);
      expect(element.children.length, 1);
      expect(element.toXmlString(), '<element>a  b</element>');
    });
    test('selectively trim whitespace', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlElement(XmlName('a'), [], [XmlText(' 1 ')]),
        XmlElement(XmlName('b'), [], [XmlText(' 2 ')]),
      ]);
      element.normalize(trimWhitespace: (node) => node.text == ' 2 ');
      expect(element.toXmlString(), '<element><a> 1 </a><b>2</b></element>');
    });
    test('collapse whitespace', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlText(' a '),
        XmlText(' b '),
      ]);
      element.normalize(collapseWhitespace: (node) => true);
      expect(element.children.length, 1);
      expect(element.toXmlString(), '<element> a b </element>');
    });
    test('selectively collapse whitespace', () {
      final element = XmlElement(XmlName('element'), [], [
        XmlElement(XmlName('a'), [], [XmlText('1  1')]),
        XmlElement(XmlName('b'), [], [XmlText('2  2')]),
      ]);
      element.normalize(collapseWhitespace: (node) => node.text == '2  2');
      expect(element.toXmlString(), '<element><a>1  1</a><b>2 2</b></element>');
    });
    test('document fragment', () {
      final fragment = XmlDocumentFragment([
        XmlText(''),
        XmlText('aaa'),
        XmlText(''),
        XmlElement(XmlName('element1')),
        XmlText(''),
        XmlText('bbb'),
        XmlText(''),
        XmlText('ccc'),
        XmlText(''),
        XmlElement(XmlName('element2')),
        XmlText(''),
        XmlText('ddd'),
        XmlText(''),
      ]);
      fragment.normalize();
      final element = XmlElement(XmlName('element'));
      element.children.add(fragment);
      expect(element.children.length, 5);
      expect(element.toXmlString(),
          '<element>aaa<element1/>bbbccc<element2/>ddd</element>');
    });
  });
  group('writer', () {
    final document = XmlDocument.parse('<body>\n'
        '  <a>\tWhat\r the  heck?\n</a>\n'
        '  <b>\tWhat\r the  heck?\n</b>\n'
        '</body>');
    test('default', () {
      final output = document.toXmlString();
      expect(
          output,
          '<body>\n'
          '  <a>\tWhat\r the  heck?\n</a>\n'
          '  <b>\tWhat\r the  heck?\n</b>\n'
          '</body>');
    });
    test('pretty', () {
      final output = document.toXmlString(pretty: true);
      expect(
          output,
          '<body>\n'
          '  <a>What the heck?</a>\n'
          '  <b>What the heck?</b>\n'
          '</body>');
    });
    test('indent', () {
      final output = document.toXmlString(pretty: true, indent: '\t');
      expect(
          output,
          '<body>\n'
          '\t<a>What the heck?</a>\n'
          '\t<b>What the heck?</b>\n'
          '</body>');
    });
    test('newline', () {
      final output = document.toXmlString(pretty: true, newLine: '\r\n');
      expect(
          output,
          '<body>\r\n'
          '  <a>What the heck?</a>\r\n'
          '  <b>What the heck?</b>\r\n'
          '</body>');
    });
    group('whitespace', () {
      test('preserve all', () {
        final output = document.toXmlString(
            pretty: true, preserveWhitespace: (node) => true);
        expect(
            output,
            '<body>\n'
            '  <a>\tWhat\r the  heck?\n</a>\n'
            '  <b>\tWhat\r the  heck?\n</b>\n'
            '</body>');
      });
      test('preserve some', () {
        final output = document.toXmlString(
            pretty: true,
            preserveWhitespace: (node) =>
                node is XmlElement && node.localName == 'b');
        expect(
            output,
            '<body>\n'
            '  <a>What the heck?</a>\n'
            '  <b>\tWhat\r the  heck?\n</b>\n'
            '</body>');
      });
      test('preserve nested', () {
        final input = XmlDocument.parse('<html><body>'
            '<p><b>bold</b>, <i>italic</i> and <b><i>both</i></b>.</p>'
            '</body></html>');
        final output = input.toXmlString(
            pretty: true,
            preserveWhitespace: (node) =>
                node is XmlElement && node.localName == 'p');
        expect(
            output,
            '<html>\n'
            '  <body>\n'
            '    <p><b>bold</b>, <i>italic</i> and <b><i>both</i></b>.</p>\n'
            '  </body>\n'
            '</html>');
      });
      test('normalize text', () {
        final input = XmlDocument([
          XmlElement(XmlName.fromString('contents'), [], [
            XmlText(' Hello '),
            XmlText('   '),
            XmlText(' World '),
            XmlText(' '),
          ])
        ]);
        final output = input.toXmlString(pretty: true);
        expect(output, '<contents>Hello World</contents>');
      });
    });
    group('attributes', () {
      const input = '<body>'
          '<a a="1">AAA</a>'
          '<b a="1" b="2">BBB</b>'
          '<c a="1" b="2" c="3">CCC</c>'
          '</body>';
      final document = XmlDocument.parse(input);
      tearDown(() => expect(document.toXmlString(), input,
          reason: 'Modified the original DOM.'));
      test('indent none', () {
        final output = document.toXmlString(
          pretty: true,
          indentAttribute: (node) => false,
        );
        expect(
            output,
            '<body>\n'
            '  <a a="1">AAA</a>\n'
            '  <b a="1" b="2">BBB</b>\n'
            '  <c a="1" b="2" c="3">CCC</c>\n'
            '</body>');
      });
      test('indent all', () {
        final output = document.toXmlString(
          pretty: true,
          indentAttribute: (node) => true,
        );
        expect(
            output,
            '<body>\n'
            '  <a\n'
            '    a="1">AAA</a>\n'
            '  <b\n'
            '    a="1"\n'
            '    b="2">BBB</b>\n'
            '  <c\n'
            '    a="1"\n'
            '    b="2"\n'
            '    c="3">CCC</c>\n'
            '</body>');
      });
      test('intend after first', () {
        final output = document.toXmlString(
          pretty: true,
          indentAttribute: (node) => node.parent!.attributes.first != node,
        );
        expect(
            output,
            '<body>\n'
            '  <a a="1">AAA</a>\n'
            '  <b a="1"\n'
            '    b="2">BBB</b>\n'
            '  <c a="1"\n'
            '    b="2"\n'
            '    c="3">CCC</c>\n'
            '</body>');
      });
      test('indent when multiple', () {
        final output = document.toXmlString(
          pretty: true,
          indentAttribute: (node) => node.parent!.attributes.length > 1,
        );
        expect(
            output,
            '<body>\n'
            '  <a a="1">AAA</a>\n'
            '  <b\n'
            '    a="1"\n'
            '    b="2">BBB</b>\n'
            '  <c\n'
            '    a="1"\n'
            '    b="2"\n'
            '    c="3">CCC</c>\n'
            '</body>');
      });
      test('indent every second', () {
        final output = document.toXmlString(
          pretty: true,
          indentAttribute: (node) {
            final index = node.parent!.attributes.indexOf(node);
            return index > 0 && index.isEven;
          },
        );
        expect(
            output,
            '<body>\n'
            '  <a a="1">AAA</a>\n'
            '  <b a="1" b="2">BBB</b>\n'
            '  <c a="1" b="2"\n'
            '    c="3">CCC</c>\n'
            '</body>');
      });
      test('no indent in preserve mode', () {
        final output = document.toXmlString(
          pretty: true,
          preserveWhitespace: (node) => true,
          indentAttribute: (node) => true,
        );
        expect(
            output,
            '<body>'
            '<a a="1">AAA</a>'
            '<b a="1" b="2">BBB</b>'
            '<c a="1" b="2" c="3">CCC</c>'
            '</body>');
      });
      test('sort reverse', () {
        final output = document.toXmlString(
          pretty: true,
          sortAttributes: (a, b) =>
              b.name.qualified.compareTo(a.name.qualified),
        );
        expect(
            output,
            '<body>\n'
            '  <a a="1">AAA</a>\n'
            '  <b b="2" a="1">BBB</b>\n'
            '  <c c="3" b="2" a="1">CCC</c>\n'
            '</body>');
      });
      test('sort reverse in preserve mode', () {
        final output = document.toXmlString(
          pretty: true,
          preserveWhitespace: (n) => true,
          sortAttributes: (a, b) =>
              b.name.qualified.compareTo(a.name.qualified),
        );
        expect(
            output,
            '<body>'
            '<a a="1">AAA</a>'
            '<b b="2" a="1">BBB</b>'
            '<c c="3" b="2" a="1">CCC</c>'
            '</body>');
      });
      test('insert space before self-closing', () {
        final element = XmlElement(
          XmlName('base'),
          [],
          [
            XmlElement(XmlName('simple')),
            XmlElement(
              XmlName('with-attributes'),
              [XmlAttribute(XmlName('attr'), 'val')],
            ),
            XmlElement(XmlName('do-not-add')),
          ],
        );

        final output = element.toXmlString(
          pretty: true,
          spaceBeforeSelfClose: (node) =>
              node is XmlElement && node.localName != 'do-not-add',
        );
        expect(
          output,
          '<base>\n'
          '  <simple />\n'
          '  <with-attributes attr="val" />\n'
          '  <do-not-add/>\n'
          '</base>',
        );
      });
    });
  });
}
