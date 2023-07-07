// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler_test;

import 'dart:convert';

import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';
import 'package:test/test.dart';

import 'testing.dart';

void testClass() {
  var errors = <Message>[];
  var input = '.foobar {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);

  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var selectorSeqs =
      ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;
  expect(selectorSeqs.length, 1);
  final simpSelector = selectorSeqs[0].simpleSelector;
  expect(simpSelector is ClassSelector, true);
  expect(selectorSeqs[0].isCombinatorNone, true);
  expect(simpSelector.name, 'foobar');
}

void testClass2() {
  var errors = <Message>[];
  var input = '.foobar .bar .no-story {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;
  expect(simpleSeqs.length, 3);

  var simpSelector0 = simpleSeqs[0].simpleSelector;
  expect(simpSelector0 is ClassSelector, true);
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector0.name, 'foobar');

  var simpSelector1 = simpleSeqs[1].simpleSelector;
  expect(simpSelector1 is ClassSelector, true);
  expect(simpleSeqs[1].isCombinatorDescendant, true);
  expect(simpSelector1.name, 'bar');

  var simpSelector2 = simpleSeqs[2].simpleSelector;
  expect(simpSelector2 is ClassSelector, true);
  expect(simpleSeqs[2].isCombinatorDescendant, true);
  expect(simpSelector2.name, 'no-story');
}

void testId() {
  var errors = <Message>[];
  var input = '#elemId {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 1);
  var simpSelector = simpleSeqs[0].simpleSelector;
  expect(simpSelector is IdSelector, true);
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector.name, 'elemId');
}

void testElement() {
  var errors = <Message>[];
  var input = 'div {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 1);

  final simpSelector = simpleSeqs[0].simpleSelector;
  expect(simpSelector is ElementSelector, true);
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector.name, 'div');

  input = 'div div span {}';
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 3);

  var simpSelector0 = simpleSeqs[0].simpleSelector;
  expect(simpSelector0 is ElementSelector, true);
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector0.name, 'div');

  var simpSelector1 = simpleSeqs[1].simpleSelector;
  expect(simpSelector1 is ElementSelector, true);
  expect(simpleSeqs[1].isCombinatorDescendant, true);
  expect(simpSelector1.name, 'div');

  var simpSelector2 = simpleSeqs[2].simpleSelector;
  expect(simpSelector2 is ElementSelector, true);
  expect(simpleSeqs[2].isCombinatorDescendant, true);
  expect(simpSelector2.name, 'span');
}

void testNamespace() {
  var errors = <Message>[];
  var input = 'ns1|div {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 1);
  expect(simpleSeqs[0].simpleSelector is NamespaceSelector, true);
  var simpSelector = simpleSeqs[0].simpleSelector as NamespaceSelector;
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector.isNamespaceWildcard, false);
  expect(simpSelector.namespace, 'ns1');
  var elementSelector = simpSelector.nameAsSimpleSelector;
  expect(elementSelector is ElementSelector, true);
  expect(elementSelector!.isWildcard, false);
  expect(elementSelector.name, 'div');
}

void testNamespace2() {
  var errors = <Message>[];
  var input = 'ns1|div div ns2|span .foobar {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 4);

  expect(simpleSeqs[0].simpleSelector is NamespaceSelector, true);
  var simpSelector0 = simpleSeqs[0].simpleSelector as NamespaceSelector;
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector0.namespace, 'ns1');
  var elementSelector0 = simpSelector0.nameAsSimpleSelector;
  expect(elementSelector0 is ElementSelector, true);
  expect(elementSelector0!.isWildcard, false);
  expect(elementSelector0.name, 'div');

  var simpSelector1 = simpleSeqs[1].simpleSelector;
  expect(simpSelector1 is ElementSelector, true);
  expect(simpleSeqs[1].isCombinatorDescendant, true);
  expect(simpSelector1.name, 'div');

  expect(simpleSeqs[2].simpleSelector is NamespaceSelector, true);
  var simpSelector2 = simpleSeqs[2].simpleSelector as NamespaceSelector;
  expect(simpleSeqs[2].isCombinatorDescendant, true);
  expect(simpSelector2.namespace, 'ns2');
  var elementSelector2 = simpSelector2.nameAsSimpleSelector;
  expect(elementSelector2 is ElementSelector, true);
  expect(elementSelector2!.isWildcard, false);
  expect(elementSelector2.name, 'span');

  var simpSelector3 = simpleSeqs[3].simpleSelector;
  expect(simpSelector3 is ClassSelector, true);
  expect(simpleSeqs[3].isCombinatorDescendant, true);
  expect(simpSelector3.name, 'foobar');
}

