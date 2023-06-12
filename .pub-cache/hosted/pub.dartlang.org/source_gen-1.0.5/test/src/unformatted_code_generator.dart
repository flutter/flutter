// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_gen/source_gen.dart';

/// Generates a single-line of unformatted code.
class UnformattedCodeGenerator extends Generator {
  const UnformattedCodeGenerator();

  @override
  String generate(_, __) => unformattedCode;

  static const formattedCode = '''
void hello() => print('hello');
''';

  static const unformattedCode = '''
void hello ()=>  print('hello');
''';
}
