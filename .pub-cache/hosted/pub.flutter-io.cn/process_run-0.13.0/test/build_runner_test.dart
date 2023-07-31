@TestOn('vm')
library process_run.dartfmt_test;

import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('pbr', () {
    test('help', () async {
      final result = await runCmd(PbrCmd(['--help']));
      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage: build_runner'));
    });
  });
}
