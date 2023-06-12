// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library extend_test;

import 'package:csslib/src/messages.dart';
import 'package:test/test.dart';

import 'testing.dart';

void compileAndValidate(String input, String generated) {
  var errors = <Message>[];
  var stylesheet = compileCss(input, errors: errors, opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void simpleExtend() {
  compileAndValidate(r'''
.error {
  border: 1px red;
  background-color: #fdd;
}
.seriousError {
  @extend .error;
  border-width: 3px;
}
''', r'''
.error, .seriousError {
  border: 1px #f00;
  background-color: #fdd;
}
.seriousError {
  border-width: 3px;
}''');
}

void complexSelectors() {
  compileAndValidate(r'''
.error {
  border: 1px #f00;
  background-color: #fdd;
}
.error.intrusion {
  background-image: url("/image/hacked.png");
}
.seriousError {
  @extend .error;
  border-width: 3px;
}
''', r'''
.error, .seriousError {
  border: 1px #f00;
  background-color: #fdd;
}
.error.intrusion, .seriousError.intrusion {
  background-image: url("/image/hacked.png");
}
.seriousError {
  border-width: 3px;
}''');

  compileAndValidate(r'''
a:hover {
  text-decoration: underline;
}
.hoverlink {
  @extend a:hover;
}
''', r'''
a:hover, .hoverlink {
  text-decoration: underline;
}
.hoverlink {
}''');
}

void multipleExtends() {
  compileAndValidate(r'''
.error {
  border: 1px #f00;
  background-color: #fdd;
}
.attention {
  font-size: 3em;
  background-color: #ff0;
}
.seriousError {
  @extend .error;
  @extend .attention;
  border-width: 3px;
}
''', r'''
.error, .seriousError {
  border: 1px #f00;
  background-color: #fdd;
}
.attention, .seriousError {
  font-size: 3em;
  background-color: #ff0;
}
.seriousError {
  border-width: 3px;
}''');
}

void chaining() {
  compileAndValidate(r'''
.error {
  border: 1px #f00;
  background-color: #fdd;
}
.seriousError {
  @extend .error;
  border-width: 3px;
}
.criticalError {
  @extend .seriousError;
  position: fixed;
  top: 10%;
  bottom: 10%;
  left: 10%;
  right: 10%;
}
''', r'''
.error, .seriousError, .criticalError {
  border: 1px #f00;
  background-color: #fdd;
}
.seriousError, .criticalError {
  border-width: 3px;
}
.criticalError {
  position: fixed;
  top: 10%;
  bottom: 10%;
  left: 10%;
  right: 10%;
}''');
}

void nestedSelectors() {
  compileAndValidate(r'''
a {
  color: blue;
  &:hover {
    text-decoration: underline;
  }
}

#fake-links .link {
  @extend a;
}
''', r'''
a, #fake-links .link {
  color: #00f;
}
a:hover, #fake-links .link:hover {
  text-decoration: underline;
}
#fake-links .link {
}''');
}

void nestedMulty() {
  compileAndValidate(r'''
.btn {
  display: inline-block;
}

input[type="checkbox"].toggle-button {
  color: red;

  + label {
    @extend .btn;
  }
}
''', r'''
.btn, input[type="checkbox"].toggle-button label {
  display: inline-block;
}
input[type="checkbox"].toggle-button {
  color: #f00;
}
input[type="checkbox"].toggle-button label {
}''');
}

void nWayExtends() {
  compileAndValidate(
      r'''
.btn > .btn {
  margin-left: 5px;
}
input.second + label {
  @extend .btn;
}
''',
      '.btn > .btn, '
          'input.second + label > .btn, '
          '.btn > input.second + label, '
          'input.second + label > input.second + label, '
          'input.second + label > input.second + label {\n'
          '  margin-left: 5px;\n}\n'
          'input.second + label {\n'
          '}');

  // TODO(terry): Optimize merge selectors would be:
  //
  // .btn + .btn, input.second + label + .btn, input.second.btn + label {
  //    margin-left: 5px;
  //  }
  //  input.second + label {
  //    color: blue;
  //  }
  compileAndValidate(
      r'''
.btn + .btn {
  margin-left: 5px;
}
input.second + label {
  @extend .btn;
  color: blue;
}
''',
      '.btn + .btn, '
          'input.second + label + .btn, '
          '.btn + input.second + label, '
          'input.second + label + input.second + label, '
          'input.second + label + input.second + label {\n'
          '  margin-left: 5px;\n}\n'
          'input.second + label {\n'
          '  color: #00f;\n}');
}

void main() {
  test('Simple Extend', simpleExtend);
  test('complex', complexSelectors);
  test('multiple', multipleExtends);
  test('chaining', chaining);
  test('nested selectors', nestedSelectors);
  test('nested many selector sequences', nestedMulty);
  test('N-way extends', nWayExtends);
}
