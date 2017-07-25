import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('flutter gradle plugin', () {
    FlutterProject project;

    setUpAll(() async {
      final Directory tmp = await Directory.systemTemp.createTemp('gradle');
      project = await FlutterProject.create(tmp, 'hello');
    });

    tearDownAll(() async {
      await project.parent.delete(recursive: true);
    });

    test('can assemble debug', () async {
      final ProcessResult result = await project.runGradleTask('assembleDebug');
      expect(result.exitCode, isZero);
    });

    test('can assemble profile', () async {
      final ProcessResult result =
          await project.runGradleTask('assembleProfile');
      expect(result.exitCode, isZero);
    });

    test('can assemble release', () async {
      final ProcessResult result =
          await project.runGradleTask('assembleRelease');
      expect(result.exitCode, isZero);
    });

    test('can assemble custom debug', () async {
      await project.addCustomBuildType('local', initWith: 'debug');
      final ProcessResult result = await project.runGradleTask('assembleLocal');
      expect(result.exitCode, isZero);
    });

    test('can assemble custom release', () async {
      await project.addCustomBuildType('beta', initWith: 'release');
      final ProcessResult result = await project.runGradleTask('assembleBeta');
      expect(result.exitCode, isZero);
    });
  });
}

class FlutterProject {
  FlutterProject(this.parent, this.name);

  Directory parent;
  String name;

  static Future<FlutterProject> create(Directory directory, String name) async {
    final ProcessResult result = await Process.run(
      'flutter',
      <String>['create', name],
      workingDirectory: directory.path,
    );
    expect(result.exitCode, isZero);
    return new FlutterProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get androidPath => path.join(rootPath, 'android');

  Future<Null> addCustomBuildType(String name, {String initWith}) async {
    final File buildScript = new File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    buildScript.openWrite(mode: FileMode.APPEND).write('''

android {
    buildTypes {
        $name {
            initWith $initWith
        }
    }
}
    ''');
  }

  Future<ProcessResult> runGradleTask(String task) async {
    return Process.run(
      './gradlew',
      <String>['-q', 'app:$task'],
      workingDirectory: androidPath,
    );
  }
}
