
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/output_formats.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('output formats', () {
    Testbed testbed;
    MockBuildSystem mockBuildSystem;

    setUp(() {
      mockBuildSystem = MockBuildSystem();
      testbed = Testbed(overrides: <Type, Generator>{
        BuildSystem: () => mockBuildSystem,
      });
    });

    test('generates xcfile lists', () => testbed.run(() {
      final Environment environment = Environment(
        projectDir: fs.currentDirectory,
      );
      fs.file('example.stamp')
        ..createSync()
        ..writeAsStringSync('''
  {"inputs":["c","Info.plist",".flutter-plugins","${fs.path.join(environment.buildDir.path, 'f')}"],
  "outputs":["a","b"]}
  ''');
      when(buildSystem.stampFilesFor('example', environment)).thenReturn(<File>[
        fs.file('example.stamp'),
      ]);

      generateXcFileList('example', environment, 'paths');
      final File inputFile = fs.file(fs.path.join('paths', 'FlutterInputs.xcfilelist'));
      final File outputFile = fs.file(fs.path.join('paths', 'FlutterOutputs.xcfilelist'));

      expect(inputFile.readAsLinesSync(), <String>['c', '']);
      expect(outputFile.readAsLinesSync(),  <String>['a', 'b', '']);
    }));
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
