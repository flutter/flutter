// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show ProcessResult;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' show FakePlatform, Platform;

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import '../prepare_package/archive_creator.dart';
import '../prepare_package/archive_publisher.dart';
import '../prepare_package/common.dart';
import '../prepare_package/process_runner.dart';
import 'common.dart';

void main() {
  const String testRef = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef';

  ProcessResult generateStatOutput([int generation = 1722972798981253]) => ProcessResult(
    0,
    0,
    '''
gs://flutter_infra_release/releases/releases_macos.json:
    Creation time:          Tue, 06 Aug 2024 19:33:19 GMT
    Update time:            Tue, 06 Aug 2024 19:33:19 GMT
    Storage class:          STANDARD
    Content-Length:         267810
    Content-Type:           application/json
    Hash (crc32c):          tgFuZw==
    Hash (md5):             xPUCBPIzd9nMUBpFfh6W2w==
    ETag:                   CIWpkO2N4YcDEAE=
    Generation:             $generation
    Metageneration:         1
''',
    '',
  );

  test('Throws on missing executable', () async {
    // Uses a *real* process manager, since we want to know what happens if
    // it can't find an executable.
    final ProcessRunner processRunner = ProcessRunner(
      subprocessOutput: false,
      printError: ([Object? _]) {},
    );
    expect(
        expectAsync1((List<String> commandLine) async {
          return processRunner.runProcess(commandLine);
        })(<String>['this_executable_better_not_exist_2857632534321']),
        throwsA(isA<PreparePackageException>()));

    await expectLater(
      () => processRunner.runProcess(<String>['this_executable_better_not_exist_2857632534321']),
      throwsA(isA<PreparePackageException>().having(
        (PreparePackageException error) => error.message,
        'message',
        contains('ProcessException: Failed to find "this_executable_better_not_exist_2857632534321" in the search path'),
      )),
    );
  });
  for (final String platformName in <String>[Platform.macOS, Platform.linux, Platform.windows]) {
    final FakePlatform platform = FakePlatform(
      operatingSystem: platformName,
      environment: <String, String>{
        'DEPOT_TOOLS': platformName == Platform.windows ? path.join('D:', 'depot_tools'): '/depot_tools',
      },
    );
    group('ProcessRunner for $platform', () {
      test('Returns stdout', () async {
        final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['echo', 'test',],
            stdout: 'output',
            stderr: 'error',
          ),
        ]);
        final ProcessRunner processRunner = ProcessRunner(
          subprocessOutput: false,
          platform: platform,
          processManager: fakeProcessManager,
          printError: ([Object? _]) {},
        );
        final String output = await processRunner.runProcess(<String>['echo', 'test']);
        expect(output, equals('output'));
      });
      test('Throws on process failure', () async {
        final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>['echo', 'test',],
            stdout: 'output',
            stderr: 'error',
            exitCode: -1,
          ),
        ]);
        final ProcessRunner processRunner = ProcessRunner(
          subprocessOutput: false,
          platform: platform,
          processManager: fakeProcessManager,
          printError: ([Object? _]) {},
        );
        expect(
            expectAsync1((List<String> commandLine) async {
              return processRunner.runProcess(commandLine);
            })(<String>['echo', 'test']),
            throwsA(isA<PreparePackageException>()));
      });
    });

    group('ArchiveCreator for $platformName', () {
      late ArchiveCreator creator;
      late Directory tempDir;
      Directory flutterDir;
      Directory cacheDir;
      late FakeProcessManager processManager;
      late FileSystem fs;
      final List<List<String>> args = <List<String>>[];
      final List<Map<Symbol, dynamic>> namedArgs = <Map<Symbol, dynamic>>[];
      late String flutter;
      late String dart;

      Future<Uint8List> fakeHttpReader(Uri url, {Map<String, String>? headers}) {
        return Future<Uint8List>.value(Uint8List(0));
      }

      setUp(() async {
        processManager = FakeProcessManager.list(<FakeCommand>[]);
        args.clear();
        namedArgs.clear();
        fs = MemoryFileSystem.test();
        tempDir = fs.systemTempDirectory;
        flutterDir = fs.directory(path.join(tempDir.path, 'flutter'));
        flutterDir.createSync(recursive: true);
        cacheDir = fs.directory(path.join(flutterDir.path, 'bin', 'cache'));
        cacheDir.createSync(recursive: true);
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.beta,
          fs: fs,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        flutter = path.join(creator.flutterRoot.absolute.path,
          'bin', 'flutter');
        dart = path.join(creator.flutterRoot.absolute.path,
          'bin', 'cache', 'dart-sdk', 'bin', 'dart');
      });

      tearDown(() async {
        tryToDelete(tempDir);
      });

      test('sets PUB_CACHE properly', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-beta${platform.isLinux ? '.tar.xz' : '.zip'}');

        processManager.addCommands(convertResults(<(String, ProcessResult?)>[
          ('git clone -b beta https://flutter.googlesource.com/mirrors/flutter', null),
          ('git reset --hard $testRef', null),
          ('git remote set-url origin https://github.com/flutter/flutter.git', null),
          ('git gc --prune=now --aggressive', null),
          ('git describe --tags --exact-match $testRef', ProcessResult(0, 0, 'v1.2.3', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$dart --version', ProcessResult(0, 0, 'Dart SDK version: 2.17.0-63.0.beta (beta) (Wed Jan 26 03:48:52 2022 -0800) on "${platformName}_x64"', '')),
          if (platform.isWindows) ('7za x ${path.join(tempDir.path, 'mingit.zip')}', null),
          ('$flutter doctor', null),
          ('$flutter update-packages', null),
          ('$flutter precache', null),
          ('$flutter ide-config', null),
          ('$flutter create --template=app ${createBase}app', null),
          ('$flutter create --template=package ${createBase}package', null),
          ('$flutter create --template=plugin ${createBase}plugin', null),
          ('$flutter pub cache list', ProcessResult(0,0,'{"packages":{}}','')),
          ('git clean -f -x -- **/.packages', null),
          ('git clean -f -x -- **/.dart_tool/', null),
          if (platform.isMacOS) ('codesign -vvvv --check-notarization ${path.join(tempDir.path, 'flutter', 'bin', 'cache', 'dart-sdk', 'bin', 'dart')}', null),
          if (platform.isWindows) ('attrib -h .git', null),
          if (platform.isWindows) ('7za a -tzip -mx=9 $archiveName flutter', null)
          else if (platform.isMacOS) ('zip -r -9 --symlinks $archiveName flutter', null)
          else if (platform.isLinux) ('tar cJf $archiveName --verbose flutter', null),
 ]));
        await creator.initializeRepo();
        await creator.createArchive();
      });

      test('calls the right commands for archive output', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-beta${platform.isLinux ? '.tar.xz' : '.zip'}');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('git clone -b beta https://flutter.googlesource.com/mirrors/flutter', null),
          ('git reset --hard $testRef', null),
          ('git remote set-url origin https://github.com/flutter/flutter.git', null),
          ('git gc --prune=now --aggressive', null),
          ('git describe --tags --exact-match $testRef', ProcessResult(0, 0, 'v1.2.3', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$dart --version', ProcessResult(0, 0, 'Dart SDK version: 2.17.0-63.0.beta (beta) (Wed Jan 26 03:48:52 2022 -0800) on "${platformName}_x64"', '')),
          if (platform.isWindows) ('7za x ${path.join(tempDir.path, 'mingit.zip')}', null),
          ('$flutter doctor', null),
          ('$flutter update-packages', null),
          ('$flutter precache', null),
          ('$flutter ide-config', null),
          ('$flutter create --template=app ${createBase}app', null),
          ('$flutter create --template=package ${createBase}package', null),
          ('$flutter create --template=plugin ${createBase}plugin', null),
          ('$flutter pub cache list', ProcessResult(0,0,'{"packages":{}}','')),
          ('git clean -f -x -- **/.packages', null),
          ('git clean -f -x -- **/.dart_tool/', null),
          if (platform.isMacOS) ('codesign -vvvv --check-notarization ${path.join(tempDir.path, 'flutter', 'bin', 'cache', 'dart-sdk', 'bin', 'dart')}', null),
          if (platform.isWindows) ('attrib -h .git', null),
          if (platform.isWindows) ('7za a -tzip -mx=9 $archiveName flutter', null)
          else if (platform.isMacOS) ('zip -r -9 --symlinks $archiveName flutter', null)
          else if (platform.isLinux) ('tar cJf $archiveName --verbose flutter', null),
 ];
        processManager.addCommands(convertResults(calls));
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.beta,
          fs: fs,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();
        await creator.createArchive();
      });

      test('adds the arch name to the archive for non-x64', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_arm64_v1.2.3-beta${platform.isLinux ? '.tar.xz' : '.zip'}');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('git clone -b beta https://flutter.googlesource.com/mirrors/flutter', null),
          ('git reset --hard $testRef', null),
          ('git remote set-url origin https://github.com/flutter/flutter.git', null),
          ('git gc --prune=now --aggressive', null),
          ('git describe --tags --exact-match $testRef', ProcessResult(0, 0, 'v1.2.3', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$dart --version', ProcessResult(0, 0, 'Dart SDK version: 2.17.0-63.0.beta (beta) (Wed Jan 26 03:48:52 2022 -0800) on "${platformName}_arm64"', '')),
          if (platform.isWindows) ('7za x ${path.join(tempDir.path, 'mingit.zip')}', null),
          ('$flutter doctor', null),
          ('$flutter update-packages', null),
          ('$flutter precache', null),
          ('$flutter ide-config', null),
          ('$flutter create --template=app ${createBase}app', null),
          ('$flutter create --template=package ${createBase}package', null),
          ('$flutter create --template=plugin ${createBase}plugin', null),
          ('$flutter pub cache list', ProcessResult(0,0,'{"packages":{}}','')),
          ('git clean -f -x -- **/.packages', null),
          ('git clean -f -x -- **/.dart_tool/', null),
          if (platform.isMacOS) ('codesign -vvvv --check-notarization ${path.join(tempDir.path, 'flutter', 'bin', 'cache', 'dart-sdk', 'bin', 'dart')}', null),
          if (platform.isWindows) ('attrib -h .git', null),
          if (platform.isWindows) ('7za a -tzip -mx=9 $archiveName flutter', null)
          else if (platform.isMacOS) ('zip -r -9 --symlinks $archiveName flutter', null)
          else if (platform.isLinux) ('tar cJf $archiveName --verbose flutter', null),
        ];
        processManager.addCommands(convertResults(calls));
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.beta,
          fs: fs,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();
        await creator.createArchive();
      });

      test('throws when a command errors out', () async {
        final List<(String, ProcessResult)> calls = <(String, ProcessResult)>[
          ('git clone -b beta https://flutter.googlesource.com/mirrors/flutter', ProcessResult(0, 0, 'output1', '')),
          ('git reset --hard $testRef', ProcessResult(0, -1, 'output2', '')),
 ];
        processManager.addCommands(convertResults(calls));
        expect(expectAsync0(creator.initializeRepo), throwsA(isA<PreparePackageException>()));
      });

      test('non-strict mode calls the right commands', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-beta${platform.isLinux ? '.tar.xz' : '.zip'}');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('git clone -b beta https://flutter.googlesource.com/mirrors/flutter', null),
          ('git reset --hard $testRef', null),
          ('git remote set-url origin https://github.com/flutter/flutter.git', null),
          ('git gc --prune=now --aggressive', null),
          ('git describe --tags --abbrev=0 $testRef', ProcessResult(0, 0, 'v1.2.3', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$dart --version', ProcessResult(0, 0, 'Dart SDK version: 2.17.0-63.0.beta (beta) (Wed Jan 26 03:48:52 2022 -0800) on "${platformName}_x64"', '')),
          if (platform.isWindows) ('7za x ${path.join(tempDir.path, 'mingit.zip')}', null),
          ('$flutter doctor', null),
          ('$flutter update-packages', null),
          ('$flutter precache', null),
          ('$flutter ide-config', null),
          ('$flutter create --template=app ${createBase}app', null),
          ('$flutter create --template=package ${createBase}package', null),
          ('$flutter create --template=plugin ${createBase}plugin', null),
          ('$flutter pub cache list', ProcessResult(0,0,'{"packages":{}}','')),
          ('git clean -f -x -- **/.packages', null),
          ('git clean -f -x -- **/.dart_tool/', null),
          if (platform.isWindows) ('attrib -h .git', null),
          if (platform.isWindows) ('7za a -tzip -mx=9 $archiveName flutter', null)
          else if (platform.isMacOS) ('zip -r -9 --symlinks $archiveName flutter', null)
          else if (platform.isLinux) ('tar cJf $archiveName --verbose flutter', null),
        ];
        processManager.addCommands(convertResults(calls));
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.beta,
          fs: fs,
          strict: false,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();
        await creator.createArchive();
      });

      test('fails if binary is not codesigned', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-beta${platform.isLinux ? '.tar.xz' : '.zip'}');
        final ProcessResult codesignFailure = ProcessResult(1, 1, '', 'code object is not signed at all');
        final String binPath = path.join(tempDir.path, 'flutter', 'bin', 'cache', 'dart-sdk', 'bin', 'dart');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('git clone -b beta https://flutter.googlesource.com/mirrors/flutter', null),
          ('git reset --hard $testRef', null),
          ('git remote set-url origin https://github.com/flutter/flutter.git', null),
          ('git gc --prune=now --aggressive', null),
          ('git describe --tags --exact-match $testRef', ProcessResult(0, 0, 'v1.2.3', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$flutter --version --machine', ProcessResult(0, 0, '{"dartSdkVersion": "3.2.1"}', '')),
          ('$dart --version', ProcessResult(0, 0, 'Dart SDK version: 2.17.0-63.0.beta (beta) (Wed Jan 26 03:48:52 2022 -0800) on "${platformName}_x64"', '')),
          if (platform.isWindows) ('7za x ${path.join(tempDir.path, 'mingit.zip')}', null),
          ('$flutter doctor', null),
          ('$flutter update-packages', null),
          ('$flutter precache', null),
          ('$flutter ide-config', null),
          ('$flutter create --template=app ${createBase}app', null),
          ('$flutter create --template=package ${createBase}package', null),
          ('$flutter create --template=plugin ${createBase}plugin', null),
          ('$flutter pub cache list', ProcessResult(0,0,'{"packages":{}}','')),
          ('git clean -f -x -- **/.packages', null),
          ('git clean -f -x -- **/.dart_tool/', null),
          if (platform.isMacOS) ('codesign -vvvv --check-notarization $binPath', codesignFailure),
          if (platform.isWindows) ('attrib -h .git', null),
          if (platform.isWindows) ('7za a -tzip -mx=9 $archiveName flutter', null)
          else if (platform.isMacOS) ('zip -r -9 --symlinks $archiveName flutter', null)
          else if (platform.isLinux) ('tar cJf $archiveName flutter', null),
        ];
        processManager.addCommands(convertResults(calls));
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.beta,
          fs: fs,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();

        await expectLater(
          () => creator.createArchive(),
          throwsA(isA<PreparePackageException>().having(
            (PreparePackageException exception) => exception.message,
            'message',
            contains('The binary $binPath was not codesigned!'),
          )),
        );
      }, skip: !platform.isMacOS); // [intended] codesign is only available on macOS
    });

    group('ArchivePublisher for $platformName', () {
      late FakeProcessManager processManager;
      late Directory tempDir;
      late FileSystem fs;
      final String gsutilCall = platform.isWindows
          ? 'python3 ${path.join("D:", "depot_tools", "gsutil.py")}'
          : 'python3 ${path.join("/", "depot_tools", "gsutil.py")}';
      final String releasesName = 'releases_$platformName.json';
      final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
      final String archiveMime = platform.isLinux ? 'application/x-gtar' : 'application/zip';
      final String gsArchivePath = 'gs://flutter_infra_release/releases/stable/$platformName/$archiveName';

      setUp(() async {
        fs = MemoryFileSystem.test(style: platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix);
        processManager = FakeProcessManager.list(<FakeCommand>[]);
        tempDir = fs.systemTempDirectory.createTempSync('flutter_prepage_package_test.');
      });

      tearDown(() async {
        tryToDelete(tempDir);
      });

      test('calls the right processes', () async {
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final String releasesJson = '''
{
  "base_url": "https://storage.googleapis.com/flutter_infra_release/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "beta": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0",
      "channel": "beta",
      "version": "v0.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.3-beta.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8",
      "dart_sdk_arch": "x64"
    },
    {
      "hash": "b9bd51cc36b706215915711e580851901faebb40",
      "channel": "beta",
      "version": "v0.2.2",
      "release_date": "2018-03-16T18:48:13.375013Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.2-beta.zip",
      "sha256": "6073331168cdb37a4637a5dc073d6a7ef4e466321effa2c529fa27d2253a4d4b",
      "dart_sdk_arch": "x64"
    },
    {
      "hash": "$testRef",
      "channel": "stable",
      "version": "v0.0.0",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "stable/$platformName/flutter_${platformName}_v0.0.0-beta.zip",
      "sha256": "5dd34873b3a3e214a32fd30c2c319a0f46e608afb72f0d450b2d621a6d02aebd",
      "dart_sdk_arch": "x64"
    }
  ]
}
''';
        fs.file(jsonPath).writeAsStringSync(releasesJson);
        fs.file(archivePath).writeAsStringSync('archive contents');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          // This process fails because the file does NOT already exist
          ('$gsutilCall -- stat $gsArchivePath', ProcessResult(0, 1, '', '')),
          ('$gsutilCall -- rm $gsArchivePath', null),
          ('$gsutilCall -- -h Content-Type:$archiveMime cp $archivePath $gsArchivePath', null),
          ('$gsutilCall -- rm $gsJsonPath', null),
          ('$gsutilCall -- -h Content-Type:application/json -h Cache-Control:max-age=60 cp $jsonPath $gsJsonPath', null),
        ];
        processManager.addCommands(convertResults(calls));
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        outputFile.createSync();
        assert(tempDir.existsSync());
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'x64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        assert(tempDir.existsSync());
        final MetadataFile file = await publisher.generateLocalMetadata();
        await publisher.publishArchive(file);

        final File releaseFile = fs.file(jsonPath);
        expect(releaseFile.existsSync(), isTrue);
        final String contents = releaseFile.readAsStringSync();
        // Make sure new data is added.
        expect(contents, contains('"hash": "$testRef"'));
        expect(contents, contains('"channel": "stable"'));
        expect(contents, contains('"archive": "stable/$platformName/$archiveName"'));
        expect(contents, contains('"sha256": "f69f4865f861193a91d1c5544a894167a7137b788d10bac8edbf5d095f45cb4d"'));
        // Make sure existing entries are preserved.
        expect(contents, contains('"hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"'));
        expect(contents, contains('"hash": "b9bd51cc36b706215915711e580851901faebb40"'));
        expect(contents, contains('"channel": "beta"'));
        expect(contents, contains('"channel": "beta"'));
        // Make sure old matching entries are removed.
        expect(contents, isNot(contains('v0.0.0')));
        final Map<String, dynamic> jsonData = json.decode(contents) as Map<String, dynamic>;
        final List<dynamic> releases = jsonData['releases'] as List<dynamic>;
        expect(releases.length, equals(3));
        // Make sure the new entry is first (and hopefully it takes less than a
        // minute to go from publishArchive above to this line!).
        expect(
          DateTime.now().difference(DateTime.parse((releases[0] as Map<String, dynamic>)['release_date'] as String)),
          lessThan(const Duration(minutes: 1)),
        );
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        expect(contents, equals(encoder.convert(jsonData)));
      });

      test('contains Dart SDK version info', () async {
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final String releasesJson = '''
{
  "base_url": "https://storage.googleapis.com/flutter_infra_release/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "beta": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0",
      "channel": "beta",
      "version": "v0.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.3-beta.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8"
    },
    {
      "hash": "b9bd51cc36b706215915711e580851901faebb40",
      "channel": "beta",
      "version": "v0.2.2",
      "release_date": "2018-03-16T18:48:13.375013Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.2-beta.zip",
      "sha256": "6073331168cdb37a4637a5dc073d6a7ef4e466321effa2c529fa27d2253a4d4b"
    },
    {
      "hash": "$testRef",
      "channel": "stable",
      "version": "v0.0.0",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "stable/$platformName/flutter_${platformName}_v0.0.0-beta.zip",
      "sha256": "5dd34873b3a3e214a32fd30c2c319a0f46e608afb72f0d450b2d621a6d02aebd"
    }
  ]
}
''';
        fs.file(jsonPath).writeAsStringSync(releasesJson);
        fs.file(archivePath).writeAsStringSync('archive contents');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          // This process fails because the file does NOT already exist
          ('$gsutilCall -- stat $gsArchivePath', ProcessResult(0, 1, '', '')),
          ('$gsutilCall -- rm $gsArchivePath', null),
          ('$gsutilCall -- -h Content-Type:$archiveMime cp $archivePath $gsArchivePath', null),
          ('$gsutilCall -- rm $gsJsonPath', null),
          ('$gsutilCall -- -h Content-Type:application/json -h Cache-Control:max-age=60 cp $jsonPath $gsJsonPath', null),
        ];
        processManager.addCommands(convertResults(calls));
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        outputFile.createSync();
        assert(tempDir.existsSync());
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'x64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        assert(tempDir.existsSync());
        final MetadataFile file = await publisher.generateLocalMetadata();
        await publisher.publishArchive(file);

        final File releaseFile = fs.file(jsonPath);
        expect(releaseFile.existsSync(), isTrue);
        final String contents = releaseFile.readAsStringSync();
        expect(contents, contains('"dart_sdk_version": "3.2.1"'));
        expect(contents, contains('"dart_sdk_arch": "x64"'));
      });

      test('Supports multiple architectures', () async {
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final String releasesJson = '''
{
  "base_url": "https://storage.googleapis.com/flutter_infra_release/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "beta": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
      "channel": "stable",
      "version": "v1.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.3-beta.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8",
      "dart_sdk_arch": "x64"
    }
  ]
}
''';
        fs.file(jsonPath).writeAsStringSync(releasesJson);
        fs.file(archivePath).writeAsStringSync('archive contents');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          // This process fails because the file does NOT already exist
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- stat $gsArchivePath', ProcessResult(0, 1, '', '')),
          ('$gsutilCall -- rm $gsArchivePath', null),
          ('$gsutilCall -- -h Content-Type:$archiveMime cp $archivePath $gsArchivePath', null),
          ('$gsutilCall -- rm $gsJsonPath', null),
          ('$gsutilCall -- -h Content-Type:application/json -h Cache-Control:max-age=60 cp $jsonPath $gsJsonPath', null),
        ];
        processManager.addCommands(convertResults(calls));
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        outputFile.createSync();
        assert(tempDir.existsSync());
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'arm64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        assert(tempDir.existsSync());
        final MetadataFile file = await publisher.generateLocalMetadata();
        await publisher.publishArchive(file);

        final File releaseFile = fs.file(jsonPath);
        expect(releaseFile.existsSync(), isTrue);
        final String contents = releaseFile.readAsStringSync();
        final Map<String, dynamic> releases = jsonDecode(contents) as Map<String, dynamic>;
        expect((releases['releases'] as List<dynamic>).length, equals(2));
      });


      test('updates base_url from old bucket to new bucket', () async {
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final String releasesJson = '''
{
  "base_url": "https://storage.googleapis.com/flutter_infra_release/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "beta": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0",
      "channel": "beta",
      "version": "v0.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.3-beta.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8"
    },
    {
      "hash": "b9bd51cc36b706215915711e580851901faebb40",
      "channel": "beta",
      "version": "v0.2.2",
      "release_date": "2018-03-16T18:48:13.375013Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.2-beta.zip",
      "sha256": "6073331168cdb37a4637a5dc073d6a7ef4e466321effa2c529fa27d2253a4d4b"
    },
    {
      "hash": "$testRef",
      "channel": "stable",
      "version": "v0.0.0",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "stable/$platformName/flutter_${platformName}_v0.0.0-beta.zip",
      "sha256": "5dd34873b3a3e214a32fd30c2c319a0f46e608afb72f0d450b2d621a6d02aebd"
    }
  ]
}
''';
        fs.file(jsonPath).writeAsStringSync(releasesJson);
        fs.file(archivePath).writeAsStringSync('archive contents');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          // This process fails because the file does NOT already exist
          ('$gsutilCall -- stat $gsArchivePath', ProcessResult(0, 1, '', '')),
          ('$gsutilCall -- rm $gsArchivePath', null),
          ('$gsutilCall -- -h Content-Type:$archiveMime cp $archivePath $gsArchivePath', null),
          ('$gsutilCall -- rm $gsJsonPath', null),
          ('$gsutilCall -- -h Content-Type:application/json -h Cache-Control:max-age=60 cp $jsonPath $gsJsonPath', null),
        ];
        processManager.addCommands(convertResults(calls));
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        outputFile.createSync();
        assert(tempDir.existsSync());
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'x64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        assert(tempDir.existsSync());
        final MetadataFile file = await publisher.generateLocalMetadata();
        await publisher.publishArchive(file);

        final File releaseFile = fs.file(jsonPath);
        expect(releaseFile.existsSync(), isTrue);
        final String contents = releaseFile.readAsStringSync();
        final Map<String, dynamic> jsonData = json.decode(contents) as Map<String, dynamic>;
        expect(jsonData['base_url'], 'https://storage.googleapis.com/flutter_infra_release/releases');
      });

      test('publishArchive throws if forceUpload is false and artifact already exists on cloud storage', () async {
        final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'x64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        final List<(String, ProcessResult)> calls = <(String, ProcessResult)>[
          // This process returns 0 because file already exists
          ('$gsutilCall -- stat $gsArchivePath', ProcessResult(0, 0, '', '')),
        ];
        processManager.addCommands(convertResults(calls));
        final MetadataFile file = MetadataFile(
          remotePath: gsArchivePath,
          localFile: outputFile,
          generation: 1,
          publisher: publisher,
        );
        await expectLater(
          () => publisher.publishArchive(file),
          throwsA(isA<Exception>().having(
            (Exception exc) => exc.toString(),
            'message',
            contains('already exists on cloud storage!'),
          )),
        );
        print('done');
      });

      test('publishArchive does not throw if forceUpload is true and artifact already exists on cloud storage', () async {
        final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          const <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'x64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final String releasesJson = '''
{
  "base_url": "https://storage.googleapis.com/flutter_infra_release/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "beta": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0",
      "channel": "beta",
      "version": "v0.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.3-beta.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8"
    },
    {
      "hash": "b9bd51cc36b706215915711e580851901faebb40",
      "channel": "beta",
      "version": "v0.2.2",
      "release_date": "2018-03-16T18:48:13.375013Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.2-beta.zip",
      "sha256": "6073331168cdb37a4637a5dc073d6a7ef4e466321effa2c529fa27d2253a4d4b"
    },
    {
      "hash": "$testRef",
      "channel": "stable",
      "version": "v0.0.0",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "stable/$platformName/flutter_${platformName}_v0.0.0-beta.zip",
      "sha256": "5dd34873b3a3e214a32fd30c2c319a0f46e608afb72f0d450b2d621a6d02aebd"
    }
  ]
}
''';
        fs.file(jsonPath).writeAsStringSync(releasesJson);
        fs.file(archivePath).writeAsStringSync('archive contents');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput()),
          ('$gsutilCall -- rm $gsArchivePath', null),
          ('$gsutilCall -- -h Content-Type:$archiveMime cp $archivePath $gsArchivePath', null),
          ('$gsutilCall -- rm $gsJsonPath', null),
          ('$gsutilCall -- -h Content-Type:application/json -h Cache-Control:max-age=60 cp $jsonPath $gsJsonPath', null),
 ];
        processManager.addCommands(convertResults(calls));
        assert(tempDir.existsSync());
        final MetadataFile file = await publisher.generateLocalMetadata();
        await publisher.publishArchive(file, true);
      });

      test('ArchivePublisher will retry once if the generation of the remote metadata file changes', () async {
        final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        const Map<String, String> newVersion = <String, String>{
          'frameworkVersionFromGit': 'v1.2.3',
          'dartSdkVersion': '3.2.1',
          'dartTargetArch': 'x64',
        };
        final StringBuffer errorBuffer = StringBuffer();
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          newVersion,
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
          printError: errorBuffer.writeln,
        );
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final String releasesJson = '''
{
  "base_url": "https://storage.googleapis.com/flutter_infra_release/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "beta": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0",
      "channel": "beta",
      "version": "v0.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.3-beta.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8"
    },
    {
      "hash": "b9bd51cc36b706215915711e580851901faebb40",
      "channel": "beta",
      "version": "v0.2.2",
      "release_date": "2018-03-16T18:48:13.375013Z",
      "archive": "beta/$platformName/flutter_${platformName}_v0.2.2-beta.zip",
      "sha256": "6073331168cdb37a4637a5dc073d6a7ef4e466321effa2c529fa27d2253a4d4b"
    },
    {
      "hash": "$testRef",
      "channel": "stable",
      "version": "v0.0.0",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "stable/$platformName/flutter_${platformName}_v0.0.0-beta.zip",
      "sha256": "5dd34873b3a3e214a32fd30c2c319a0f46e608afb72f0d450b2d621a6d02aebd"
    }
  ]
}
''';
        fs.file(jsonPath).writeAsStringSync(releasesJson);
        fs.file(archivePath).writeAsStringSync('archive contents');
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          // First attempt
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(1)),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(2)),
          // Second attempt
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(2)),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(2)),
        ];
        processManager.addCommands(convertResults(calls));
        final MetadataFile metadataFile = await publisher.generateLocalMetadata();
        expect(processManager, hasNoRemainingExpectations);
        final String metadataContents = metadataFile.localFile.readAsStringSync();
        final List<Object?> releases = (jsonDecode(metadataContents) as Map<String, Object?>)['releases']! as List<Object?>;
        final Map<String, Object?> firstRelease = releases.first! as Map<String, Object?>;
        expect(firstRelease['version'], newVersion['frameworkVersionFromGit']);
        expect(firstRelease['dart_sdk_version'], newVersion['dartSdkVersion']);
        expect(firstRelease['dart_sdk_arch'], newVersion['dartTargetArch']);
        expect(
          errorBuffer.toString(),
          contains(RegExp(
            'Error! The file $gsJsonPath was at generation 1 before downloading,\\s+'
            'but generation 2 after on attempt 0',
          )),
        );
      });

      test('ArchivePublisher throws StateError if the generation of the remote metadata file changes twice', () async {
        final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
        final File outputFile = fs.file(path.join(tempDir.absolute.path, archiveName));
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          const <String, String>{
            'frameworkVersionFromGit': 'v1.2.3',
            'dartSdkVersion': '3.2.1',
            'dartTargetArch': 'x64',
          },
          outputFile,
          false,
          fs: fs,
          processManager: processManager,
          platform: platform,
        );
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra_release/releases/$releasesName';
        final List<(String, ProcessResult?)> calls = <(String, ProcessResult?)>[
          // First attempt
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(1)),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(2)),
          // Second attempt
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(2)),
          ('$gsutilCall -- cp $gsJsonPath $jsonPath', null),
          ('$gsutilCall -- stat $gsJsonPath', generateStatOutput(3)),
        ];
        processManager.addCommands(convertResults(calls));
        await expectLater(
          () => publisher.generateLocalMetadata(),
          throwsA(isA<StateError>().having(
            (StateError exc) => exc.message,
            'message',
            contains('The generation number of the file $gsJsonPath was changed by another process'),
          )),
        );
        expect(processManager, hasNoRemainingExpectations);
      });
    });
  }
}

List<FakeCommand> convertResults(List<(String, ProcessResult?)> results) {
  final List<FakeCommand> commands = <FakeCommand>[];
  for (final (String key, ProcessResult? candidate) in results) {
    final List<String> args = key.split(' ');
    if (candidate == null) {
      commands.add(FakeCommand(
        command: args,
      ));
    } else {
      commands.add(FakeCommand(
        command: args,
        exitCode: candidate.exitCode,
        stderr: candidate.stderr.toString(),
        stdout: candidate.stdout.toString(),
      ));
    }
  }
  return commands;
}
