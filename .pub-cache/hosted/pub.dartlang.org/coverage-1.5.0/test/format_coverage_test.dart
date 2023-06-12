import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../bin/format_coverage.dart';

void main() {
  late Directory testDir;
  setUp(() {
    testDir = Directory.systemTemp.createTempSync('coverage_test_temp');
  });

  tearDown(() async {
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  test('considers all json files', () async {
    final fileA = File(p.join(testDir.path, 'coverage_a.json'));
    fileA.createSync();
    final fileB = File(p.join(testDir.path, 'coverage_b.json'));
    fileB.createSync();
    final fileC = File(p.join(testDir.path, 'not_coverage.foo'));
    fileC.createSync();

    final files = filesToProcess(testDir.path);
    expect(files.length, equals(2));
    expect(
        files.map((f) => f.path),
        containsAll(
            [endsWith('coverage_a.json'), endsWith('coverage_b.json')]));
  });
}
