import 'dart:io';

import 'package:flutter_tools/executable.dart' as executable;

void main() {
  Directory.current = '/Users/tvolkert/project/flutter/flutter/examples/hello_world';
  executable.main(const <String>[
    'run',
    '--no-hot',
    '-d', 'iPhone',
    '--replay-from=bar'
  ]);
}
