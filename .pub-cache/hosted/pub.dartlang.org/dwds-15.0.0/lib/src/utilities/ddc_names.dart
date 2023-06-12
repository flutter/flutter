// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// Transforms a path to a valid JS identifier.
///
/// This logic must be synchronized with [pathToJSIdentifier] in DDC at:
/// pkg/dev_compiler/lib/src/compiler/module_builder.dart
///
/// For backwards compatibility, if this pattern is changed,
/// dev_compiler_bootstrap.dart must be updated to accept both old and new
/// patterns.
String pathToJSIdentifier(String path) {
  path = p.normalize(path);
  if (path.startsWith('/') || path.startsWith('\\')) {
    path = path.substring(1, path.length);
  }
  return toJSIdentifier(path
      .replaceAll('\\', '__')
      .replaceAll('/', '__')
      .replaceAll('..', '__')
      .replaceAll('-', '_'));
}

/// Escape [name] to make it into a valid identifier.
String toJSIdentifier(String name) {
  if (name.isEmpty) return r'$';

  // Escape any invalid characters
  StringBuffer? buffer;
  for (var i = 0; i < name.length; i++) {
    final ch = name[i];
    final needsEscape = ch == r'$' || _invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  final result = buffer != null ? '$buffer' : name;
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(RegExp('[0-9]')) || invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

/// Returns true for invalid JS variable names, such as keywords.
/// Also handles invalid variable names in strict mode, like "arguments".
bool invalidVariableName(String keyword, {bool strictMode = true}) {
  switch (keyword) {
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    case 'await':
    case 'break':
    case 'case':
    case 'catch':
    case 'class':
    case 'const':
    case 'continue':
    case 'debugger':
    case 'default':
    case 'delete':
    case 'do':
    case 'else':
    case 'enum':
    case 'export':
    case 'extends':
    case 'finally':
    case 'for':
    case 'function':
    case 'if':
    case 'import':
    case 'in':
    case 'instanceof':
    case 'let':
    case 'new':
    case 'return':
    case 'super':
    case 'switch':
    case 'this':
    case 'throw':
    case 'try':
    case 'typeof':
    case 'var':
    case 'void':
    case 'while':
    case 'with':
      return true;
    case 'arguments':
    case 'eval':
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    // http://www.ecma-international.org/ecma-262/6.0/#sec-identifiers-static-semantics-early-errors
    case 'implements':
    case 'interface':
    case 'package':
    case 'private':
    case 'protected':
    case 'public':
    case 'static':
    case 'yield':
      return strictMode;
  }
  return false;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = RegExp(r'[^A-Za-z_$0-9]');