void testSelectorGroups() {
  var errors = <Message>[];
  var input =
      'div, .foobar ,#elemId, .xyzzy .test, ns1|div div #elemId .foobar {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 5);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var groupSelector0 = ruleset.selectorGroup!.selectors[0];
  expect(groupSelector0.simpleSelectorSequences.length, 1);
  var selector0 = groupSelector0.simpleSelectorSequences[0];
  var simpleSelector0 = selector0.simpleSelector;
  expect(simpleSelector0 is ElementSelector, true);
  expect(selector0.isCombinatorNone, true);
  expect(simpleSelector0.name, 'div');

  var groupSelector1 = ruleset.selectorGroup!.selectors[1];
  expect(groupSelector1.simpleSelectorSequences.length, 1);
  var selector1 = groupSelector1.simpleSelectorSequences[0];
  var simpleSelector1 = selector1.simpleSelector;
  expect(simpleSelector1 is ClassSelector, true);
  expect(selector1.isCombinatorNone, true);
  expect(simpleSelector1.name, 'foobar');

  var groupSelector2 = ruleset.selectorGroup!.selectors[2];
  expect(groupSelector2.simpleSelectorSequences.length, 1);
  var selector2 = groupSelector2.simpleSelectorSequences[0];
  var simpleSelector2 = selector2.simpleSelector;
  expect(simpleSelector2 is IdSelector, true);
  expect(selector2.isCombinatorNone, true);
  expect(simpleSelector2.name, 'elemId');

  var groupSelector3 = ruleset.selectorGroup!.selectors[3];
  expect(groupSelector3.simpleSelectorSequences.length, 2);

  var selector30 = groupSelector3.simpleSelectorSequences[0];
  var simpleSelector30 = selector30.simpleSelector;
  expect(simpleSelector30 is ClassSelector, true);
  expect(selector30.isCombinatorNone, true);
  expect(simpleSelector30.name, 'xyzzy');

  var selector31 = groupSelector3.simpleSelectorSequences[1];
  var simpleSelector31 = selector31.simpleSelector;
  expect(simpleSelector31 is ClassSelector, true);
  expect(selector31.isCombinatorDescendant, true);
  expect(simpleSelector31.name, 'test');

  var groupSelector4 = ruleset.selectorGroup!.selectors[4];
  expect(groupSelector4.simpleSelectorSequences.length, 4);

  var selector40 = groupSelector4.simpleSelectorSequences[0];
  expect(selector40.simpleSelector is NamespaceSelector, true);
  var simpleSelector40 = selector40.simpleSelector as NamespaceSelector;
  expect(selector40.isCombinatorNone, true);
  expect(simpleSelector40.namespace, 'ns1');
  var elementSelector = simpleSelector40.nameAsSimpleSelector;
  expect(elementSelector is ElementSelector, true);
  expect(elementSelector!.isWildcard, false);
  expect(elementSelector.name, 'div');

  var selector41 = groupSelector4.simpleSelectorSequences[1];
  var simpleSelector41 = selector41.simpleSelector;
  expect(simpleSelector41 is ElementSelector, true);
  expect(selector41.isCombinatorDescendant, true);
  expect(simpleSelector41.name, 'div');

  var selector42 = groupSelector4.simpleSelectorSequences[2];
  var simpleSelector42 = selector42.simpleSelector;
  expect(simpleSelector42 is IdSelector, true);
  expect(selector42.isCombinatorDescendant, true);
  expect(simpleSelector42.name, 'elemId');

  var selector43 = groupSelector4.simpleSelectorSequences[3];
  var simpleSelector43 = selector43.simpleSelector;
  expect(selector43.isCombinatorDescendant, true);
  expect(simpleSelector43.name, 'foobar');
}

