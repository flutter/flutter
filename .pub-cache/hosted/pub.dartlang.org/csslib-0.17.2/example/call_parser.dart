// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

const _default = css.PreprocessorOptions(
    useColors: false,
    checked: true,
    warningsAsErrors: true,
    inputFile: 'memory');

/// Spin-up CSS parser in checked mode to detect any problematic CSS.  Normally,
/// CSS will allow any property/value pairs regardless of validity; all of our
/// tests (by default) will ensure that the CSS is really valid.
StyleSheet parseCss(String cssInput,
    {List<css.Message>? errors, css.PreprocessorOptions? opts}) {
  return css.parse(cssInput, errors: errors, options: opts ?? _default);
}

// Pretty printer for CSS.
var emitCss = CssPrinter();
String prettyPrint(StyleSheet ss) =>
    (emitCss..visitTree(ss, pretty: true)).toString();

void main() {
  var errors = <css.Message>[];

  // Parse a simple stylesheet.
  print('1. Good CSS, parsed CSS emitted:');
  print('   =============================');
  var stylesheet = parseCss(
      '@import "support/at-charset-019.css"; div { color: red; }'
      'button[type] { background-color: red; }'
      '.foo { '
      'color: red; left: 20px; top: 20px; width: 100px; height:200px'
      '}'
      '#div {'
      'color : #00F578; border-color: #878787;'
      '}',
      errors: errors);

  if (errors.isNotEmpty) {
    print('Got ${errors.length} errors.\n');
    for (var error in errors) {
      print(error);
    }
  } else {
    print(prettyPrint(stylesheet));
  }

  // Parse a stylesheet with errors
  print('2. Catch severe syntax errors:');
  print('   ===========================');
  var stylesheetError = parseCss(
      '.foo #%^&*asdf{ '
      'color: red; left: 20px; top: 20px; width: 100px; height:200px'
      '}',
      errors: errors);

  if (errors.isNotEmpty) {
    print('Got ${errors.length} errors.\n');
    for (var error in errors) {
      print(error);
    }
  } else {
    print(stylesheetError.toString());
  }

  // Parse a stylesheet that warns (checks) problematic CSS.
  print('3. Detect CSS problem with checking on:');
  print('   ===================================');
  stylesheetError = parseCss('# div1 { color: red; }', errors: errors);

  if (errors.isNotEmpty) {
    print('Detected ${errors.length} problem in checked mode.\n');
    for (var error in errors) {
      print(error);
    }
  } else {
    print(stylesheetError.toString());
  }

  // Parse a CSS selector.
  print('4. Parse a selector only:');
  print('   ======================');
  var selectorAst = css.selector('#div .foo', errors: errors);
  if (errors.isNotEmpty) {
    print('Got ${errors.length} errors.\n');
    for (var error in errors) {
      print(error);
    }
  } else {
    print(prettyPrint(selectorAst));
  }
}
