// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nested_test;

import 'package:csslib/src/messages.dart';
import 'package:test/test.dart';

import 'testing.dart';

void compileAndValidate(String input, String generated) {
  var errors = <Message>[];
  var stylesheet = compileCss(input, errors: errors, opts: simpleOptions);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void selectorVariations() {
  final input1 = r'''html { color: red; }''';
  final generated1 = r'''html {
  color: #f00;
}''';
  compileAndValidate(input1, generated1);

  final input2 = r'''button { span { height: 200 } }''';
  final generated2 = r'''button {
}
button span {
  height: 200;
}''';
  compileAndValidate(input2, generated2);

  final input3 = r'''div { color: red; } button { span { height: 200 } }''';
  final generated3 = r'''div {
  color: #f00;
}
button {
}
button span {
  height: 200;
}''';
  compileAndValidate(input3, generated3);

  final input4 = r'''#header { color: red; h1 { font-size: 26px; } }''';
  final generated4 = r'''#header {
  color: #f00;
}
#header h1 {
  font-size: 26px;
}''';
  compileAndValidate(input4, generated4);

  final input5 = r'''
#header {
  color: red;
  h1 { font-size: 26px; }
  background-color: blue;
}''';
  final generated5 = r'''#header {
  color: #f00;
  background-color: #00f;
}
#header h1 {
  font-size: 26px;
}''';
  compileAndValidate(input5, generated5);

  final input6 = r'''html { body {color: red; }}''';
  final generated6 = r'''html {
}
html body {
  color: #f00;
}''';
  compileAndValidate(input6, generated6);

  final input7 = r'''html body {color: red; }''';
  final generated7 = r'''html body {
  color: #f00;
}''';
  compileAndValidate(input7, generated7);

  final input8 = r'''
html, body { color: red; }
button { height: 200 }
body { width: 300px; }''';
  final generated8 = r'''html, body {
  color: #f00;
}
button {
  height: 200;
}
body {
  width: 300px;
}''';
  compileAndValidate(input8, generated8);

  final input9 = '''
html, body {
  color: red;
  button { height: 200 }
  div { width: 300px; }
}''';
  final generated9 = r'''html, body {
  color: #f00;
}
html button, body button {
  height: 200;
}
html div, body div {
  width: 300px;
}''';
  compileAndValidate(input9, generated9);

  final input10 = '''
html {
  color: red;
  button, div { height: 200 }
  body { width: 300px; }
}''';
  final generated10 = r'''html {
  color: #f00;
}
html button, html div {
  height: 200;
}
html body {
  width: 300px;
}''';
  compileAndValidate(input10, generated10);

  final input11 = '''
html, body {
  color: red;
  button, div { height: 200 }
  table { width: 300px; }
}''';
  final generated11 = r'''html, body {
  color: #f00;
}
html button, body button, html div, body div {
  height: 200;
}
html table, body table {
  width: 300px;
}''';
  compileAndValidate(input11, generated11);

  final input12 = '''
html, body {
  color: red;
  button, div {
    span, a, ul { height: 200 }
  }
  table { width: 300px; }
}''';
  final generated12 = r'''html, body {
  color: #f00;
}
'''
      'html button span, body button span, html div span, body div span, '
      'html button a, body button a, html div a, body div a, html button ul, '
      r'''body button ul, html div ul, body div ul {
  height: 200;
}
html table, body table {
  width: 300px;
}''';
  compileAndValidate(input12, generated12);

  final input13 = r'''
#header {
  div {
  width: 100px;
  a { height: 200px; }
  }
  color: blue;
}
span { color: #1f1f1f; }
''';
  final generated13 = r'''#header {
  color: #00f;
}
#header div {
  width: 100px;
}
#header div a {
  height: 200px;
}
span {
  color: #1f1f1f;
}''';
  compileAndValidate(input13, generated13);
}

void simpleNest() {
  final input = '''
div span { color: green; }
#header {
  color: red;
  h1 {
    font-size: 26px;
    font-weight: bold;
  }
  p {
    font-size: 12px;
    a {
      text-decoration: none;
    }
  }
  background-color: blue;
}
div > span[attr="foo"] { color: yellow; }
''';

  final generated = r'''div span {
  color: #008000;
}
#header {
  color: #f00;
  background-color: #00f;
}
#header h1 {
  font-size: 26px;
  font-weight: bold;
}
#header p {
  font-size: 12px;
}
#header p a {
  text-decoration: none;
}
div > span[attr="foo"] {
  color: #ff0;
}''';
  compileAndValidate(input, generated);
}

void complexNest() {
  final input = '''
@font-face  { font-family: arial; }
div { color: #f0f0f0; }
#header + div {
  color: url(abc.png);
  *[attr="bar"] {
    font-size: 26px;
    font-weight: bold;
  }
  p~ul {
    font-size: 12px;
    :not(p) {
      text-decoration: none;
      div > span[attr="foo"] { color: yellow; }
    }
  }
  background-color: blue;
  span {
    color: red;
    .one { color: blue; }
    .two { color: green; }
    .three { color: yellow; }
    .four {
       .four-1 { background-color: #00000f; }
       .four-2 { background-color: #0000ff; }
       .four-3 { background-color: #000fff; }
       .four-4 {
         height: 44px;
         .four-4-1 { height: 10px; }
         .four-4-2 { height: 20px; }
         .four-4-3 { height: 30px; }
         width: 44px;
       }
    }
  }
}
span { color: #1f1f2f; }
''';

  final generated = r'''@font-face  {
  font-family: arial;
}
div {
  color: #f0f0f0;
}
#header + div {
  color: url("abc.png");
  background-color: #00f;
}
#header + div *[attr="bar"] {
  font-size: 26px;
  font-weight: bold;
}
#header + div p ~ ul {
  font-size: 12px;
}
#header + div p ~ ul :not(p) {
  text-decoration: none;
}
#header + div p ~ ul :not(p) div > span[attr="foo"] {
  color: #ff0;
}
#header + div span {
  color: #f00;
}
#header + div span .one {
  color: #00f;
}
#header + div span .two {
  color: #008000;
}
#header + div span .three {
  color: #ff0;
}
#header + div span .four .four-1 {
  background-color: #00000f;
}
#header + div span .four .four-2 {
  background-color: #00f;
}
#header + div span .four .four-3 {
  background-color: #000fff;
}
#header + div span .four .four-4 {
  height: 44px;
  width: 44px;
}
#header + div span .four .four-4 .four-4-1 {
  height: 10px;
}
#header + div span .four .four-4 .four-4-2 {
  height: 20px;
}
#header + div span .four .four-4 .four-4-3 {
  height: 30px;
}
span {
  color: #1f1f2f;
}''';

  compileAndValidate(input, generated);
}

void mediaNesting() {
  final input = r'''
@media screen and (-webkit-min-device-pixel-ratio:0) {
  #toggle-all {
    image: url(test.jpb);
    div, table {
      background: none;
      a { width: 100px; }
    }
    color: red;
  }
}
''';
  final generated = r'''@media screen AND (-webkit-min-device-pixel-ratio:0) {
#toggle-all {
  image: url("test.jpb");
  color: #f00;
}
#toggle-all div, #toggle-all table {
  background: none;
}
#toggle-all div a, #toggle-all table a {
  width: 100px;
}
}''';

  compileAndValidate(input, generated);
}

void simpleThis() {
  final input = '''#header {
  h1 {
    font-size: 26px;
    font-weight: bold;
  }
  p { font-size: 12px;
    a { text-decoration: none;
      &:hover { border-width: 1px }
    }
  }
}
''';

  final generated = r'''#header {
}
#header h1 {
  font-size: 26px;
  font-weight: bold;
}
#header p {
  font-size: 12px;
}
#header p a {
  text-decoration: none;
}
#header p a:hover {
  border-width: 1px;
}''';

  compileAndValidate(input, generated);
}

void complexThis() {
  final input1 = r'''
.light {
  .leftCol {
    .textLink {
      color: fooL1;
      &:hover { color: barL1;}
    }
    .picLink {
      background-image: url(/fooL1.jpg);
      &:hover { background-image: url(/barL1.jpg);}
    }
    .textWithIconLink {
      color: fooL2;
      background-image: url(/fooL2.jpg);
      &:hover { color: barL2; background-image: url(/barL2.jpg);}
    }
  }
}''';

  final generated1 = r'''.light {
}
.light .leftCol .textLink {
  color: fooL1;
}
.light .leftCol .textLink:hover {
  color: barL1;
}
.light .leftCol .picLink {
  background-image: url("/fooL1.jpg");
}
.light .leftCol .picLink:hover {
  background-image: url("/barL1.jpg");
}
.light .leftCol .textWithIconLink {
  color: fooL2;
  background-image: url("/fooL2.jpg");
}
.light .leftCol .textWithIconLink:hover {
  color: barL2;
  background-image: url("/barL2.jpg");
}''';

  compileAndValidate(input1, generated1);

  final input2 = r'''
.textLink {
  .light .leftCol & {
    color: fooL1;
    &:hover { color: barL1; }
  }
  .light .rightCol & {
    color: fooL3;
    &:hover { color: barL3; }
  }
}''';

  final generated2 = r'''
.textLink {
}
.light .leftCol .textLink {
  color: fooL1;
}
.light .leftCol .textLink:hover {
  color: barL1;
}
.light .rightCol .textLink {
  color: fooL3;
}
.light .rightCol .textLink:hover {
  color: barL3;
}''';

  compileAndValidate(input2, generated2);
}

void variationsThis() {
  final input1 = r'''
.textLink {
  a {
    light .leftCol & {
      color: red;
    }
  }
}''';
  final generated1 = r'''.textLink {
}
light .leftCol .textLink a {
  color: #f00;
}''';

  compileAndValidate(input1, generated1);

  final input2 = r'''.textLink {
  a {
    & light .leftCol & {
      color: red;
    }
  }
}''';
  final generated2 = r'''.textLink {
}
.textLink a light .leftCol .textLink a {
  color: #f00;
}''';
  compileAndValidate(input2, generated2);

  final input3 = r'''
.textLink {
  a {
    & light .leftCol { color: red; }
  }
}''';
  final generated3 = r'''.textLink {
}
.textLink a light .leftCol {
  color: #f00;
}''';
  compileAndValidate(input3, generated3);

  final input4 = r'''
.textLink {
  a {
    & light .leftCol { color: red; }
    &:hover { width: 100px; }
  }
}''';
  final generated4 = r'''.textLink {
}
.textLink a light .leftCol {
  color: #f00;
}
.textLink a:hover {
  width: 100px;
}''';
  compileAndValidate(input4, generated4);

  final input5 = r'''.textLink { a { &:hover { color: red; } } }''';
  final generated5 = r'''.textLink {
}
.textLink a:hover {
  color: #f00;
}''';

  compileAndValidate(input5, generated5);

  final input6 = r'''.textLink { &:hover { color: red; } }''';
  final generated6 = r'''.textLink {
}
.textLink:hover {
  color: #f00;
}''';
  compileAndValidate(input6, generated6);

  final input7 = r'''.textLink { a { & + & { color: red; } } }''';
  final generated7 = r'''.textLink {
}
.textLink a + .textLink a {
  color: #f00;
}''';
  compileAndValidate(input7, generated7);

  final input8 = r'''.textLink { a { & { color: red; } } }''';
  final generated8 = r'''.textLink {
}
.textLink a {
  color: #f00;
}''';
  compileAndValidate(input8, generated8);

  final input9 = r'''.textLink { a { & ~ & { color: red; } } }''';
  final generated9 = r'''.textLink {
}
.textLink a ~ .textLink a {
  color: #f00;
}''';
  compileAndValidate(input9, generated9);

  final input10 = r'''.textLink { a { & & { color: red; } } }''';
  final generated10 = r'''.textLink {
}
.textLink a .textLink a {
  color: #f00;
}''';
  compileAndValidate(input10, generated10);
}

void thisCombinator() {
  var input = r'''
.btn {
  color: red;
}
.btn + .btn {
  margin-left: 5px;
}
input.second {
  & + label {
    color: blue;
  }
}
''';

  var generated = r'''.btn {
  color: #f00;
}
.btn + .btn {
  margin-left: 5px;
}
input.second {
}
input.second + label {
  color: #00f;
}''';

  compileAndValidate(input, generated);
}

void main() {
  test('Selector and Nested Variations', selectorVariations);
  test('Simple nesting', simpleNest);
  test('Complex nesting', complexNest);
  test('@media nesting', mediaNesting);
  test('Simple &', simpleThis);
  test('Variations &', variationsThis);
  test('Complex &', complexThis);
  test('& with + selector', thisCombinator);
}