void testCombinator() {
  var errors = <Message>[];
  var input = '.foobar > .bar + .no-story ~ myNs|div #elemId {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 5);

  var selector0 = simpleSeqs[0];
  var simpleSelector0 = selector0.simpleSelector;
  expect(simpleSelector0 is ClassSelector, true);
  expect(selector0.isCombinatorNone, true);
  expect(simpleSelector0.name, 'foobar');

  var selector1 = simpleSeqs[1];
  var simpleSelector1 = selector1.simpleSelector;
  expect(simpleSelector1 is ClassSelector, true);
  expect(selector1.isCombinatorGreater, true);
  expect(simpleSelector1.name, 'bar');

  var selector2 = simpleSeqs[2];
  var simpleSelector2 = selector2.simpleSelector;
  expect(simpleSelector2 is ClassSelector, true);
  expect(selector2.isCombinatorPlus, true);
  expect(simpleSelector2.name, 'no-story');

  var selector3 = simpleSeqs[3];
  expect(selector3.simpleSelector is NamespaceSelector, true);
  var simpleSelector3 = selector3.simpleSelector as NamespaceSelector;
  expect(selector3.isCombinatorTilde, true);
  expect(simpleSelector3.namespace, 'myNs');
  var elementSelector = simpleSelector3.nameAsSimpleSelector;
  expect(elementSelector is ElementSelector, true);
  expect(elementSelector!.isWildcard, false);
  expect(elementSelector.name, 'div');

  var selector4 = simpleSeqs[4];
  var simpleSelector4 = selector4.simpleSelector;
  expect(simpleSelector4 is IdSelector, true);
  expect(selector4.isCombinatorDescendant, true);
  expect(simpleSelector4.name, 'elemId');
}

void testWildcard() {
  var errors = <Message>[];
  var input = '* {}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  var ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  var simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 1);
  var simpSelector = simpleSeqs[0].simpleSelector;
  expect(simpSelector is ElementSelector, true);
  expect(simpleSeqs[0].isCombinatorNone, true);
  expect(simpSelector.isWildcard, true);
  expect(simpSelector.name, '*');

  input = '*.foobar {}';
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 2);

  {
    var selector0 = simpleSeqs[0];
    var simpleSelector0 = selector0.simpleSelector;
    expect(simpleSelector0 is ElementSelector, true);
    expect(selector0.isCombinatorNone, true);
    expect(simpleSelector0.isWildcard, true);
    expect(simpleSelector0.name, '*');
  }

  var selector1 = simpleSeqs[1];
  var simpleSelector1 = selector1.simpleSelector;
  expect(simpleSelector1 is ClassSelector, true);
  expect(selector1.isCombinatorNone, true);
  expect(simpleSelector1.name, 'foobar');

  input = 'myNs|*.foobar {}';
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels.length, 1);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 2);

  {
    var selector0 = simpleSeqs[0];
    expect(selector0.simpleSelector is NamespaceSelector, true);
    var simpleSelector0 = selector0.simpleSelector as NamespaceSelector;
    expect(selector0.isCombinatorNone, true);
    expect(simpleSelector0.isNamespaceWildcard, false);
    var elementSelector = simpleSelector0.nameAsSimpleSelector;
    expect('myNs', simpleSelector0.namespace);
    expect(elementSelector!.isWildcard, true);
    expect('*', elementSelector.name);
  }

  selector1 = simpleSeqs[1];
  simpleSelector1 = selector1.simpleSelector;
  expect(simpleSelector1 is ClassSelector, true);
  expect(selector1.isCombinatorNone, true);
  expect('foobar', simpleSelector1.name);

  input = '*|*.foobar {}';
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(stylesheet.topLevels[0] is RuleSet, true);
  ruleset = stylesheet.topLevels[0] as RuleSet;
  expect(ruleset.selectorGroup!.selectors.length, 1);
  expect(ruleset.declarationGroup.declarations.length, 0);

  simpleSeqs = ruleset.selectorGroup!.selectors[0].simpleSelectorSequences;

  expect(simpleSeqs.length, 2);

  {
    var selector0 = simpleSeqs[0];
    expect(selector0.simpleSelector is NamespaceSelector, true);
    var simpleSelector0 = selector0.simpleSelector as NamespaceSelector;
    expect(selector0.isCombinatorNone, true);
    expect(simpleSelector0.isNamespaceWildcard, true);
    expect('*', simpleSelector0.namespace);
    var elementSelector = simpleSelector0.nameAsSimpleSelector;
    expect(elementSelector!.isWildcard, true);
    expect('*', elementSelector.name);
  }

  selector1 = simpleSeqs[1];
  simpleSelector1 = selector1.simpleSelector;
  expect(simpleSelector1 is ClassSelector, true);
  expect(selector1.isCombinatorNone, true);
  expect('foobar', simpleSelector1.name);
}

