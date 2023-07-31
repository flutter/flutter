@TestOn('vm')
library process_run.dartbin_api_test;

import 'package:process_run/dartbin.dart';
import 'package:test/test.dart';

void main() {
  group('dartbin_api', () {
    test('public', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
      // ignore: unnecessary_statements
      getFlutterBinChannel;
    });
  });
}
