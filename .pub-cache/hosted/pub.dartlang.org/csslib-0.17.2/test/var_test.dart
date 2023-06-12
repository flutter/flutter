// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library var_test;

import 'package:csslib/src/messages.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;
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

void simpleVar() {
  final input = '''
:root {
  var-color-background: red;
  var-color-foreground: blue;

  var-c: #00ff00;
  var-b: var(c);
  var-a: var(b);
  var-level-1-normal: 1px;
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
  border-radius: var(level-1-normal);
}
''';

  final generated = '''
:root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-c: #0f0;
  var-b: var(c);
  var-a: var(b);
  var-level-1-normal: 1px;
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
  border-radius: var(level-1-normal);
}''';

  final generatedPolyfill = '''
:root {
}
.testIt {
  color: #00f;
  background: #f00;
  border-radius: 1px;
}''';

  compileAndValidate(input, generated);
  compilePolyfillAndValidate(input, generatedPolyfill);
}

void expressionsVar() {
  final input = '''
:root {
  var-color-background: red;
  var-color-foreground: blue;

  var-c: #00ff00;
  var-b: var(c);
  var-a: var(b);

  var-image: url(test.png);

  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30EM;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10Px;
  var-rgba: rgba(10,20,255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}

.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);

  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);

  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}

@font-face {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}

@font-face {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}

.foobar {
    grid-columns: var(grid-columns);
}
''';

  final generated = '''
:root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-c: #0f0;
  var-b: var(c);
  var-a: var(b);
  var-image: url("test.png");
  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30em;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10px;
  var-rgba: rgba(10, 20, 255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}
.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);
  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);
  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}
@font-face  {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}
@font-face  {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}
.foobar {
  grid-columns: var(grid-columns);
}''';

  compileAndValidate(input, generated);

  var generatedPolyfill = r'''
:root {
}
.testIt {
  color: #00f;
  background: #0f0;
  background-image: url("test.png");
  border-width: 20cm;
  margin-width: 33%;
  border-height: 30em;
  width: .6in;
  length: 1.2in;
  -web-stuff: -10px;
  background-color: rgba(10, 20, 255);
  transition: color 0.4s;
  transform: rotate(20deg);
  content: "✔";
  text-shadow: 0 -1px 0 #bfbfbf;
}
@font-face  {
  font-family: Gentium;
  src: url("http://example.com/fonts/Gentium.ttf");
  unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
}
@font-face  {
  font-family: Gentium;
  src: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  unicode-range: U+0A-FF, U+980-9FF, U+????, U+3???;
}
.foobar {
  grid-columns: 10px ("content" 1fr 10px) [4];
}''';

  compilePolyfillAndValidate(input, generatedPolyfill);
}

void defaultVar() {
  final input = '''
:root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b, #0a0);
  var-b: var(c, #0b0);
  var-c: #00ff00;

  var-image: url(test.png);

  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30EM;
}

.test {
  background-color: var(test, orange);
}

body {
  background: var(a) var(image) no-repeat right top;
}

div {
  background: var(color-background) url('img_tree.png') no-repeat right top;
}

.test-2 {
  background: var(color-background) var(image-2, url('img_1.png'))
              no-repeat right top;
}

.test-3 {
  background: var(color-background) var(image) no-repeat right top;
}

.test-4 {
  background: #ffff00 var(image) no-repeat right top;
}

.test-5 {
  background: var(test-color, var(a)) var(image) no-repeat right top;
}

.test-6 {
  border: red var(a-1, solid 20px);
}
''';

  final generated = '''
:root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b, #0a0);
  var-b: var(c, #0b0);
  var-c: #0f0;
  var-image: url("test.png");
  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30em;
}
.test {
  background-color: var(test, #ffa500);
}
body {
  background: var(a) var(image) no-repeat right top;
}
div {
  background: var(color-background) url("img_tree.png") no-repeat right top;
}
.test-2 {
  background: var(color-background) var(image-2, url("img_1.png")) no-repeat right top;
}
.test-3 {
  background: var(color-background) var(image) no-repeat right top;
}
.test-4 {
  background: #ff0 var(image) no-repeat right top;
}
.test-5 {
  background: var(test-color, var(a)) var(image) no-repeat right top;
}
.test-6 {
  border: #f00 var(a-1, solid 20px);
}''';

  compileAndValidate(input, generated);

  var generatedPolyfill = r'''
:root {
}
.test {
  background-color: #ffa500;
}
body {
  background: #0a0 url("test.png") no-repeat right top;
}
div {
  background: #f00 url("img_tree.png") no-repeat right top;
}
.test-2 {
  background: #f00 url("img_1.png") no-repeat right top;
}
.test-3 {
  background: #f00 url("test.png") no-repeat right top;
}
.test-4 {
  background: #ff0 url("test.png") no-repeat right top;
}
.test-5 {
  background: #0a0 url("test.png") no-repeat right top;
}
.test-6 {
  border: #f00 solid 20px;
}''';

  compilePolyfillAndValidate(input, generatedPolyfill);
}

