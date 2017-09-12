// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TestTree extends Object with DiagnosticableTreeMixin {
  TestTree({
    this.name,
    this.style,
    this.children: const <TestTree>[],
    this.properties: const <DiagnosticsNode>[],
  });

  final String name;
  final List<TestTree> children;
  final List<DiagnosticsNode> properties;
  final DiagnosticsTreeStyle style;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    for (TestTree child in this.children) {
      children.add(child.toDiagnosticsNode(
        name: 'child ${child.name}',
        style: child.style,
      ));
    }
    return children;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (style != null)
      properties.defaultDiagnosticsTreeStyle = style;

    for (DiagnosticsNode property in this.properties)
      properties.add(property);
  }
}

enum ExampleEnum {
  hello,
  world,
  deferToChild,
}

void main() {
  test('TreeDiagnosticsMixin control test', () async {
    void goldenStyleTest(String description,
        {DiagnosticsTreeStyle style,
        DiagnosticsTreeStyle lastChildStyle,
        String golden = ''}) {
      final TestTree tree = new TestTree(children: <TestTree>[
        new TestTree(name: 'node A', style: style),
        new TestTree(
          name: 'node B',
          children: <TestTree>[
            new TestTree(name: 'node B1', style: style),
            new TestTree(name: 'node B2', style: style),
            new TestTree(name: 'node B3', style: lastChildStyle ?? style),
          ],
          style: style,
        ),
        new TestTree(name: 'node C', style: lastChildStyle ?? style),
      ], style: lastChildStyle);

      expect(tree, hasAGoodToStringDeep);
      expect(
        tree.toDiagnosticsNode(style: style).toStringDeep(),
        equalsIgnoringHashCodes(golden),
        reason: description,
      );
    }

    goldenStyleTest(
      'dense',
      style: DiagnosticsTreeStyle.dense,
      golden:
      'TestTree#00000\n'
      '├child node A: TestTree#00000\n'
      '├child node B: TestTree#00000\n'
      '│├child node B1: TestTree#00000\n'
      '│├child node B2: TestTree#00000\n'
      '│└child node B3: TestTree#00000\n'
      '└child node C: TestTree#00000\n',
    );

    goldenStyleTest(
      'sparse',
      style: DiagnosticsTreeStyle.sparse,
      golden:
      'TestTree#00000\n'
      ' ├─child node A: TestTree#00000\n'
      ' ├─child node B: TestTree#00000\n'
      ' │ ├─child node B1: TestTree#00000\n'
      ' │ ├─child node B2: TestTree#00000\n'
      ' │ └─child node B3: TestTree#00000\n'
      ' └─child node C: TestTree#00000\n',
    );

    goldenStyleTest(
      'dashed',
      style: DiagnosticsTreeStyle.offstage,
      golden:
      'TestTree#00000\n'
      ' ╎╌child node A: TestTree#00000\n'
      ' ╎╌child node B: TestTree#00000\n'
      ' ╎ ╎╌child node B1: TestTree#00000\n'
      ' ╎ ╎╌child node B2: TestTree#00000\n'
      ' ╎ └╌child node B3: TestTree#00000\n'
      ' └╌child node C: TestTree#00000\n',
    );

    goldenStyleTest(
      'leaf children',
      style: DiagnosticsTreeStyle.sparse,
      lastChildStyle: DiagnosticsTreeStyle.transition,
      golden:
      'TestTree#00000\n'
      ' ├─child node A: TestTree#00000\n'
      ' ├─child node B: TestTree#00000\n'
      ' │ ├─child node B1: TestTree#00000\n'
      ' │ ├─child node B2: TestTree#00000\n'
      ' │ ╘═╦══ child node B3 ═══\n'
      ' │   ║ TestTree#00000\n'
      ' │   ╚═══════════\n'
      ' ╘═╦══ child node C ═══\n'
      '   ║ TestTree#00000\n'
      '   ╚═══════════\n',
    );

    // You would never really want to make everything a leaf child like this
    // but you can and still get a readable tree.
    // The joint between single and double lines here is a bit clunky
    // but we could correct that if there is any real use for this style.
    goldenStyleTest(
      'leaf',
      style: DiagnosticsTreeStyle.transition,
      golden:
      'TestTree#00000:\n'
      '  ╞═╦══ child node A ═══\n'
      '  │ ║ TestTree#00000\n'
      '  │ ╚═══════════\n'
      '  ╞═╦══ child node B ═══\n'
      '  │ ║ TestTree#00000:\n'
      '  │ ║   ╞═╦══ child node B1 ═══\n'
      '  │ ║   │ ║ TestTree#00000\n'
      '  │ ║   │ ╚═══════════\n'
      '  │ ║   ╞═╦══ child node B2 ═══\n'
      '  │ ║   │ ║ TestTree#00000\n'
      '  │ ║   │ ╚═══════════\n'
      '  │ ║   ╘═╦══ child node B3 ═══\n'
      '  │ ║     ║ TestTree#00000\n'
      '  │ ║     ╚═══════════\n'
      '  │ ╚═══════════\n'
      '  ╘═╦══ child node C ═══\n'
      '    ║ TestTree#00000\n'
      '    ╚═══════════\n',
    );

    goldenStyleTest(
      'whitespace',
      style: DiagnosticsTreeStyle.whitespace,
      golden:
      'TestTree#00000:\n'
      '  child node A: TestTree#00000\n'
      '  child node B: TestTree#00000:\n'
      '    child node B1: TestTree#00000\n'
      '    child node B2: TestTree#00000\n'
      '    child node B3: TestTree#00000\n'
      '  child node C: TestTree#00000\n',
    );

    // Single line mode does not display children.
    goldenStyleTest(
      'single line',
      style: DiagnosticsTreeStyle.singleLine,
      golden: 'TestTree#00000',
    );
  });

  test('TreeDiagnosticsMixin tree with properties test', () async {
    void goldenStyleTest(String description, {
      DiagnosticsTreeStyle style,
      DiagnosticsTreeStyle lastChildStyle,
      @required String golden,
    }) {
      final TestTree tree = new TestTree(
        properties: <DiagnosticsNode>[
          new StringProperty('stringProperty1', 'value1', quoted: false),
          new DoubleProperty('doubleProperty1', 42.5),
          new DoubleProperty('roundedProperty', 1.0 / 3.0),
          new StringProperty('DO_NOT_SHOW', 'DO_NOT_SHOW', level: DiagnosticLevel.hidden, quoted: false),
          new DiagnosticsProperty<Object>('DO_NOT_SHOW_NULL', null, defaultValue: null),
          new DiagnosticsProperty<Object>('nullProperty', null),
          new StringProperty('node_type', '<root node>', showName: false, quoted: false),
        ],
        children: <TestTree>[
          new TestTree(name: 'node A', style: style),
          new TestTree(
            name: 'node B',
            properties: <DiagnosticsNode>[
              new StringProperty('p1', 'v1', quoted: false),
              new StringProperty('p2', 'v2', quoted: false),
            ],
            children: <TestTree>[
              new TestTree(name: 'node B1', style: style),
              new TestTree(
                name: 'node B2',
                properties: <DiagnosticsNode>[new StringProperty('property1', 'value1', quoted: false)],
                style: style,
              ),
              new TestTree(
                name: 'node B3',
                properties: <DiagnosticsNode>[
                  new StringProperty('node_type', '<leaf node>', showName: false, quoted: false),
                  new IntProperty('foo', 42),
                ],
                style: lastChildStyle ?? style,
              ),
            ],
            style: style,
          ),
          new TestTree(
            name: 'node C',
            properties: <DiagnosticsNode>[
              new StringProperty('foo', 'multi\nline\nvalue!', quoted: false),
            ],
            style: lastChildStyle ?? style,
          ),
        ],
        style: lastChildStyle,
      );

      if (tree.style != DiagnosticsTreeStyle.singleLine)
        expect(tree, hasAGoodToStringDeep);

      expect(
        tree.toDiagnosticsNode(style: style).toStringDeep(),
        equalsIgnoringHashCodes(golden),
        reason: description,
      );
    }

    goldenStyleTest(
      'sparse',
      style: DiagnosticsTreeStyle.sparse,
      golden:
      'TestTree#00000\n'
      ' │ stringProperty1: value1\n'
      ' │ doubleProperty1: 42.5\n'
      ' │ roundedProperty: 0.3\n'
      ' │ nullProperty: null\n'
      ' │ <root node>\n'
      ' │\n'
      ' ├─child node A: TestTree#00000\n'
      ' ├─child node B: TestTree#00000\n'
      ' │ │ p1: v1\n'
      ' │ │ p2: v2\n'
      ' │ │\n'
      ' │ ├─child node B1: TestTree#00000\n'
      ' │ ├─child node B2: TestTree#00000\n'
      ' │ │   property1: value1\n'
      ' │ │\n'
      ' │ └─child node B3: TestTree#00000\n'
      ' │     <leaf node>\n'
      ' │     foo: 42\n'
      ' │\n'
      ' └─child node C: TestTree#00000\n'
      '     foo:\n'
      '     multi\n'
      '     line\n'
      '     value!\n',
    );

    goldenStyleTest(
      'dense',
      style: DiagnosticsTreeStyle.dense,
      golden:
        'TestTree#00000(stringProperty1: value1, doubleProperty1: 42.5, roundedProperty: 0.3, nullProperty: null, <root node>)\n'
        '├child node A: TestTree#00000\n'
        '├child node B: TestTree#00000(p1: v1, p2: v2)\n'
        '│├child node B1: TestTree#00000\n'
        '│├child node B2: TestTree#00000(property1: value1)\n'
        '│└child node B3: TestTree#00000(<leaf node>, foo: 42)\n'
        '└child node C: TestTree#00000(foo: multi\\nline\\nvalue!)\n',
    );

    goldenStyleTest(
      'dashed',
      style: DiagnosticsTreeStyle.offstage,
      golden:
      'TestTree#00000\n'
      ' │ stringProperty1: value1\n'
      ' │ doubleProperty1: 42.5\n'
      ' │ roundedProperty: 0.3\n'
      ' │ nullProperty: null\n'
      ' │ <root node>\n'
      ' │\n'
      ' ╎╌child node A: TestTree#00000\n'
      ' ╎╌child node B: TestTree#00000\n'
      ' ╎ │ p1: v1\n'
      ' ╎ │ p2: v2\n'
      ' ╎ │\n'
      ' ╎ ╎╌child node B1: TestTree#00000\n'
      ' ╎ ╎╌child node B2: TestTree#00000\n'
      ' ╎ ╎   property1: value1\n'
      ' ╎ ╎\n'
      ' ╎ └╌child node B3: TestTree#00000\n'
      ' ╎     <leaf node>\n'
      ' ╎     foo: 42\n'
      ' ╎\n'
      ' └╌child node C: TestTree#00000\n'
      '     foo:\n'
      '     multi\n'
      '     line\n'
      '     value!\n',
    );

    goldenStyleTest(
      'leaf children',
      style: DiagnosticsTreeStyle.sparse,
      lastChildStyle: DiagnosticsTreeStyle.transition,
      golden:
      'TestTree#00000\n'
      ' │ stringProperty1: value1\n'
      ' │ doubleProperty1: 42.5\n'
      ' │ roundedProperty: 0.3\n'
      ' │ nullProperty: null\n'
      ' │ <root node>\n'
      ' │\n'
      ' ├─child node A: TestTree#00000\n'
      ' ├─child node B: TestTree#00000\n'
      ' │ │ p1: v1\n'
      ' │ │ p2: v2\n'
      ' │ │\n'
      ' │ ├─child node B1: TestTree#00000\n'
      ' │ ├─child node B2: TestTree#00000\n'
      ' │ │   property1: value1\n'
      ' │ │\n'
      ' │ ╘═╦══ child node B3 ═══\n'
      ' │   ║ TestTree#00000:\n'
      ' │   ║   <leaf node>\n'
      ' │   ║   foo: 42\n'
      ' │   ╚═══════════\n'
      ' ╘═╦══ child node C ═══\n'
      '   ║ TestTree#00000:\n'
      '   ║   foo:\n'
      '   ║   multi\n'
      '   ║   line\n'
      '   ║   value!\n'
      '   ╚═══════════\n',
    );

    // You would never really want to make everything a transition child like
    // this but you can and still get a readable tree.
    goldenStyleTest(
      'transition',
      style: DiagnosticsTreeStyle.transition,
      golden:
      'TestTree#00000:\n'
      '  stringProperty1: value1\n'
      '  doubleProperty1: 42.5\n'
      '  roundedProperty: 0.3\n'
      '  nullProperty: null\n'
      '  <root node>\n'
      '  ╞═╦══ child node A ═══\n'
      '  │ ║ TestTree#00000\n'
      '  │ ╚═══════════\n'
      '  ╞═╦══ child node B ═══\n'
      '  │ ║ TestTree#00000:\n'
      '  │ ║   p1: v1\n'
      '  │ ║   p2: v2\n'
      '  │ ║   ╞═╦══ child node B1 ═══\n'
      '  │ ║   │ ║ TestTree#00000\n'
      '  │ ║   │ ╚═══════════\n'
      '  │ ║   ╞═╦══ child node B2 ═══\n'
      '  │ ║   │ ║ TestTree#00000:\n'
      '  │ ║   │ ║   property1: value1\n'
      '  │ ║   │ ╚═══════════\n'
      '  │ ║   ╘═╦══ child node B3 ═══\n'
      '  │ ║     ║ TestTree#00000:\n'
      '  │ ║     ║   <leaf node>\n'
      '  │ ║     ║   foo: 42\n'
      '  │ ║     ╚═══════════\n'
      '  │ ╚═══════════\n'
      '  ╘═╦══ child node C ═══\n'
      '    ║ TestTree#00000:\n'
      '    ║   foo:\n'
      '    ║   multi\n'
      '    ║   line\n'
      '    ║   value!\n'
      '    ╚═══════════\n',
    );

    goldenStyleTest(
      'whitespace',
      style: DiagnosticsTreeStyle.whitespace,
      golden:
        'TestTree#00000:\n'
        '  stringProperty1: value1\n'
        '  doubleProperty1: 42.5\n'
        '  roundedProperty: 0.3\n'
        '  nullProperty: null\n'
        '  <root node>\n'
        '  child node A: TestTree#00000\n'
        '  child node B: TestTree#00000:\n'
        '    p1: v1\n'
        '    p2: v2\n'
        '    child node B1: TestTree#00000\n'
        '    child node B2: TestTree#00000:\n'
        '      property1: value1\n'
        '    child node B3: TestTree#00000:\n'
        '      <leaf node>\n'
        '      foo: 42\n'
        '  child node C: TestTree#00000:\n'
        '    foo:\n'
        '    multi\n'
        '    line\n'
        '    value!\n',
    );

    // Single line mode does not display children.
    goldenStyleTest(
      'single line',
      style: DiagnosticsTreeStyle.singleLine,
      golden: 'TestTree#00000(stringProperty1: value1, doubleProperty1: 42.5, roundedProperty: 0.3, nullProperty: null, <root node>)',
    );

    // There isn't anything interesting for this case as the children look the
    // same with and without children. TODO(jacobr): this is an ugly test case.
    // only difference is odd not clearly desirable density of B3 being right
    // next to node C.
    goldenStyleTest(
      'single line last child',
      style: DiagnosticsTreeStyle.sparse,
      lastChildStyle: DiagnosticsTreeStyle.singleLine,
      golden:
      'TestTree#00000\n'
      ' │ stringProperty1: value1\n'
      ' │ doubleProperty1: 42.5\n'
      ' │ roundedProperty: 0.3\n'
      ' │ nullProperty: null\n'
      ' │ <root node>\n'
      ' │\n'
      ' ├─child node A: TestTree#00000\n'
      ' ├─child node B: TestTree#00000\n'
      ' │ │ p1: v1\n'
      ' │ │ p2: v2\n'
      ' │ │\n'
      ' │ ├─child node B1: TestTree#00000\n'
      ' │ ├─child node B2: TestTree#00000\n'
      ' │ │   property1: value1\n'
      ' │ │\n'
      ' │ └─child node B3: TestTree#00000(<leaf node>, foo: 42)\n'
      ' └─child node C: TestTree#00000(foo: multi\\nline\\nvalue!)\n',
    );
  });

  test('transition test', () {
    // Test multiple styles integrating together in the same tree due to using
    // transition to go between styles that would otherwise be incompatible.
    final TestTree tree = new TestTree(
      style: DiagnosticsTreeStyle.sparse,
      properties: <DiagnosticsNode>[
        new StringProperty('stringProperty1', 'value1'),
      ],
      children: <TestTree>[
        new TestTree(
          style: DiagnosticsTreeStyle.transition,
          name: 'node transition',
          properties: <DiagnosticsNode>[
            new StringProperty('p1', 'v1'),
            new TestTree(
              properties: <DiagnosticsNode>[
                new DiagnosticsProperty<bool>('survived', true),
              ],
            ).toDiagnosticsNode(name: 'tree property', style: DiagnosticsTreeStyle.whitespace),
          ],
          children: <TestTree>[
            new TestTree(name: 'dense child', style: DiagnosticsTreeStyle.dense),
            new TestTree(
              name: 'dense',
              properties: <DiagnosticsNode>[new StringProperty('property1', 'value1')],
              style: DiagnosticsTreeStyle.dense,
            ),
            new TestTree(
              name: 'node B3',
              properties: <DiagnosticsNode>[
                new StringProperty('node_type', '<leaf node>', showName: false, quoted: false),
                new IntProperty('foo', 42),
              ],
              style: DiagnosticsTreeStyle.dense
            ),
          ],
        ),
        new TestTree(
          name: 'node C',
          properties: <DiagnosticsNode>[
            new StringProperty('foo', 'multi\nline\nvalue!', quoted: false),
          ],
          style: DiagnosticsTreeStyle.sparse,
        ),
      ],
    );

    expect(tree, hasAGoodToStringDeep);
    expect(
      tree.toDiagnosticsNode().toStringDeep(),
      equalsIgnoringHashCodes(
        'TestTree#00000\n'
        ' │ stringProperty1: "value1"\n'
        ' ╞═╦══ child node transition ═══\n'
        ' │ ║ TestTree#00000:\n'
        ' │ ║   p1: "v1"\n'
        ' │ ║   tree property: TestTree#00000:\n'
        ' │ ║     survived: true\n'
        ' │ ║   ├child dense child: TestTree#00000\n'
        ' │ ║   ├child dense: TestTree#00000(property1: "value1")\n'
        ' │ ║   └child node B3: TestTree#00000(<leaf node>, foo: 42)\n'
        ' │ ╚═══════════\n'
        ' └─child node C: TestTree#00000\n'
        '     foo:\n'
        '     multi\n'
        '     line\n'
        '     value!\n',
      ),
    );
  });

  test('describeEnum test', () {
    expect(describeEnum(ExampleEnum.hello), equals('hello'));
    expect(describeEnum(ExampleEnum.world), equals('world'));
    expect(describeEnum(ExampleEnum.deferToChild), equals('deferToChild'));
  });

  test('toHyphenedName test', () {
    expect(camelCaseToHyphenatedName(''), equals(''));
    expect(camelCaseToHyphenatedName('hello'), equals('hello'));
    expect(camelCaseToHyphenatedName('Hello'), equals('hello'));
    expect(camelCaseToHyphenatedName('HELLO'), equals('h-e-l-l-o'));
    expect(camelCaseToHyphenatedName('deferToChild'), equals('defer-to-child'));
    expect(camelCaseToHyphenatedName('DeferToChild'), equals('defer-to-child'));
    expect(camelCaseToHyphenatedName('helloWorld'), equals('hello-world'));
  });

  test('string property test', () {
    expect(
      new StringProperty('name', 'value', quoted: false).toString(),
      equals('name: value'),
    );

    expect(
      new StringProperty(
        'name',
        'value',
        description: 'VALUE',
        ifEmpty: '<hidden>',
        quoted: false,
      ).toString(),
      equals('name: VALUE'),
    );

    expect(
      new StringProperty(
        'name',
        'value',
        showName: false,
        ifEmpty: '<hidden>',
        quoted: false,
      ).toString(),
      equals('value'),
    );

    expect(
      new StringProperty('name', '', ifEmpty: '<hidden>').toString(),
      equals('name: <hidden>'),
    );

    expect(
      new StringProperty(
        'name',
        '',
        ifEmpty: '<hidden>',
        showName: false,
      ).toString(),
      equals('<hidden>'),
    );

    expect(new StringProperty('name', null).isFiltered(DiagnosticLevel.info), isFalse);
    expect(new StringProperty('name', 'value', level: DiagnosticLevel.hidden).isFiltered(DiagnosticLevel.info), isTrue);
    expect(new StringProperty('name', null, defaultValue: null).isFiltered(DiagnosticLevel.info), isTrue);
    expect(
      new StringProperty(
        'name',
        'value',
        quoted: true,
      ).toString(),
      equals('name: "value"'),
    );

    expect(
      new StringProperty('name', 'value', showName: false).toString(),
      equals('"value"'),
    );

    expect(
      new StringProperty(
        'name',
        null,
        showName: false,
        quoted: true,
      ).toString(),
      equals('null'),
    );
  });

  test('bool property test', () {
    final DiagnosticsProperty<bool> trueProperty = new DiagnosticsProperty<bool>('name', true);
    final DiagnosticsProperty<bool> falseProperty = new DiagnosticsProperty<bool>('name', false);
    expect(trueProperty.toString(), equals('name: true'));
    expect(trueProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(trueProperty.value, isTrue);
    expect(falseProperty.toString(), equals('name: false'));
    expect(falseProperty.value, isFalse);
    expect(falseProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(
      new DiagnosticsProperty<bool>(
        'name',
        true,
        description: 'truthy',
      ).toString(),
      equals('name: truthy'),
    );
    expect(
      new DiagnosticsProperty<bool>('name', true, showName: false).toString(),
      equals('true'),
    );

    expect(new DiagnosticsProperty<bool>('name', null).isFiltered(DiagnosticLevel.info), isFalse);
    expect(new DiagnosticsProperty<bool>('name', true, level: DiagnosticLevel.hidden).isFiltered(DiagnosticLevel.info), isTrue);
    expect(new DiagnosticsProperty<bool>('name', null, defaultValue: null).isFiltered(DiagnosticLevel.info), isTrue);
    expect(
      new DiagnosticsProperty<bool>('name', null, ifNull: 'missing').toString(),
      equals('name: missing'),
    );
  });

  test('flag property test', () {
    final FlagProperty trueFlag = new FlagProperty(
      'myFlag',
      value: true,
      ifTrue: 'myFlag',
    );
    final FlagProperty falseFlag = new FlagProperty(
      'myFlag',
      value: false,
      ifTrue: 'myFlag',
    );
    expect(trueFlag.toString(), equals('myFlag'));

    expect(trueFlag.value, isTrue);
    expect(falseFlag.value, isFalse);

    expect(trueFlag.isFiltered(DiagnosticLevel.fine), isFalse);
    expect(falseFlag.isFiltered(DiagnosticLevel.fine), isTrue);
  });

  test('property with tooltip test', () {
    final DiagnosticsProperty<String> withTooltip = new DiagnosticsProperty<String>(
      'name',
      'value',
      tooltip: 'tooltip',
    );
    expect(
     withTooltip.toString(),
      equals('name: value (tooltip)'),
    );
    expect(withTooltip.value, equals('value'));
    expect(withTooltip.isFiltered(DiagnosticLevel.fine), isFalse);
  });

  test('double property test', () {
    final DoubleProperty doubleProperty = new DoubleProperty(
      'name',
      42.0,
    );
    expect(doubleProperty.toString(), equals('name: 42.0'));
    expect(doubleProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(doubleProperty.value, equals(42.0));

    expect(new DoubleProperty('name', 1.3333).toString(), equals('name: 1.3'));

    expect(new DoubleProperty('name', null).toString(), equals('name: null'));
    expect(new DoubleProperty('name', null).isFiltered(DiagnosticLevel.info), equals(false));

    expect(
      new DoubleProperty('name', null, ifNull: 'missing').toString(),
      equals('name: missing'),
    );

    expect(
      new DoubleProperty('name', 42.0, unit: 'px',
      ).toString(),
      equals('name: 42.0px'),
    );
  });


  test('unsafe double property test', () {
    final DoubleProperty safe = new DoubleProperty.lazy(
      'name',
        () => 42.0,
    );
    expect(safe.toString(), equals('name: 42.0'));
    expect(safe.isFiltered(DiagnosticLevel.info), isFalse);
    expect(safe.value, equals(42.0));

    expect(
      new DoubleProperty.lazy('name', () => 1.3333).toString(),
      equals('name: 1.3'),
    );

    expect(
      new DoubleProperty.lazy('name', () => null).toString(),
      equals('name: null'),
    );
    expect(
      new DoubleProperty.lazy('name', () => null).isFiltered(DiagnosticLevel.info),
      equals(false),
    );

    final DoubleProperty throwingProperty = new DoubleProperty.lazy(
      'name',
      () => throw new FlutterError('Invalid constraints'),
    );
    // TODO(jacobr): it would be better if throwingProperty.object threw an
    // exception.
    expect(throwingProperty.value, isNull);
    expect(throwingProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(
      throwingProperty.toString(),
      equals('name: EXCEPTION (FlutterError)'),
    );
    expect(throwingProperty.level, equals(DiagnosticLevel.error));
  });

  test('percent property', () {
    expect(
      new PercentProperty('name', 0.4).toString(),
      equals('name: 40.0%'),
    );

    expect(
      new PercentProperty('name', 0.99, unit: 'invisible', tooltip: 'almost transparent').toString(),
      equals('name: 99.0% invisible (almost transparent)'),
    );

    expect(
      new PercentProperty('name', null, unit: 'invisible', tooltip: '!').toString(),
      equals('name: null (!)'),
    );

    expect(
      new PercentProperty('name', 0.4).value,
      0.4,
    );
    expect(
      new PercentProperty('name', 0.0).toString(),
      equals('name: 0.0%'),
    );
    expect(
      new PercentProperty('name', -10.0).toString(),
      equals('name: 0.0%'),
    );
    expect(
      new PercentProperty('name', 1.0).toString(),
      equals('name: 100.0%'),
    );
    expect(
      new PercentProperty('name', 3.0).toString(),
      equals('name: 100.0%'),
    );
    expect(
      new PercentProperty('name', null).toString(),
      equals('name: null'),
    );
    expect(
      new PercentProperty(
        'name',
        null,
        ifNull: 'missing',
      ).toString(),
      equals('name: missing'),
    );
    expect(
      new PercentProperty(
        'name',
        null,
        ifNull: 'missing',
        showName: false,
      ).toString(),
      equals('missing'),
    );
    expect(
      new PercentProperty(
        'name',
        0.5,
        showName: false,
      ).toString(),
      equals('50.0%'),
    );
  });

  test('callback property test', () {
    final Function onClick = () {};
    final ObjectFlagProperty<Function> present = new ObjectFlagProperty<Function>(
      'onClick',
      onClick,
      ifPresent: 'clickable',
    );
    final ObjectFlagProperty<Function> missing = new ObjectFlagProperty<Function>(
      'onClick',
      null,
      ifPresent: 'clickable',
    );

    expect(present.toString(), equals('clickable'));
    expect(present.isFiltered(DiagnosticLevel.info), isFalse);
    expect(present.value, equals(onClick));
    expect(missing.toString(), equals('onClick: null'));
    expect(missing.isFiltered(DiagnosticLevel.fine), isTrue);
  });

  test('missing callback property test', () {
    final Function onClick = () {};
    final ObjectFlagProperty<Function> present = new ObjectFlagProperty<Function>(
      'onClick',
      onClick,
      ifNull: 'disabled',
    );
    final ObjectFlagProperty<Function> missing = new ObjectFlagProperty<Function>(
      'onClick',
      null,
      ifNull: 'disabled',
    );

    expect(present.toString(), equals('onClick: Closure: () => dynamic'));
    expect(present.isFiltered(DiagnosticLevel.fine), isTrue);
    expect(present.value, equals(onClick));
    expect(missing.toString(), equals('disabled'));
    expect(missing.isFiltered(DiagnosticLevel.info), isFalse);
  });

  test('describe bool property', () {
    final FlagProperty yes = new FlagProperty(
      'name',
      value: true,
      ifTrue: 'YES',
      ifFalse: 'NO',
      showName: true,
    );
    final FlagProperty no = new FlagProperty(
      'name',
      value: false,
      ifTrue: 'YES',
      ifFalse: 'NO',
      showName: true,
    );
    expect(yes.toString(), equals('name: YES'));
    expect(yes.level, equals(DiagnosticLevel.info));
    expect(yes.value, isTrue);
    expect(no.toString(), equals('name: NO'));
    expect(no.level, equals(DiagnosticLevel.info));
    expect(no.value, isFalse);

    expect(
      new FlagProperty(
        'name',
        value: true,
        ifTrue: 'YES',
        ifFalse: 'NO',
      ).toString(),
      equals('YES'),
    );

    expect(
      new FlagProperty(
        'name',
        value: false,
        ifTrue: 'YES',
        ifFalse: 'NO',
      ).toString(),
      equals('NO'),
    );

    expect(
      new FlagProperty(
        'name',
        value: true,
        ifTrue: 'YES',
        ifFalse: 'NO',
        level: DiagnosticLevel.hidden,
        showName: true,
      ).level,
      equals(DiagnosticLevel.hidden),
    );
  });

  test('enum property test', () {
    final EnumProperty<ExampleEnum> hello = new EnumProperty<ExampleEnum>(
      'name',
      ExampleEnum.hello,
    );
    final EnumProperty<ExampleEnum> world = new EnumProperty<ExampleEnum>(
      'name',
      ExampleEnum.world,
    );
    final EnumProperty<ExampleEnum> deferToChild = new EnumProperty<ExampleEnum>(
      'name',
      ExampleEnum.deferToChild,
    );
    final EnumProperty<ExampleEnum> nullEnum = new EnumProperty<ExampleEnum>(
      'name',
      null,
    );
    expect(hello.level, equals(DiagnosticLevel.info));
    expect(hello.value, equals(ExampleEnum.hello));
    expect(hello.toString(), equals('name: hello'));

    expect(world.level, equals(DiagnosticLevel.info));
    expect(world.value, equals(ExampleEnum.world));
    expect(world.toString(), equals('name: world'));

    expect(deferToChild.level, equals(DiagnosticLevel.info));
    expect(deferToChild.value, equals(ExampleEnum.deferToChild));
    expect(deferToChild.toString(), equals('name: defer-to-child'));

    expect(nullEnum.level, equals(DiagnosticLevel.info));
    expect(nullEnum.value, isNull);
    expect(nullEnum.toString(), equals('name: null'));

    final EnumProperty<ExampleEnum> matchesDefault = new EnumProperty<ExampleEnum>(
      'name',
      ExampleEnum.hello,
      defaultValue: ExampleEnum.hello,
    );
    expect(matchesDefault.toString(), equals('name: hello'));
    expect(matchesDefault.value, equals(ExampleEnum.hello));
    expect(matchesDefault.isFiltered(DiagnosticLevel.info), isTrue);


    expect(
      new EnumProperty<ExampleEnum>(
        'name',
        ExampleEnum.hello,
        level: DiagnosticLevel.hidden,
      ).level,
      equals(DiagnosticLevel.hidden),
    );
  });

  test('int property test', () {
    final IntProperty regular = new IntProperty(
      'name',
      42,
    );
    expect(regular.toString(), equals('name: 42'));
    expect(regular.value, equals(42));
    expect(regular.level, equals(DiagnosticLevel.info));

    final IntProperty nullValue = new IntProperty(
      'name',
      null,
    );
    expect(nullValue.toString(), equals('name: null'));
    expect(nullValue.value, isNull);
    expect(nullValue.level, equals(DiagnosticLevel.info));

    final IntProperty hideNull = new IntProperty(
      'name',
      null,
      defaultValue: null,
    );
    expect(hideNull.toString(), equals('name: null'));
    expect(hideNull.value, isNull);
    expect(hideNull.isFiltered(DiagnosticLevel.info), isTrue);

    final IntProperty nullDescription = new IntProperty(
      'name',
      null,
      ifNull: 'missing',
    );
    expect(nullDescription.toString(), equals('name: missing'));
    expect(nullDescription.value, isNull);
    expect(nullDescription.level, equals(DiagnosticLevel.info));

    final IntProperty hideName = new IntProperty(
      'name',
      42,
      showName: false,
    );
    expect(hideName.toString(), equals('42'));
    expect(hideName.value, equals(42));
    expect(hideName.level, equals(DiagnosticLevel.info));

    final IntProperty withUnit = new IntProperty(
      'name',
      42,
      unit: 'pt',
    );
    expect(withUnit.toString(), equals('name: 42pt'));
    expect(withUnit.value, equals(42));
    expect(withUnit.level, equals(DiagnosticLevel.info));

    final IntProperty defaultValue = new IntProperty(
      'name',
      42,
      defaultValue: 42,
    );
    expect(defaultValue.toString(), equals('name: 42'));
    expect(defaultValue.value, equals(42));
    expect(defaultValue.isFiltered(DiagnosticLevel.info), isTrue);

    final IntProperty notDefaultValue = new IntProperty(
      'name',
      43,
      defaultValue: 42,
    );
    expect(notDefaultValue.toString(), equals('name: 43'));
    expect(notDefaultValue.value, equals(43));
    expect(notDefaultValue.level, equals(DiagnosticLevel.info));

    final IntProperty hidden = new IntProperty(
      'name',
      42,
      level: DiagnosticLevel.hidden,
    );
    expect(hidden.toString(), equals('name: 42'));
    expect(hidden.value, equals(42));
    expect(hidden.level, equals(DiagnosticLevel.hidden));
  });

  test('object property test', () {
    final Rect rect = new Rect.fromLTRB(0.0, 0.0, 20.0, 20.0);
    final DiagnosticsNode simple = new DiagnosticsProperty<Rect>(
      'name',
      rect,
    );
    expect(simple.value, equals(rect));
    expect(simple.level, equals(DiagnosticLevel.info));
    expect(simple.toString(), equals('name: Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)'));

    final DiagnosticsNode withDescription = new DiagnosticsProperty<Rect>(
      'name',
      rect,
      description: 'small rect',
    );
    expect(withDescription.value, equals(rect));
    expect(withDescription.level, equals(DiagnosticLevel.info));
    expect(withDescription.toString(), equals('name: small rect'));

    final DiagnosticsProperty<Object> nullProperty = new DiagnosticsProperty<Object>(
      'name',
      null,
    );
    expect(nullProperty.value, isNull);
    expect(nullProperty.level, equals(DiagnosticLevel.info));
    expect(nullProperty.toString(), equals('name: null'));

    final DiagnosticsProperty<Object> hideNullProperty = new DiagnosticsProperty<Object>(
      'name',
      null,
      defaultValue: null,
    );
    expect(hideNullProperty.value, isNull);
    expect(hideNullProperty.isFiltered(DiagnosticLevel.info), isTrue);
    expect(hideNullProperty.toString(), equals('name: null'));

    final DiagnosticsNode nullDescription = new DiagnosticsProperty<Object>(
      'name',
      null,
      ifNull: 'missing',
    );
    expect(nullDescription.value, isNull);
    expect(nullDescription.level, equals(DiagnosticLevel.info));
    expect(nullDescription.toString(), equals('name: missing'));

    final DiagnosticsProperty<Rect> hideName = new DiagnosticsProperty<Rect>(
      'name',
      rect,
      showName: false,
      level: DiagnosticLevel.warning
    );
    expect(hideName.value, equals(rect));
    expect(hideName.level, equals(DiagnosticLevel.warning));
    expect(hideName.toString(), equals('Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)'));

    final DiagnosticsProperty<Rect> hideSeparator = new DiagnosticsProperty<Rect>(
      'Creator',
      rect,
      showSeparator: false,
    );
    expect(hideSeparator.value, equals(rect));
    expect(hideSeparator.level, equals(DiagnosticLevel.info));
    expect(
      hideSeparator.toString(),
      equals('Creator Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)'),
    );
  });

  test('lazy object property test', () {
    final Rect rect = new Rect.fromLTRB(0.0, 0.0, 20.0, 20.0);
    final DiagnosticsNode simple = new DiagnosticsProperty<Rect>.lazy(
      'name',
      () => rect,
      description: 'small rect',
    );
    expect(simple.value, equals(rect));
    expect(simple.level, equals(DiagnosticLevel.info));
    expect(simple.toString(), equals('name: small rect'));

    final DiagnosticsNode nullProperty = new DiagnosticsProperty<Object>.lazy(
      'name',
      () => null,
      description: 'missing',
    );
    expect(nullProperty.value, isNull);
    expect(nullProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(nullProperty.toString(), equals('name: missing'));

    final DiagnosticsNode hideNullProperty = new DiagnosticsProperty<Object>.lazy(
      'name',
      () => null,
      description: 'missing',
      defaultValue: null,
    );
    expect(hideNullProperty.value, isNull);
    expect(hideNullProperty.isFiltered(DiagnosticLevel.info), isTrue);
    expect(hideNullProperty.toString(), equals('name: missing'));

    final DiagnosticsNode hideName = new DiagnosticsProperty<Rect>.lazy(
      'name',
      () => rect,
      description: 'small rect',
      showName: false,
    );
    expect(hideName.value, equals(rect));
    expect(hideName.isFiltered(DiagnosticLevel.info), isFalse);
    expect(hideName.toString(), equals('small rect'));

    final DiagnosticsProperty<Object> throwingWithDescription = new DiagnosticsProperty<Object>.lazy(
      'name',
      () => throw new FlutterError('Property not available'),
      description: 'missing',
      defaultValue: null,
    );
    expect(throwingWithDescription.value, isNull);
    expect(throwingWithDescription.exception, isFlutterError);
    expect(throwingWithDescription.isFiltered(DiagnosticLevel.info), false);
    expect(throwingWithDescription.toString(), equals('name: missing'));

    final DiagnosticsProperty<Object> throwingProperty = new DiagnosticsProperty<Object>.lazy(
      'name',
      () => throw new FlutterError('Property not available'),
      defaultValue: null,
    );
    expect(throwingProperty.value, isNull);
    expect(throwingProperty.exception, isFlutterError);
    expect(throwingProperty.isFiltered(DiagnosticLevel.info), false);
    expect(throwingProperty.toString(), equals('name: EXCEPTION (FlutterError)'));

  });

  test('color property test', () {
    // Add more tests if colorProperty becomes more than a wrapper around
    // objectProperty.
    final Color color = const Color.fromARGB(255, 255, 255, 255);
    final DiagnosticsProperty<Color> simple = new DiagnosticsProperty<Color>(
      'name',
      color,
    );
    expect(simple.isFiltered(DiagnosticLevel.info), isFalse);
    expect(simple.value, equals(color));
    expect(simple.toString(), equals('name: Color(0xffffffff)'));
  });

  test('flag property test', () {
    final FlagProperty show = new FlagProperty(
      'wasLayout',
      value: true,
      ifTrue: 'layout computed',
    );
    expect(show.name, equals('wasLayout'));
    expect(show.value, isTrue);
    expect(show.isFiltered(DiagnosticLevel.info), isFalse);
    expect(show.toString(), equals('layout computed'));

    final FlagProperty hide = new FlagProperty(
      'wasLayout',
      value: false,
      ifTrue: 'layout computed',
    );
    expect(hide.name, equals('wasLayout'));
    expect(hide.value, isFalse);
    expect(hide.level, equals(DiagnosticLevel.hidden));
    expect(hide.toString(), equals('wasLayout: false'));

    final FlagProperty hideTrue = new FlagProperty(
      'wasLayout',
      value: true,
      ifFalse: 'no layout computed',
    );
    expect(hideTrue.name, equals('wasLayout'));
    expect(hideTrue.value, isTrue);
    expect(hideTrue.level, equals(DiagnosticLevel.hidden));
    expect(hideTrue.toString(), equals('wasLayout: true'));
  });

  test('has property test', () {
    final Function onClick = () {};
    final ObjectFlagProperty<Function> has = new ObjectFlagProperty<Function>.has(
      'onClick',
      onClick,
    );
    expect(has.name, equals('onClick'));
    expect(has.value, equals(onClick));
    expect(has.isFiltered(DiagnosticLevel.info), isFalse);
    expect(has.toString(), equals('has onClick'));

    final ObjectFlagProperty<Function> missing = new ObjectFlagProperty<Function>.has(
      'onClick',
      null,
    );
    expect(missing.name, equals('onClick'));
    expect(missing.value, isNull);
    expect(missing.isFiltered(DiagnosticLevel.info), isTrue);
    expect(missing.toString(), equals('onClick: null'));
  });

  test('iterable property test', () {
    final List<int> ints = <int>[1,2,3];
    final IterableProperty<int> intsProperty = new IterableProperty<int>(
      'ints',
      ints,
    );
    expect(intsProperty.value, equals(ints));
    expect(intsProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(intsProperty.toString(), equals('ints: 1, 2, 3'));

    final IterableProperty<Object> emptyProperty = new IterableProperty<Object>(
      'name',
      <Object>[],
    );
    expect(emptyProperty.value, isEmpty);
    expect(emptyProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(emptyProperty.toString(), equals('name: []'));

    final IterableProperty<Object> nullProperty = new IterableProperty<Object>(
      'list',
      null,
    );
    expect(nullProperty.value, isNull);
    expect(nullProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(nullProperty.toString(), equals('list: null'));

    final IterableProperty<Object> hideNullProperty = new IterableProperty<Object>(
      'list',
      null,
      defaultValue: null,
    );
    expect(hideNullProperty.value, isNull);
    expect(hideNullProperty.isFiltered(DiagnosticLevel.info), isTrue);
    expect(hideNullProperty.level, equals(DiagnosticLevel.fine));
    expect(hideNullProperty.toString(), equals('list: null'));

    final List<Object> objects = <Object>[
      new Rect.fromLTRB(0.0, 0.0, 20.0, 20.0),
      const Color.fromARGB(255, 255, 255, 255),
    ];
    final IterableProperty<Object> objectsProperty = new IterableProperty<Object>(
      'objects',
      objects,
    );
    expect(objectsProperty.value, equals(objects));
    expect(objectsProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(
      objectsProperty.toString(),
      equals('objects: Rect.fromLTRB(0.0, 0.0, 20.0, 20.0), Color(0xffffffff)'),
    );

    final IterableProperty<Object> multiLineProperty = new IterableProperty<Object>(
      'objects',
      objects,
      style: DiagnosticsTreeStyle.whitespace,
    );
    expect(multiLineProperty.value, equals(objects));
    expect(multiLineProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(
      multiLineProperty.toString(),
      equals(
        'objects:\n'
        'Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)\n'
        'Color(0xffffffff)',
      ),
    );
    expect(
      multiLineProperty.toStringDeep(),
      equals(
        'objects:\n'
        '  Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)\n'
        '  Color(0xffffffff)\n',
      ),
    );

    expect(
      new TestTree(
        properties: <DiagnosticsNode>[multiLineProperty],
      ).toStringDeep(),
      equalsIgnoringHashCodes(
        'TestTree#00000\n'
        '   objects:\n'
        '     Rect.fromLTRB(0.0, 0.0, 20.0, 20.0)\n'
        '     Color(0xffffffff)\n',
      ),
    );

    expect(
      new TestTree(
        properties: <DiagnosticsNode>[objectsProperty, new IntProperty('foo', 42)],
        style: DiagnosticsTreeStyle.singleLine,
      ).toStringDeep(),
      equalsIgnoringHashCodes(
        'TestTree#00000(objects: [Rect.fromLTRB(0.0, 0.0, 20.0, 20.0), Color(0xffffffff)], foo: 42)',
      ),
    );

    // Iterable with a single entry. Verify that rendering is sensible and that
    // multi line rendering isn't used even though it is not helpful.
    final List<Object> singleElementList = <Object>[const Color.fromARGB(255, 255, 255, 255)];

    final IterableProperty<Object> objectProperty = new IterableProperty<Object>(
      'object',
      singleElementList,
      style: DiagnosticsTreeStyle.whitespace,
    );
    expect(objectProperty.value, equals(singleElementList));
    expect(objectProperty.isFiltered(DiagnosticLevel.info), isFalse);
    expect(
      objectProperty.toString(),
      equals('object: Color(0xffffffff)'),
    );
    expect(
      objectProperty.toStringDeep(),
      equals('object: Color(0xffffffff)\n'),
    );
    expect(
      new TestTree(
        name: 'root',
        properties: <DiagnosticsNode>[objectProperty],
      ).toStringDeep(),
      equalsIgnoringHashCodes(
        'TestTree#00000\n'
        '   object: Color(0xffffffff)\n',
      ),
    );
  });

  test('message test', () {
    final DiagnosticsNode message = new DiagnosticsNode.message('hello world');
    expect(message.toString(), equals('hello world'));
    expect(message.name, isEmpty);
    expect(message.value, isNull);
    expect(message.showName, isFalse);

    final DiagnosticsNode messageProperty = new MessageProperty('diagnostics', 'hello world');
    expect(messageProperty.toString(), equals('diagnostics: hello world'));
    expect(messageProperty.name, equals('diagnostics'));
    expect(messageProperty.value, isNull);
    expect(messageProperty.showName, isTrue);

  });
}
