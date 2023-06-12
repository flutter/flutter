/// Additional feature tests that aren't based on test data.
library parser_feature_test;

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html/src/constants.dart';
import 'package:html/src/encoding_parser.dart';
import 'package:html/src/treebuilder.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  _testElementSpans();
  test('doctype is cloneable', () {
    final doc = parse('<!doctype HTML>');
    final doctype = doc.nodes[0] as DocumentType;
    expect(doctype.clone(false).toString(), '<!DOCTYPE html>');
  });

  test('line counter', () {
    // http://groups.google.com/group/html5lib-discuss/browse_frm/thread/f4f00e4a2f26d5c0
    final doc = parse('<pre>\nx\n&gt;\n</pre>');
    expect(doc.body!.innerHtml, '<pre>x\n&gt;\n</pre>');
  });

  test('namespace html elements on', () {
    final doc = HtmlParser('', tree: TreeBuilder(true)).parse();
    expect((doc.nodes[0] as Element).namespaceUri, Namespaces.html);
  });

  test('namespace html elements off', () {
    final doc = HtmlParser('', tree: TreeBuilder(false)).parse();
    expect((doc.nodes[0] as Element).namespaceUri, null);
  });

  test('parse error spans - full', () {
    final parser = HtmlParser('''
<!DOCTYPE html>
<html>
  <body>
  <!DOCTYPE html>
  </body>
</html>
''', generateSpans: true, sourceUrl: 'ParseError');
    final doc = parser.parse();
    expect(doc.body!.outerHtml, '<body>\n  \n  \n\n</body>');
    expect(parser.errors.length, 1);
    final error = parser.errors[0];
    expect(error.errorCode, 'unexpected-doctype');

    // Note: these values are 0-based, but the printed format is 1-based.
    expect(error.span!.start.line, 3);
    expect(error.span!.end.line, 3);
    expect(error.span!.start.column, 2);
    expect(error.span!.end.column, 17);
    expect(error.span!.text, '<!DOCTYPE html>');

    expect(error.toString(), '''
On line 4, column 3 of ParseError: Unexpected DOCTYPE. Ignored.
  ╷
4 │   <!DOCTYPE html>
  │   ^^^^^^^^^^^^^^^
  ╵''');
  });

  test('parse error spans - minimal', () {
    final parser = HtmlParser('''
<!DOCTYPE html>
<html>
  <body>
  <!DOCTYPE html>
  </body>
</html>
''');
    final doc = parser.parse();
    expect(doc.body!.outerHtml, '<body>\n  \n  \n\n</body>');
    expect(parser.errors.length, 1);
    final error = parser.errors[0];
    expect(error.errorCode, 'unexpected-doctype');
    expect(error.span!.start.line, 3);
    // Note: error position is at the end, not the beginning
    expect(error.span!.start.column, 17);
  });

  test('text spans should have the correct length', () {
    final textContent = '\n  hello {{name}}';
    final html = '<body><div>$textContent</div>';
    final doc = parse(html, generateSpans: true);
    final text = doc.body!.nodes[0].nodes[0] as Text;
    expect(text, const TypeMatcher<Text>());
    expect(text.data, textContent);
    expect(text.sourceSpan!.start.offset, html.indexOf(textContent));
    expect(text.sourceSpan!.length, textContent.length);
  });

  test('attribute spans', () {
    final text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    final doc = parse(text, generateSpans: true);
    final elem = doc.querySelector('element')!;
    expect(elem.sourceSpan!.start.offset, 0);
    expect(elem.sourceSpan!.end.offset, text.length);
    expect(elem.sourceSpan!.text, text);

    expect(elem.attributeSpans!['quux'], null);

    final span = elem.attributeSpans!['extends']!;
    expect(span.start.offset, text.indexOf('extends'));
    expect(span.text, 'extends="x-bar"');
  });

  test('attribute value spans', () {
    final text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    final doc = parse(text, generateSpans: true);
    final elem = doc.querySelector('element')!;

    expect(elem.attributeValueSpans!['quux'], null);

    final span = elem.attributeValueSpans!['extends']!;
    expect(span.start.offset, text.indexOf('x-bar'));
    expect(span.text, 'x-bar');
  });

  test('attribute spans if no attributes', () {
    final text = '<element>';
    final doc = parse(text, generateSpans: true);
    final elem = doc.querySelector('element')!;

    expect(elem.attributeSpans!['quux'], null);
    expect(elem.attributeValueSpans!['quux'], null);
  });

  test('attribute spans if no attribute value', () {
    final text = '<foo template>';
    final doc = parse(text, generateSpans: true);
    final elem = doc.querySelector('foo')!;

    expect(elem.attributeSpans!['template']!.start.offset,
        text.indexOf('template'));
    expect(elem.attributeValueSpans!.containsKey('template'), false);
  });

  test('attribute spans null if code parsed without spans', () {
    final text = '<element name="x-foo" extends="x-bar" constructor="Foo">';
    final doc = parse(text);
    final elem = doc.querySelector('element')!;
    expect(elem.sourceSpan, null);
    expect(elem.attributeSpans!['quux'], null);
    expect(elem.attributeSpans!['extends'], null);
  });

  test('void element innerHTML', () {
    var doc = parse('<div></div>');
    expect(doc.body!.innerHtml, '<div></div>');
    doc = parse('<body><script></script></body>');
    expect(doc.body!.innerHtml, '<script></script>');
    doc = parse('<br>');
    expect(doc.body!.innerHtml, '<br>');
    doc = parse('<br><foo><bar>');
    expect(doc.body!.innerHtml, '<br><foo><bar></bar></foo>');
  });

  test('empty document has html, body, and head', () {
    final doc = parse('');
    final html = '<html><head></head><body></body></html>';
    expect(doc.outerHtml, html);
    expect(doc.documentElement!.outerHtml, html);
    expect(doc.head!.outerHtml, '<head></head>');
    expect(doc.body!.outerHtml, '<body></body>');
  });

  test('strange table case', () {
    final doc = parse('<table><tbody><foo>').body!;
    expect(doc.innerHtml, '<foo></foo><table><tbody></tbody></table>');
  });

  group('html serialization', () {
    test('attribute order', () {
      // Note: the spec only requires a stable order.
      // However, we preserve the input order via LinkedHashMap
      final body = parse('<foo d=1 a=2 c=3 b=4>').body!;
      expect(body.innerHtml, '<foo d="1" a="2" c="3" b="4"></foo>');
      expect(body.querySelector('foo')!.attributes.remove('a'), '2');
      expect(body.innerHtml, '<foo d="1" c="3" b="4"></foo>');
      body.querySelector('foo')!.attributes['a'] = '0';
      expect(body.innerHtml, '<foo d="1" c="3" b="4" a="0"></foo>');
    });

    test('escaping Text node in <script>', () {
      final e = parseFragment('<script>a && b</script>').firstChild as Element;
      expect(e.outerHtml, '<script>a && b</script>');
    });

    test('escaping Text node in <span>', () {
      final e = parseFragment('<span>a && b</span>').firstChild as Element;
      expect(e.outerHtml, '<span>a &amp;&amp; b</span>');
    });

    test('Escaping attributes', () {
      var e = parseFragment('<div class="a<b>">').firstChild as Element;
      expect(e.outerHtml, '<div class="a<b>"></div>');
      e = parseFragment('<div class=\'a"b\'>').firstChild as Element;
      expect(e.outerHtml, '<div class="a&quot;b"></div>');
    });

    test('Escaping non-breaking space', () {
      final text = '<span>foO\u00A0bar</span>';
      expect(text.codeUnitAt(text.indexOf('O') + 1), 0xA0);
      final e = parseFragment(text).firstChild as Element;
      expect(e.outerHtml, '<span>foO&nbsp;bar</span>');
    });

    test('Newline after <pre>', () {
      var e = parseFragment('<pre>\n\nsome text</span>').firstChild as Element;
      expect((e.firstChild as Text).data, '\nsome text');
      expect(e.outerHtml, '<pre>\n\nsome text</pre>');

      e = parseFragment('<pre>\nsome text</span>').firstChild as Element;
      expect((e.firstChild as Text).data, 'some text');
      expect(e.outerHtml, '<pre>some text</pre>');
    });

    test('xml namespaces', () {
      // Note: this is a nonsensical example, but it triggers the behavior
      // we're looking for with attribute names in foreign content.
      final doc = parse('''
        <body>
        <svg>
        <desc xlink:type="simple"
              xlink:href="http://example.com/logo.png"
              xlink:show="new"></desc>
      ''');
      final n = doc.querySelector('desc')!;
      final keys = n.attributes.keys.toList();
      expect(
          keys.first,
          isA<AttributeName>()
              .having((n) => n.prefix, 'prefix', 'xlink')
              .having((n) => n.namespace, 'namespace',
                  'http://www.w3.org/1999/xlink')
              .having((n) => n.name, 'name', 'type'));

      expect(
          n.outerHtml,
          '<desc xlink:type="simple" '
          'xlink:href="http://example.com/logo.png" xlink:show="new"></desc>');
    });
  });

  test('error printing without spans', () {
    final parser = HtmlParser('foo');
    final doc = parser.parse();
    expect(doc.body!.innerHtml, 'foo');
    expect(parser.errors.length, 1);
    expect(parser.errors[0].errorCode, 'expected-doctype-but-got-chars');
    expect(parser.errors[0].message,
        'Unexpected non-space characters. Expected DOCTYPE.');
    expect(
        parser.errors[0].toString(),
        'ParserError on line 1, column 4: Unexpected non-space characters. '
        'Expected DOCTYPE.\n'
        '  ╷\n'
        '1 │ foo\n'
        '  │    ^\n'
        '  ╵');
  });

  test('Element.text', () {
    final doc = parseFragment('<div>foo<div>bar</div>baz</div>');
    final e = doc.firstChild!;
    final text = e.firstChild!;
    expect((text as Text).data, 'foo');
    expect(e.text, 'foobarbaz');

    e.text = 'FOO';
    expect(e.nodes.length, 1);
    expect(e.firstChild, isNot(text), reason: 'should create a new tree');
    expect((e.firstChild as Text).data, 'FOO');
    expect(e.text, 'FOO');
  });

  test('Text.text', () {
    final doc = parseFragment('<div>foo<div>bar</div>baz</div>');
    final e = doc.firstChild!;
    final text = e.firstChild as Text;
    expect(text.data, 'foo');
    expect(text.text, 'foo');

    text.text = 'FOO';
    expect(text.data, 'FOO');
    expect(e.text, 'FOObarbaz');
    expect(text.text, 'FOO');
  });

  test('Comment.text', () {
    final doc = parseFragment('<div><!--foo-->bar</div>');
    final e = doc.firstChild!;
    final c = e.firstChild!;
    expect((c as Comment).data, 'foo');
    expect(c.text, 'foo');
    expect(e.text, 'bar');

    c.text = 'qux';
    expect(c.data, 'qux');
    expect(c.text, 'qux');
    expect(e.text, 'bar');
  });

  test('foreignObject end tag', () {
    final p = HtmlParser('''
<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg"
     version="1.1">
    <foreignObject width="320px" height="200px">
        <x-flow></x-flow>
    </foreignObject>
</svg>''');
    final doc = p.parseFragment();
    expect(p.errors, isEmpty);
    final svg = doc.querySelector('svg')!;
    expect(svg.children[0].children[0].localName, 'x-flow');
  });

  group('Encoding pre-parser', () {
    String? getEncoding(String s) => EncodingParser(s.codeUnits).getEncoding();

    test('gets encoding from meta charset', () {
      expect(getEncoding('<meta charset="utf-16">'), 'utf-16');
    });

    test('gets encoding from meta in head', () {
      expect(getEncoding('<head><meta charset="utf-16">'), 'utf-16');
    });

    test('skips comments', () {
      expect(getEncoding('<!--comment--><meta charset="utf-16">'), 'utf-16');
    });

    test('stops if no match', () {
      // missing closing tag
      expect(getEncoding('<meta charset="utf-16"'), null);
    });

    test('ignores whitespace', () {
      expect(getEncoding('  <meta charset="utf-16">'), 'utf-16');
    });

    test('parses content attr', () {
      expect(
          getEncoding(
              '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'),
          null);
    });
  });
}