void undefinedVars() {
  final errors = <Message>[];
  final input = '''
:root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b);
  var-b: var(c);
  var-c: #00ff00;

  var-one: var(two);
  var-two: var(one);

  var-four: var(five);
  var-five: var(six);
  var-six: var(four);

  var-def-1: var(def-2);
  var-def-2: var(def-3);
  var-def-3: var(def-2);
}

.testIt {
  color: var(color-foreground);
  background: var(color-background);
}
.test-1 {
  color: var(c);
}
.test-2 {
  color: var(one);
  background: var(six);
}
''';

  final generatedPolyfill = '''
:root {
}
.testIt {
  color: #00f;
  background: #f00;
}
.test-1 {
  color: #0f0;
}
.test-2 {
  color: ;
  background: ;
}''';

  var errorStrings = [
    'error on line 5, column 14: Variable is not defined.\n'
        '  ,\n'
        '5 |   var-a: var(b);\n'
        '  |              ^^\n'
        '  \'',
    'error on line 6, column 14: Variable is not defined.\n'
        '  ,\n'
        '6 |   var-b: var(c);\n'
        '  |              ^^\n'
        '  \'',
    'error on line 9, column 16: Variable is not defined.\n'
        '  ,\n'
        '9 |   var-one: var(two);\n'
        '  |                ^^^^\n'
        '  \'',
    'error on line 12, column 17: Variable is not defined.\n'
        '   ,\n'
        '12 |   var-four: var(five);\n'
        '   |                 ^^^^^\n'
        '   \'',
    'error on line 13, column 17: Variable is not defined.\n'
        '   ,\n'
        '13 |   var-five: var(six);\n'
        '   |                 ^^^^\n'
        '   \'',
    'error on line 16, column 18: Variable is not defined.\n'
        '   ,\n'
        '16 |   var-def-1: var(def-2);\n'
        '   |                  ^^^^^^\n'
        '   \'',
    'error on line 17, column 18: Variable is not defined.\n'
        '   ,\n'
        '17 |   var-def-2: var(def-3);\n'
        '   |                  ^^^^^^\n'
        '   \'',
  ];

  var generated = r'''
:root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b);
  var-b: var(c);
  var-c: #0f0;
  var-one: var(two);
  var-two: var(one);
  var-four: var(five);
  var-five: var(six);
  var-six: var(four);
  var-def-1: var(def-2);
  var-def-2: var(def-3);
  var-def-3: var(def-2);
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
}
.test-1 {
  color: var(c);
}
.test-2 {
  color: var(one);
  background: var(six);
}''';
  var testBitMap = 0;

  compileAndValidate(input, generated);

  var stylesheet =
      polyFillCompileCss(input, errors: errors..clear(), opts: options);

  expect(errors.length, errorStrings.length, reason: errors.toString());
  testBitMap = 0;

  outer:
  for (var error in errors) {
    var errorString = error.toString();
    for (var i = 0; i < errorStrings.length; i++) {
      if (errorString == errorStrings[i]) {
        testBitMap |= 1 << i;
        continue outer;
      }
    }
    fail('Unexpected error string: $errorString');
  }
  expect(testBitMap, equals((1 << errorStrings.length) - 1));
  expect(prettyPrint(stylesheet), generatedPolyfill);
}

void parserVar() {
  final input = '''
:root {
  var-color-background: red;
  var-color-foreground: blue;

  var-c: #00ff00;
  var-b: var(c);
  var-a: var(b);

  var-image: url(test.png);

  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30EM;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10Px;
  var-rgba: rgba(10,20,255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}

.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);

  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);

  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}

@font-face {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}

@font-face {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}

.foobar {
    grid-columns: var(grid-columns);
}
''';

  final generated = '''
:root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-c: #0f0;
  var-b: var(c);
  var-a: var(b);
  var-image: url("test.png");
  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30em;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10px;
  var-rgba: rgba(10, 20, 255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}
.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);
  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);
  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}
@font-face  {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}
@font-face  {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}
.foobar {
  grid-columns: var(grid-columns);
}''';

  compileAndValidate(input, generated);

  var generatedPolyfill = r'''
:root {
}
.testIt {
  color: #00f;
  background: #0f0;
  background-image: url("test.png");
  border-width: 20cm;
  margin-width: 33%;
  border-height: 30em;
  width: .6in;
  length: 1.2in;
  -web-stuff: -10px;
  background-color: rgba(10, 20, 255);
  transition: color 0.4s;
  transform: rotate(20deg);
  content: "✔";
  text-shadow: 0 -1px 0 #bfbfbf;
}
@font-face  {
  font-family: Gentium;
  src: url("http://example.com/fonts/Gentium.ttf");
  unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
}
@font-face  {
  font-family: Gentium;
  src: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  unicode-range: U+0A-FF, U+980-9FF, U+????, U+3???;
}
.foobar {
  grid-columns: 10px ("content" 1fr 10px) [4];
}''';
  compilePolyfillAndValidate(input, generatedPolyfill);
}

