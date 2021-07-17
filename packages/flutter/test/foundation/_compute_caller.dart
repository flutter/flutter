// A test script that invokes compute() to start an isolate.

import 'package:flutter/src/foundation/_isolates_io.dart';

int getLength(String s) {
  return s.length;
}

Future<void> main() async {
  const String s = 'hello world';
  final int result = await compute(getLength, s);
  if (result != s.length) {
    throw Exception('compute returned bad result');
  }
}