void _testElementSpans() {
  void assertSpan(SourceSpan span, int offset, int end, String text) {
    expect(span, isNotNull);
    expect(span.start.offset, offset);
    expect(span.end.offset, end);
    expect(span.text, text);
  }

  group('element spans', () {
    test('html and body', () {
      final text = '<html><body>123</body></html>';
      final doc = parse(text, generateSpans: true);
      {
        final elem = doc.querySelector('html')!;
        assertSpan(elem.sourceSpan!, 0, 6, '<html>');
        assertSpan(elem.endSourceSpan!, 22, 29, '</html>');
      }
      {
        final elem = doc.querySelector('body')!;
        assertSpan(elem.sourceSpan!, 6, 12, '<body>');
        assertSpan(elem.endSourceSpan!, 15, 22, '</body>');
      }
    });

    test('normal', () {
      final text = '<div><element><span></span></element></div>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('element')!;
      assertSpan(elem.sourceSpan!, 5, 14, '<element>');
      assertSpan(elem.endSourceSpan!, 27, 37, '</element>');
    });

    test('block', () {
      final text = '<div>123</div>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('div')!;
      assertSpan(elem.sourceSpan!, 0, 5, '<div>');
      assertSpan(elem.endSourceSpan!, 8, 14, '</div>');
    });

    test('form', () {
      final text = '<form>123</form>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('form')!;
      assertSpan(elem.sourceSpan!, 0, 6, '<form>');
      assertSpan(elem.endSourceSpan!, 9, 16, '</form>');
    });

    test('p explicit end', () {
      final text = '<p>123</p>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('p')!;
      assertSpan(elem.sourceSpan!, 0, 3, '<p>');
      assertSpan(elem.endSourceSpan!, 6, 10, '</p>');
    });

    test('p implicit end', () {
      final text = '<div><p>123<p>456</div>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('p')!;
      assertSpan(elem.sourceSpan!, 5, 8, '<p>');
      expect(elem.endSourceSpan, isNull);
    });

    test('li', () {
      final text = '<li>123</li>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('li')!;
      assertSpan(elem.sourceSpan!, 0, 4, '<li>');
      assertSpan(elem.endSourceSpan!, 7, 12, '</li>');
    });

    test('heading', () {
      final text = '<h1>123</h1>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('h1')!;
      assertSpan(elem.sourceSpan!, 0, 4, '<h1>');
      assertSpan(elem.endSourceSpan!, 7, 12, '</h1>');
    });

    test('formatting', () {
      final text = '<b>123</b>';
      final doc = parse(text, generateSpans: true);
      final elem = doc.querySelector('b')!;
      assertSpan(elem.sourceSpan!, 0, 3, '<b>');
      assertSpan(elem.endSourceSpan!, 6, 10, '</b>');
    });

    test('table tbody', () {
      final text = '<table><tbody>  </tbody></table>';
      final doc = parse(text, generateSpans: true);
      {
        final elem = doc.querySelector('tbody')!;
        assertSpan(elem.sourceSpan!, 7, 14, '<tbody>');
        assertSpan(elem.endSourceSpan!, 16, 24, '</tbody>');
      }
    });

    test('table tr td', () {
      final text = '<table><tr><td>123</td></tr></table>';
      final doc = parse(text, generateSpans: true);
      {
        final elem = doc.querySelector('table')!;
        assertSpan(elem.sourceSpan!, 0, 7, '<table>');
        assertSpan(elem.endSourceSpan!, 28, 36, '</table>');
      }
      {
        final elem = doc.querySelector('tr')!;
        assertSpan(elem.sourceSpan!, 7, 11, '<tr>');
        assertSpan(elem.endSourceSpan!, 23, 28, '</tr>');
      }
      {
        final elem = doc.querySelector('td')!;
        assertSpan(elem.sourceSpan!, 11, 15, '<td>');
        assertSpan(elem.endSourceSpan!, 18, 23, '</td>');
      }
    });

    test('select optgroup option', () {
      final text = '<select><optgroup><option>123</option></optgroup></select>';
      final doc = parse(text, generateSpans: true);
      {
        final elem = doc.querySelector('select')!;
        assertSpan(elem.sourceSpan!, 0, 8, '<select>');
        assertSpan(elem.endSourceSpan!, 49, 58, '</select>');
      }
      {
        final elem = doc.querySelector('optgroup')!;
        assertSpan(elem.sourceSpan!, 8, 18, '<optgroup>');
        assertSpan(elem.endSourceSpan!, 38, 49, '</optgroup>');
      }
      {
        final elem = doc.querySelector('option')!;
        assertSpan(elem.sourceSpan!, 18, 26, '<option>');
        assertSpan(elem.endSourceSpan!, 29, 38, '</option>');
      }
    });
  });
}
