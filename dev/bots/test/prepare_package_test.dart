// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' show FakePlatform;

import '../prepare_package.dart';
import 'fake_process_manager.dart';

void main() {
  const String testRef = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
  test('Throws on missing executable', () async {
    // Uses a *real* process manager, since we want to know what happens if
    // it can't find an executable.
    final ProcessRunner processRunner = new ProcessRunner(subprocessOutput: false);
    expect(
        expectAsync1((List<String> commandLine) async {
          return processRunner.runProcess(commandLine);
        })(<String>['this_executable_better_not_exist_2857632534321']),
        throwsA(const isInstanceOf<ProcessRunnerException>()));
    try {
      await processRunner.runProcess(<String>['this_executable_better_not_exist_2857632534321']);
    } on ProcessRunnerException catch (e) {
      expect(
        e.message,
        contains('Invalid argument(s): Cannot find executable for this_executable_better_not_exist_2857632534321.'),
      );
    }
  });
  for (String platformName in <String>['macos', 'linux', 'windows']) {
    final FakePlatform platform = new FakePlatform(
      operatingSystem: platformName,
      environment: <String, String>{},
    );
    group('ProcessRunner for $platform', () {
      test('Returns stdout', () async {
        final FakeProcessManager fakeProcessManager = new FakeProcessManager();
        fakeProcessManager.fakeResults = <String, List<ProcessResult>>{
          'echo test': <ProcessResult>[new ProcessResult(0, 0, 'output', 'error')],
        };
        final ProcessRunner processRunner = new ProcessRunner(
            subprocessOutput: false, platform: platform, processManager: fakeProcessManager);
        final String output = await processRunner.runProcess(<String>['echo', 'test']);
        expect(output, equals('output'));
      });
      test('Throws on process failure', () async {
        final FakeProcessManager fakeProcessManager = new FakeProcessManager();
        fakeProcessManager.fakeResults = <String, List<ProcessResult>>{
          'echo test': <ProcessResult>[new ProcessResult(0, -1, 'output', 'error')],
        };
        final ProcessRunner processRunner = new ProcessRunner(
            subprocessOutput: false, platform: platform, processManager: fakeProcessManager);
        expect(
            expectAsync1((List<String> commandLine) async {
              return processRunner.runProcess(commandLine);
            })(<String>['echo', 'test']),
            throwsA(const isInstanceOf<ProcessRunnerException>()));
      });
    });
    group('ArchiveCreator for $platformName', () {
      ArchiveCreator creator;
      Directory tmpDir;
      Directory flutterDir;
      FakeProcessManager processManager;
      final List<List<String>> args = <List<String>>[];
      final List<Map<Symbol, dynamic>> namedArgs = <Map<Symbol, dynamic>>[];
      String flutter;

      Future<Uint8List> fakeHttpReader(Uri url, {Map<String, String> headers}) {
        return new Future<Uint8List>.value(new Uint8List(0));
      }

      setUp(() async {
        processManager = new FakeProcessManager();
        args.clear();
        namedArgs.clear();
        tmpDir = await Directory.systemTemp.createTemp('flutter_');
        flutterDir = new Directory(path.join(tmpDir.path, 'flutter'));
        flutterDir.createSync(recursive: true);
        creator = new ArchiveCreator(
          tmpDir,
          tmpDir,
          testRef,
          Branch.dev,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        flutter = path.join(creator.flutterRoot.absolute.path, 'bin', 'flutter');
      });

      tearDown(() async {
        // On Windows, the directory is locked and not able to be deleted yet. So
        // we just leave some (very small, because we're not actually building
        // archives here) trash around to be deleted at the next reboot.
        if (!platform.isWindows) {
          await tmpDir.delete(recursive: true);
        }
      });

      test('sets PUB_CACHE properly', () async {
        final String createBase = path.join(tmpDir.absolute.path, 'create_');
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter':
              null,
          'git reset --hard $testRef': null,
          'git remote set-url origin https://github.com/flutter/flutter.git': null,
          'git describe --tags --abbrev=0': <ProcessResult>[new ProcessResult(0, 0, 'v1.2.3', '')],
        };
        if (platform.isWindows) {
          calls['7za x ${path.join(tmpDir.path, 'mingit.zip')}'] = null;
        }
        calls.addAll(<String, List<ProcessResult>>{
          '$flutter doctor': null,
          '$flutter update-packages': null,
          '$flutter precache': null,
          '$flutter ide-config': null,
          '$flutter create --template=app ${createBase}app': null,
          '$flutter create --template=package ${createBase}package': null,
          '$flutter create --template=plugin ${createBase}plugin': null,
          'git clean -f -X **/.packages': null,
        });
        final String archiveName = path.join(tmpDir.absolute.path,
            'flutter_${platformName}_v1.2.3-dev${platform.isLinux ? '.tar.xz' : '.zip'}');
        if (platform.isWindows) {
          calls['7za a -tzip -mx=9 $archiveName flutter'] = null;
        } else if (platform.isMacOS) {
          calls['zip -r -9 $archiveName flutter'] = null;
        } else if (platform.isLinux) {
          calls['tar cJf $archiveName flutter'] = null;
        }
        processManager.fakeResults = calls;
        await creator.initializeRepo();
        await creator.createArchive();
        expect(
          verify(processManager.start(
            captureAny,
            workingDirectory: captureAny,
            environment: captureAny,
          )).captured[1]['PUB_CACHE'],
          endsWith(path.join('flutter', '.pub-cache')),
        );
      });

      test('calls the right commands for archive output', () async {
        final String createBase = path.join(tmpDir.absolute.path, 'create_');
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter':
              null,
          'git reset --hard $testRef': null,
          'git remote set-url origin https://github.com/flutter/flutter.git': null,
          'git describe --tags --abbrev=0': <ProcessResult>[new ProcessResult(0, 0, 'v1.2.3', '')],
        };
        if (platform.isWindows) {
          calls['7za x ${path.join(tmpDir.path, 'mingit.zip')}'] = null;
        }
        calls.addAll(<String, List<ProcessResult>>{
          '$flutter doctor': null,
          '$flutter update-packages': null,
          '$flutter precache': null,
          '$flutter ide-config': null,
          '$flutter create --template=app ${createBase}app': null,
          '$flutter create --template=package ${createBase}package': null,
          '$flutter create --template=plugin ${createBase}plugin': null,
          'git clean -f -X **/.packages': null,
        });
        final String archiveName = path.join(tmpDir.absolute.path,
            'flutter_${platformName}_v1.2.3-dev${platform.isLinux ? '.tar.xz' : '.zip'}');
        if (platform.isWindows) {
          calls['7za a -tzip -mx=9 $archiveName flutter'] = null;
        } else if (platform.isMacOS) {
          calls['zip -r -9 $archiveName flutter'] = null;
        } else if (platform.isLinux) {
          calls['tar cJf $archiveName flutter'] = null;
        }
        processManager.fakeResults = calls;
        creator = new ArchiveCreator(
          tmpDir,
          tmpDir,
          testRef,
          Branch.dev,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();
        await creator.createArchive();
        processManager.verifyCalls(calls.keys.toList());
      });

      test('throws when a command errors out', () async {
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter':
              <ProcessResult>[new ProcessResult(0, 0, 'output1', '')],
          'git reset --hard $testRef': <ProcessResult>[new ProcessResult(0, -1, 'output2', '')],
        };
        processManager.fakeResults = calls;
        expect(expectAsync0(creator.initializeRepo),
            throwsA(const isInstanceOf<ProcessRunnerException>()));
      });
    });

    group('ArchivePublisher for $platformName', () {
      FakeProcessManager processManager;
      Directory tempDir;

      setUp(() async {
        processManager = new FakeProcessManager();
        tempDir = await Directory.systemTemp.createTemp('flutter_');
        tempDir.createSync();
      });

      tearDown(() async {
        // On Windows, the directory is locked and not able to be deleted yet. So
        // we just leave some (very small, because we're not actually building
        // archives here) trash around to be deleted at the next reboot.
        if (!platform.isWindows) {
          await tempDir.delete(recursive: true);
        }
      });

      test('calls the right processes', () async {
        final String releasesName = 'releases_$platformName.json';
        final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
        final String archiveMime = platform.isLinux ? 'application/x-gtar' : 'application/zip';
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String gsArchivePath = 'gs://flutter_infra/releases/dev/$platformName/$archiveName';
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra/releases/$releasesName';
        final String releasesJson = '''{
    "base_url": "https://storage.googleapis.com/flutter_infra/releases",
    "current_release": {
        "beta": "6da8ec6bd0c4801b80d666869e4069698561c043",
        "dev": "f88c60b38c3a5ef92115d24e3da4175b4890daba"
    },
    "releases": {
        "6da8ec6bd0c4801b80d666869e4069698561c043": {
            "${platformName}_archive": "dev/linux/flutter_${platformName}_0.21.0-beta.zip",
            "release_date": "2017-12-19T10:30:00,847287019-08:00",
            "version": "0.21.0-beta"
        },
        "f88c60b38c3a5ef92115d24e3da4175b4890daba": {
            "${platformName}_archive": "dev/linux/flutter_${platformName}_0.22.0-dev.zip",
            "release_date": "2018-01-19T13:30:09,728487019-08:00",
            "version": "0.22.0-dev"
        }
    }
}
''';
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'gsutil rm $gsArchivePath': null,
          'gsutil -h Content-Type:$archiveMime cp $archivePath $gsArchivePath': null,
          'gsutil cat $gsJsonPath': <ProcessResult>[new ProcessResult(0, 0, releasesJson, '')],
          'gsutil rm $gsJsonPath': null,
          'gsutil -h Content-Type:application/json cp $jsonPath $gsJsonPath': null,
        };
        processManager.fakeResults = calls;
        final File outputFile = new File(path.join(tempDir.absolute.path, archiveName));
        assert(tempDir.existsSync());
        final ArchivePublisher publisher = new ArchivePublisher(
          tempDir,
          testRef,
          Branch.dev,
          '1.2.3',
          outputFile,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
        );
        assert(tempDir.existsSync());
        await publisher.publishArchive();
        processManager.verifyCalls(calls.keys.toList());
        final File releaseFile = new File(jsonPath);
        expect(releaseFile.existsSync(), isTrue);
        final String contents = releaseFile.readAsStringSync();
        // Make sure new data is added.
        expect(contents, contains('"dev": "$testRef"'));
        expect(contents, contains('"$testRef": {'));
        expect(contents, contains('"${platformName}_archive": "dev/$platformName/$archiveName"'));
        // Make sure existing entries are preserved.
        expect(contents, contains('"6da8ec6bd0c4801b80d666869e4069698561c043": {'));
        expect(contents, contains('"f88c60b38c3a5ef92115d24e3da4175b4890daba": {'));
        expect(contents, contains('"beta": "6da8ec6bd0c4801b80d666869e4069698561c043"'));
        // Make sure it's valid JSON, and in the right format.
        final Map<String, dynamic> jsonData = json.decode(contents);
        const JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        expect(contents, equals(encoder.convert(jsonData)));
      });
    });
  }
}