/// Test List<int> as input to parser.
void testArrayOfChars() {
  var errors = <Message>[];
  var input = '<![CDATA[.foo { '
      'color: red; left: 20px; top: 20px; width: 100px; height:200px'
      '}'
      '#div {'
      'color : #00F578; border-color: #878787;'
      '}]]>';

  var stylesheet = parse(utf8.encode(input), errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  expect(prettyPrint(stylesheet), r'''
.foo {
  color: #f00;
  left: 20px;
  top: 20px;
  width: 100px;
  height: 200px;
}
#div {
  color: #00F578;
  border-color: #878787;
}''');
}

void testPseudo() {
  var errors = <Message>[];

  final input = r'''
html:lang(fr-ca) { quotes: '" ' ' "' }
zoom: { }

a:link { color: red }
:link  { color: blue }

a:focus { background: yellow }
a:focus:hover { background: white }

p.special:first-letter {color: #ffd800}

p:not(#example){
  background-color: yellow;
}

input:not([DISABLED]){
  background-color: yellow;
}

html|*:not(:link):not(:visited) {
  border: 1px solid black;
}

*:not(FOO) {
  height: 20px;
}

*|*:not(*) {
  color: orange;
}

*|*:not(:hover) {
  color: magenta;
}

p:nth-child(3n-3) { }

div:nth-child(2n) { color : red; }
''';

  var stylesheet = parseCss(input, errors: errors, opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), r'''
html:lang(fr-ca) {
  quotes: '" ' ' "';
}
zoom {
}
a:link {
  color: #f00;
}
:link {
  color: #00f;
}
a:focus {
  background: #ff0;
}
a:focus:hover {
  background: #fff;
}
p.special:first-letter {
  color: #ffd800;
}
p:not(#example) {
  background-color: #ff0;
}
input:not([DISABLED]) {
  background-color: #ff0;
}
html|*:not(:link):not(:visited) {
  border: 1px solid #000;
}
*:not(FOO) {
  height: 20px;
}
*|*:not(*) {
  color: #ffa500;
}
*|*:not(:hover) {
  color: #f0f;
}
p:nth-child(3n-3) {
}
div:nth-child(2n) {
  color: #f00;
}''');
}

void testAttribute() {
  // TODO(terry): Implement
}

void testNegation() {
  // TODO(terry): Implement
}

void testHost() {
  var errors = <Message>[];
  var input = '@host { '
      ':scope {'
      'white-space: nowrap;'
      'overflow-style: marquee-line;'
      'overflow-x: marquee;'
      '}'
      '* { color: red; }'
      '*:hover { font-weight: bold; }'
      ':nth-child(odd) { color: blue; }'
      '}';
  var stylesheet = parseCss(input, errors: errors, opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), r'''
@host {
:scope {
  white-space: nowrap;
  overflow-style: marquee-line;
  overflow-x: marquee;
}
* {
  color: #f00;
}
*:hover {
  font-weight: bold;
}
:nth-child(odd) {
  color: #00f;
}
}''');
}

void testStringEscape() {
  var errors = <Message>[];
  var input = r'''a { foo: '{"text" : "a\\\""}' }''';
  var stylesheet = parseCss(input, errors: errors, opts: simpleOptions);
  expect(errors.isEmpty, true, reason: errors.toString());

  expect(prettyPrint(stylesheet), r'''
a {
  foo: '{"text" : "a\\\""}';
}''');
}

// TODO(terry): Move to emitter_test.dart when real emitter exist.
void testEmitter() {
  var errors = <Message>[];
  var input = '.foo { '
      'color: red; left: 20px; top: 20px; width: 100px; height:200px'
      '}'
      '#div {'
      'color : #00F578; border-color: #878787;'
      '}';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(prettyPrint(stylesheet), r'''
.foo {
  color: #f00;
  left: 20px;
  top: 20px;
  width: 100px;
  height: 200px;
}
#div {
  color: #00F578;
  border-color: #878787;
}''');
}

void testExpressionParsing() {
  var errors = <Message>[];
  var input = r'''
.foobar {
  border-radius: calc(0 - 1px);
  border-width: calc(0 + 1px);
}''';
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  walkTree(stylesheet);

  expect(prettyPrint(stylesheet), r'''
.foobar {
  border-radius: calc(0 - 1px);
  border-width: calc(0 + 1px);
}''');
}

void main() {
  test('Classes', testClass);
  test('Classes 2', testClass2);
  test('Ids', testId);
  test('Elements', testElement);
  test('Namespace', testNamespace);
  test('Namespace 2', testNamespace2);
  test('Selector Groups', testSelectorGroups);
  test('Combinator', testCombinator);
  test('Wildcards', testWildcard);
  test('Pseudo', testPseudo);
  test('Attributes', testAttribute);
  test('Negation', testNegation);
  test('@host', testHost);
  test('stringEscape', testStringEscape);
  test('Parse List<int> as input', testArrayOfChars);
  test('Simple Emitter', testEmitter);
  test('Expression parsing', testExpressionParsing);
}
