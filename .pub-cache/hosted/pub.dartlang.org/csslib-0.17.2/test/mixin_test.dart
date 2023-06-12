// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_test;

import 'package:csslib/src/messages.dart';
import 'package:test/test.dart';

import 'testing.dart';

void compileAndValidate(String input, String generated) {
  var errors = <Message>[];
  var stylesheet = compileCss(input, errors: errors, opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void compilePolyfillAndValidate(String input, String generated) {
  var errors = <Message>[];
  var stylesheet = polyFillCompileCss(input, errors: errors, opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void topLevelMixin() {
  compileAndValidate(r'''
@mixin silly-links {
  a {
    color: blue;
    background-color: red;
  }
}

@include silly-links;
''', r'''
a {
  color: #00f;
  background-color: #f00;
}''');
}

void topLevelMixinTwoIncludes() {
  compileAndValidate(r'''
@mixin a {
  a {
    color: blue;
    background-color: red;
  }
}
@mixin b {
  span {
    color: black;
    background-color: orange;
  }
}
@include a;
@include b;
''', r'''
a {
  color: #00f;
  background-color: #f00;
}
span {
  color: #000;
  background-color: #ffa500;
}''');
}

/// Tests top-level mixins that includes another mixin.
void topLevelMixinMultiRulesets() {
  compileAndValidate(r'''
@mixin a {
  a {
    color: blue;
    background-color: red;
  }
}
@mixin b {
  #foo-id {
    border-top: 1px solid red;
    border-bottom: 2px solid green;
  }
}
@mixin c {
  span {
    color: black;
    background-color: orange;
  }
  @include b;
}
@include a;
@include c;
''', r'''
a {
  color: #00f;
  background-color: #f00;
}
span {
  color: #000;
  background-color: #ffa500;
}
#foo-id {
  border-top: 1px solid #f00;
  border-bottom: 2px solid #008000;
}''');
}

void topLevelMixinDeeplyNestedRulesets() {
  compileAndValidate(r'''
@mixin a {
  a {
    color: blue;
    background-color: red;
  }
}
@mixin b {
  #foo-id {
    border-top: 1px solid red;
    border-bottom: 2px solid green;
  }
}
@mixin f {
  #split-bar div {
    border: 1px solid lightgray;
  }
}
@mixin e {
  #split-bar:visited {
    color: gray;
  }
  @include f;
}
@mixin d {
  a:hover {
    cursor: arrow;
  }
  @include e
}
@mixin c {
  @include a;
  span {
    color: black;
    background-color: orange;
  }
  @include b;
  @include d;
}
@include c;
''', r'''
a {
  color: #00f;
  background-color: #f00;
}
span {
  color: #000;
  background-color: #ffa500;
}
#foo-id {
  border-top: 1px solid #f00;
  border-bottom: 2px solid #008000;
}
a:hover {
  cursor: arrow;
}
#split-bar:visited {
  color: #808080;
}
#split-bar div {
  border: 1px solid #d3d3d3;
}''');
}

/// Tests selector groups and other combinators.
void topLevelMixinSelectors() {
  compileAndValidate(r'''
@mixin a {
  a, b {
    color: blue;
    background-color: red;
  }
  div > span {
    color: black;
    background-color: orange;
  }
}

@include a;
''', r'''
a, b {
  color: #00f;
  background-color: #f00;
}
div > span {
  color: #000;
  background-color: #ffa500;
}''');
}

void declSimpleMixin() {
  compileAndValidate(r'''
@mixin div-border {
  border: 2px dashed red;
}
div {
  @include div-border;
}
''', r'''
div {
  border: 2px dashed #f00;
}''');
}

void declMixinTwoIncludes() {
  compileAndValidate(r'''
@mixin div-border {
  border: 2px dashed red;
}
@mixin div-color {
  color: blue;
}
div {
  @include div-border;
  @include div-color;
}
''', r'''
div {
  border: 2px dashed #f00;
  color: #00f;
}''');
}

void declMixinNestedIncludes() {
  compileAndValidate(r'''
@mixin div-border {
  border: 2px dashed red;
}
@mixin div-padding {
  padding: .5em;
}
@mixin div-margin {
  margin: 5px;
}
@mixin div-color {
  @include div-padding;
  color: blue;
  @include div-margin;
}
div {
  @include div-border;
  @include div-color;
}
''', r'''
div {
  border: 2px dashed #f00;
  padding: .5em;
  color: #00f;
  margin: 5px;
}''');
}

void declMixinDeeperNestedIncludes() {
  compileAndValidate(r'''
@mixin div-border {
  border: 2px dashed red;
}
@mixin div-padding {
  padding: .5em;
}
@mixin div-margin {
  margin: 5px;
}
@mixin div-color {
  @include div-padding;
  @include div-margin;
}
div {
  @include div-border;
  @include div-color;
}
''', r'''
div {
  border: 2px dashed #f00;
  padding: .5em;
  margin: 5px;
}''');
}

void mixinArg() {
  compileAndValidate(r'''
@mixin div-border-1 {
  border: 2px dashed red;
}
@mixin div-border-2() {
  border: 22px solid blue;
}
@mixin div-left(@dist) {
  margin-left: @dist;
}
@mixin div-right(var-margin) {
  margin-right: var(margin);
}
div-1 {
  @include div-left(10px);
  @include div-right(100px);
  @include div-border-1;
}
div-2 {
  @include div-left(20em);
  @include div-right(5in);
  @include div-border-2();
}
div-3 {
  @include div-border-1();
}
div-4 {
  @include div-border-2;
}
''', r'''
div-1 {
  margin-left: 10px;
  margin-right: 100px;
  border: 2px dashed #f00;
}
div-2 {
  margin-left: 20em;
  margin-right: 5in;
  border: 22px solid #00f;
}
div-3 {
  border: 2px dashed #f00;
}
div-4 {
  border: 22px solid #00f;
}''');
}

void mixinArgs() {
  compileAndValidate(r'''
@mixin box-shadow(@shadows...) {
  -moz-box-shadow: @shadows;
  -webkit-box-shadow: @shadows;
  box-shadow: var(shadows);
}

.shadows {
  @include box-shadow(0px 4px 5px #666, 2px 6px 10px #999);
}''', r'''
.shadowed {
  -moz-box-shadow: 0px 4px 5px #666, 2px 6px 10px #999;
  -webkit-box-shadow: 0px 4px 5px #666, 2px 6px 10px #999;
  box-shadow: 0px 4px 5px #666, 2px 6px 10px #999;
}
''');
}

void mixinManyArgs() {
  compileAndValidate(r'''
@mixin border(@border-values) {
  border: @border-values
}

.primary {
  @include border(3px solid green);
}
''', r'''
.primary {
  border: 3px solid #008000;
}''');

  compileAndValidate(r'''
@mixin setup(@border-color, @border-style, @border-size, @color) {
  border: @border-size @border-style @border-color;
  color: @color;
}

.primary {
  @include setup(red, solid, 5px, blue);
}
''', r'''
.primary {
  border: 5px solid #f00;
  color: #00f;
}''');

  // Test passing a declaration that is multiple parameters.
  compileAndValidate(r'''
@mixin colors(@text, @background, @border) {
  color: @text;
  background-color: @background;
  border-color: @border;
}

@values: #ff0000, #00ff00, #0000ff;
.primary {
  @include colors(@values);
}
''', r'''
var-values: #f00, #0f0, #00f;

.primary {
  color: #f00;
  background-color: #0f0;
  border-color: #00f;
}''');

  compilePolyfillAndValidate(r'''
@mixin colors(@text, @background, @border) {
  color: @text;
  background-color: @background;
  border-color: @border;
}

@values: #ff0000, #00ff00, #0000ff;
.primary {
  @include colors(@values);
}
''', r'''
.primary {
  color: #f00;
  background-color: #0f0;
  border-color: #00f;
}''');
}

void badDeclarationInclude() {
  final errors = <Message>[];
  final input = r'''
@mixin a {
  #foo-id {
    color: red;
  }
}
@mixin b {
  span {
    border: 2px dashed red;
    @include a;
  }
}
@include b;
''';

  compileCss(input, errors: errors, opts: options);

  expect(errors.isNotEmpty, true);
  expect(errors.length, 1, reason: errors.toString());
  var error = errors[0];
  expect(error.message, 'Using top-level mixin a as a declaration');
  expect(error.span!.start.line, 8);
  expect(error.span!.end.offset, 105);
}

void badTopInclude() {
  final errors = <Message>[];
  final input = r'''
@mixin b {
  color: red;
}

@mixin a {
  span {
    border: 2px dashed red;
  }
  @include b;
}

@include a;
  ''';

  compileCss(input, errors: errors, opts: options);

  expect(errors.length, 1, reason: errors.toString());
  var error = errors[0];
  expect(error.message, 'Using declaration mixin b as top-level mixin');
  expect(error.span!.start.line, 8);
  expect(error.span!.end.offset, 90);
}

void emptyMixin() {
  final errors = <Message>[];
  final input = r'''
@mixin a {
}
@mixin b {
  border: 2px dashed red;
  @include a;
}
div {
  @include b;
}
  ''';

  var generated = r'''
div {
  border: 2px dashed #f00;
}''';

  var stylesheet = compileCss(input, errors: errors, opts: options);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void undefinedTopLevel() {
  final errors = <Message>[];
  final input = r'''
@mixin a {
  @include b;
}
@mixin b {
  span {
    border: 2px dashed red;
  }
  @include a;
}

@include b;

  ''';

  compileCss(input, errors: errors, opts: options);

  expect(errors.isNotEmpty, true);
  expect(errors.length, 1, reason: errors.toString());
  var error = errors[0];
  expect(error.message, 'Undefined mixin b');
  expect(error.span!.start.line, 1);
  expect(error.span!.start.offset, 14);
}

void undefinedDeclaration() {
  final errors = <Message>[];
  final input = r'''
@mixin a {
  @include b;
}
@mixin b {
  border: 2px dashed red;
  @include a;
}
div {
  @include b;
}
  ''';

  compileCss(input, errors: errors, opts: options);

  expect(errors.isNotEmpty, true);
  expect(errors.length, 1, reason: errors.toString());
  var error = errors[0];
  expect(error.message, 'Undefined mixin b');
  expect(error.span!.start.line, 1);
  expect(error.span!.start.offset, 14);
}

void includeGrammar() {
  compileAndValidate(r'''
@mixin a {
  foo { color: red }
}

@mixin b {
  @include a;
  @include a;
}

@include b;
''', r'''
foo {
  color: #f00;
}
foo {
  color: #f00;
}''');

  compileAndValidate(r'''
@mixin a {
  color: red
}

foo {
  @include a;
  @include a
}
''', r'''
foo {
  color: #f00;
  color: #f00;
}''');

  var errors = <Message>[];
  var input = r'''
@mixin a {
  foo { color: red }
}

@mixin b {
  @include a
  @include a
}

@include b
''';

  compileCss(input, errors: errors, opts: options);

  expect(errors.isNotEmpty, true);
  expect(errors.length, 6, reason: errors.toString());
  var error = errors[0];
  expect(error.message, 'parsing error expected ;');
  expect(error.span!.start.line, 6);
  expect(error.span!.end.offset, 69);
  error = errors[1];
  expect(error.message, 'expected :, but found }');
  expect(error.span!.start.line, 7);
  expect(error.span!.end.offset, 73);
  error = errors[2];
  expect(error.message, 'parsing error expected }');
  expect(error.span!.start.line, 9);
  expect(error.span!.end.offset, 83);
  error = errors[3];
  expect(error.message, 'expected {, but found end of file()');
  expect(error.span!.start.line, 9);
  expect(error.span!.end.offset, 86);
  error = errors[4];
  expect(error.message, 'expected }, but found end of file()');
  expect(error.span!.start.line, 10);
  expect(error.span!.end.offset, 86);
  error = errors[5];
  expect(error.message, 'Using top-level mixin a as a declaration');
  expect(error.span!.start.line, 5);
  expect(error.span!.end.offset, 56);
}

void main() {
  group('Basic mixin', () {
    test('include grammar', includeGrammar);
    test('empty mixin content', emptyMixin);
  });

  group('Top-level mixin', () {
    test('simple mixin', topLevelMixin);
    test('mixin with two @includes', topLevelMixinTwoIncludes);
    test('multi rulesets', topLevelMixinMultiRulesets);
    test('multi rulesets and nesting', topLevelMixinDeeplyNestedRulesets);
    test('selector groups', topLevelMixinSelectors);
  });

  group('Declaration mixin', () {
    test('simple', declSimpleMixin);
    test('with two @includes', declMixinTwoIncludes);
    test('with includes', declMixinNestedIncludes);
    test('with deeper nesting', declMixinDeeperNestedIncludes);
  });

  group('Mixin arguments', () {
    test('simple arg', mixinArg);
    test('multiple args and var decls as args', mixinManyArgs);
  });

  group('Mixin warnings', () {
    test('undefined top-level', undefinedTopLevel);
    test('undefined declaration', undefinedDeclaration);
    test('detect bad top-level as declaration', badDeclarationInclude);
    test('detect bad declaration as top-level', badTopInclude);
  });
}
