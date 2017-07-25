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
      await project.runGradleTask('assembleDebug');
    });

    test('can assemble profile', () async {
      await project.runGradleTask('assembleProfile');
    });

    test('can assemble release', () async {
      await project.runGradleTask('assembleRelease');
    });

    test('can assemble custom debug', () async {
      await project.addCustomBuildType('local', initWith: 'debug');
      await project.runGradleTask('assembleLocal');
    });

    test('can assemble custom release', () async {
      await project.addCustomBuildType('beta', initWith: 'release');
      await project.runGradleTask('assembleBeta');
    });
  }, timeout: new Timeout.factor(4));
}

String get flutterExecutable {
  final String fileName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  return path.absolute(path.join('..', '..', 'bin', fileName));
}

String get gradleExecutable {
  final String fileName = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
  return path.join('.', fileName);
}

class FlutterProject {
  FlutterProject(this.parent, this.name);

  Directory parent;
  String name;

  static Future<FlutterProject> create(Directory directory, String name) async {
    final ProcessResult result = await Process.run(
      flutterExecutable,
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

  Future<Null> runGradleTask(String task) async {
    final ProcessResult result = await Process.run(
      gradleExecutable,
      <String>['-q', 'app:$task'],
      workingDirectory: androidPath,
    );
    expect(result.exitCode, isZero);
  }
}