void testVar() {
  final errors = <Message>[];
  final input = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}
''';
  final generated = '''
var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  var stylesheet = parseCss(input, errors: errors, opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  compileAndValidate(input, generated);

  final input2 = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: @color-background;
  color: @color-foreground;
}
''';
  final generated2 = '''
var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  stylesheet = parseCss(input, errors: errors..clear(), opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);

  compileAndValidate(input2, generated2);
}

void testLess() {
  final errors = <Message>[];
  final input = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}
''';
  final generated = '''
var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  var stylesheet = parseCss(input, errors: errors, opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  compileAndValidate(input, generated);

  final input2 = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: @color-background;
  color: @color-foreground;
}
''';
  final generated2 = '''
var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  stylesheet = parseCss(input, errors: errors..clear(), opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);

  compileAndValidate(input2, generated2);
}

void polyfill() {
  compilePolyfillAndValidate(r'''
@color-background: red;
@color-foreground: blue;
.test {
  background-color: @color-background;
  color: @color-foreground;
}''', r'''
.test {
  background-color: #f00;
  color: #00f;
}''');
}

void testIndirects() {
  compilePolyfillAndValidate('''
:root {
  var-redef: #0f0;

  var-a1: #fff;
  var-a2: var(a1);
  var-a3: var(a2);

  var-redef: #000;
}
.test {
  background-color: @a1;
  color: @a2;
  border-color: @a3;
}
.test-1 {
  color: @redef;
}''', r'''
:root {
}
.test {
  background-color: #fff;
  color: #fff;
  border-color: #fff;
}
.test-1 {
  color: #000;
}''');
}

void includes() {
  var errors = <Message>[];
  var file1Input = r'''
:root {
  var-redef: #0f0;

  var-a1: #fff;
  var-a2: var(a1);
  var-a3: var(a2);

  var-redef: #000;
}
.test-1 {
  background-color: @a1;
  color: @a2;
  border-color: @a3;
}
.test-1a {
  color: @redef;
}
''';

  var file2Input = r'''
:root {
  var-redef: #0b0;
  var-b3: var(a3);
}
.test-2 {
  color: var(b3);
  background-color: var(redef);
  border-color: var(a3);
}
''';

  var input = r'''
:root {
  var-redef: #0c0;
}
.test-main {
  color: var(b3);
  background-color: var(redef);
  border-color: var(a3);
}
''';

  var generated1 = r'''
:root {
  var-redef: #0f0;
  var-a1: #fff;
  var-a2: var(a1);
  var-a3: var(a2);
  var-redef: #000;
}
.test-1 {
  background-color: var(a1);
  color: var(a2);
  border-color: var(a3);
}
.test-1a {
  color: var(redef);
}''';

  var stylesheet1 = compileCss(file1Input, errors: errors, opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet1), generated1);

  var generated2 = r'''
:root {
  var-redef: #0b0;
  var-b3: var(a3);
}
.test-2 {
  color: var(b3);
  background-color: var(redef);
  border-color: var(a3);
}''';

  var stylesheet2 = compileCss(file2Input,
      includes: [stylesheet1], errors: errors..clear(), opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet2), generated2);

  var generatedPolyfill1 = r'''
:root {
}
.test-1 {
  background-color: #fff;
  color: #fff;
  border-color: #fff;
}
.test-1a {
  color: #000;
}''';
  var styleSheet1Polyfill = compileCss(file1Input,
      errors: errors..clear(), polyfill: true, opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(styleSheet1Polyfill), generatedPolyfill1);

  var generatedPolyfill2 = r'''
:root {
}
.test-2 {
  color: #fff;
  background-color: #0b0;
  border-color: #fff;
}''';
  var styleSheet2Polyfill = compileCss(file2Input,
      includes: [stylesheet1],
      errors: errors..clear(),
      polyfill: true,
      opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(styleSheet2Polyfill), generatedPolyfill2);

  // Make sure includes didn't change.
  expect(prettyPrint(stylesheet1), generated1);

  var generatedPolyfill = r'''
:root {
}
.test-main {
  color: #fff;
  background-color: #0c0;
  border-color: #fff;
}''';
  var stylesheetPolyfill = compileCss(input,
      includes: [stylesheet1, stylesheet2],
      errors: errors..clear(),
      polyfill: true,
      opts: options);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheetPolyfill), generatedPolyfill);

  // Make sure includes didn't change.
  expect(prettyPrint(stylesheet1), generated1);
  expect(prettyPrint(stylesheet2), generated2);
}

void main() {
  glyph.ascii = true;
  test('Simple var', simpleVar);
  test('Expressions var', expressionsVar);
  test('Default value in var()', defaultVar);
  test('CSS Parser only var', parserVar);
  test('Var syntax', testVar);
  test('Indirects', testIndirects);
  test('Forward Refs', undefinedVars);
  test('Less syntax', testLess);
  test('Polyfill', polyfill);
  test('Multi-file', includes);
}
