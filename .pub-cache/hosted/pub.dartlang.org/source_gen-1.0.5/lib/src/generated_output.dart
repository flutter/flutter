// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'generator.dart';

class GeneratedOutput {
  final String output;
  final String generatorDescription;

  GeneratedOutput(Generator generator, this.output)
      : assert(output.isNotEmpty),
        // assuming length check is cheaper than simple string equality
        assert(output.length == output.trim().length),
        generatorDescription = _toString(generator);

  static String _toString(Generator generator) {
    final output = generator.toString();
    if (output.endsWith('Generator')) {
      return output;
    }
    return 'Generator: $output';
  }
}
