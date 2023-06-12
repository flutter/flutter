// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common definitions used for setting up the test environment.
library testing;

import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';

export 'package:csslib/src/preprocessor_options.dart';

const simpleOptionsWithCheckedAndWarningsAsErrors = PreprocessorOptions(
    useColors: false,
    checked: true,
    warningsAsErrors: true,
    inputFile: 'memory');

const simpleOptions =
    PreprocessorOptions(useColors: false, inputFile: 'memory');

const options = PreprocessorOptions(
    useColors: false, warningsAsErrors: true, inputFile: 'memory');

/// Spin-up CSS parser in checked mode to detect any problematic CSS.  Normally,
/// CSS will allow any property/value pairs regardless of validity; all of our
/// tests (by default) will ensure that the CSS is really valid.
StyleSheet parseCss(String cssInput,
        {List<Message>? errors, PreprocessorOptions? opts}) =>
    parse(cssInput,
        errors: errors,
        options: opts ?? simpleOptionsWithCheckedAndWarningsAsErrors);

/// Spin-up CSS parser in checked mode to detect any problematic CSS.  Normally,
/// CSS will allow any property/value pairs regardless of validity; all of our
/// tests (by default) will ensure that the CSS is really valid.
StyleSheet compileCss(String cssInput,
        {List<Message>? errors,
        PreprocessorOptions? opts,
        bool polyfill = false,
        List<StyleSheet>? includes}) =>
    compile(cssInput,
        errors: errors,
        options: opts ?? simpleOptionsWithCheckedAndWarningsAsErrors,
        polyfill: polyfill,
        includes: includes);

StyleSheet polyFillCompileCss(input,
        {List<Message>? errors, PreprocessorOptions? opts}) =>
    compileCss(input as String, errors: errors, polyfill: true, opts: opts);

/// CSS emitter walks the style sheet tree and emits readable CSS.
final _emitCss = CssPrinter();

/// Simple Visitor does nothing but walk tree.
final _cssVisitor = Visitor();

/// Pretty printer for CSS.
String prettyPrint(StyleSheet ss) {
  // Walk the tree testing basic Vistor class.
  walkTree(ss);
  return (_emitCss..visitTree(ss, pretty: true)).toString();
}

/// Helper function to emit compact (non-pretty printed) CSS for suite test
/// comparsions.  Spaces, new lines, etc. are reduced for easier comparsions of
/// expected suite test results.
String compactOutput(StyleSheet ss) {
  walkTree(ss);
  return (_emitCss..visitTree(ss, pretty: false)).toString();
}

/// Walks the style sheet tree does nothing; insures the basic walker works.
void walkTree(StyleSheet ss) {
  _cssVisitor.visitTree(ss);
}

String dumpTree(StyleSheet ss) => treeToDebugString(ss);
