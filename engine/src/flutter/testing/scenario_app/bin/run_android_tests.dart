// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:dir_contents_diff/dir_contents_diff.dart' show dirContentsDiff;
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';
import 'package:skia_gold_client/skia_gold_client.dart';

import 'utils/adb_logcat_filtering.dart';
import 'utils/logs.dart';
import 'utils/process_manager_extension.dart';
import 'utils/screenshot_transformer.dart';

void _withTemporaryCwd(String path, void Function() callback) {
  final String originalCwd = Directory.current.path;
  Directory.current = Directory(path).parent.path;

  try {
    callback();
  } finally {
    Directory.current = originalCwd;
  }
}

// If you update the arguments, update the documentation in the README.md file.
void main(List<String> args) async {
  final Engine? engine = Engine.tryFindWithin();
  final ArgParser parser = ArgParser()
    ..addFlag(
      'help',
      help: 'Prints usage information',
      negatable: false,
    )
    ..addFlag(
      'verbose',
      help: 'Prints verbose output',
      negatable: false,
    )
    ..addOption(
      'adb',
      help: 'Path to the adb tool',
      defaultsTo: engine != null ? join(
        engine.srcDir.path,
        'third_party',
        'android_tools',
        'sdk',
        'platform-tools',
        'adb',
      ) : null,
    )
    ..addOption(
      'ndk-stack',
      help: 'Path to the ndk-stack tool',
      defaultsTo: engine != null ? join(
        engine.srcDir.path,
        'third_party',
        'android_tools',
        'ndk',
        'prebuilt',
        () {
          if (Platform.isLinux) {
            return 'linux-x86_64';
          } else if (Platform.isMacOS) {
            return 'darwin-x86_64';
          } else if (Platform.isWindows) {
            return 'windows-x86_64';
          } else {
            throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
          }
        }(),
        'bin',
        'ndk-stack',
      ) : null,
    )
    ..addOption(
      'out-dir',
      help: 'Out directory',
      defaultsTo:
        engine?.
        outputs().
        where((Output o) => basename(o.path.path).startsWith('android_')).
        firstOrNull?.
        path.path,
    )
    ..addOption(
      'smoke-test',
      help: 'Runs a single test to verify the setup',
    )
    ..addFlag(
      'use-skia-gold',
      help: 'Use Skia Gold to compare screenshots.',
      defaultsTo: isLuciEnv,
    )
    ..addFlag(
      'enable-impeller',
      help: 'Enable Impeller for the Android app.',
    )
    ..addOption(
      'output-contents-golden',
      help: 'Path to a file that contains the expected filenames of golden files.',
      defaultsTo: engine != null ? join(
        engine.srcDir.path,
        'flutter',
        'testing',
        'scenario_app',
        'android',
        'expected_golden_output.txt',
      ) : null,
    )
    ..addOption(
      'impeller-backend',
      help: 'The Impeller backend to use for the Android app.',
      allowed: <String>['vulkan', 'opengles'],
      defaultsTo: 'vulkan',
    )
    ..addOption(
      'logs-dir',
      help: 'The directory to store the logs and screenshots. Defaults to '
            'the value of the FLUTTER_LOGS_DIR environment variable, if set, '
            'otherwise it defaults to a path within out-dir.',
      defaultsTo: Platform.environment['FLUTTER_LOGS_DIR'],
    );

  runZonedGuarded(
    () async {
      final ArgResults results = parser.parse(args);
      if (results['help'] as bool) {
        stdout.writeln(parser.usage);
        return;
      }

      if (results['out-dir'] == null) {
        panic(<String>['--out-dir is required']);
      }
      if (results['adb'] == null) {
        panic(<String>['--adb is required']);
      }

      final bool verbose = results['verbose'] as bool;
      final Directory outDir = Directory(results['out-dir'] as String);
      final File adb = File(results['adb'] as String);
      final bool useSkiaGold = results['use-skia-gold'] as bool;
      final String? smokeTest = results['smoke-test'] as String?;
      final bool enableImpeller = results['enable-impeller'] as bool;
      final String? contentsGolden = results['output-contents-golden'] as String?;
      final _ImpellerBackend? impellerBackend = _ImpellerBackend.tryParse(results['impeller-backend'] as String?);
      if (enableImpeller && impellerBackend == null) {
        panic(<String>['invalid graphics-backend', results['impeller-backend'] as String? ?? '<null>']);
      }
      final Directory logsDir = Directory(results['logs-dir'] as String? ?? join(outDir.path, 'scenario_app', 'logs'));
      final String? ndkStack = results['ndk-stack'] as String?;
      if (ndkStack == null) {
        panic(<String>['--ndk-stack is required']);
      }
      await _run(
        verbose: verbose,
        outDir: outDir,
        adb: adb,
        smokeTestFullPath: smokeTest,
        useSkiaGold: useSkiaGold,
        enableImpeller: enableImpeller,
        impellerBackend: impellerBackend,
        logsDir: logsDir,
        contentsGolden: contentsGolden,
        ndkStack: ndkStack,
      );
      exit(0);
    },
    (Object error, StackTrace stackTrace) {
      if (error is! Panic) {
        stderr.writeln(error);
        stderr.writeln(stackTrace);
      }
      exit(1);
    },
  );
}

const int _tcpPort = 3001;

enum _ImpellerBackend {
  vulkan,
  opengles;

  static _ImpellerBackend? tryParse(String? value) {
    for (final _ImpellerBackend backend in _ImpellerBackend.values) {
      if (backend.name == value) {
        return backend;
      }
    }
    return null;
  }
}

Future<void> _run({
  required bool verbose,
  required Directory outDir,
  required File adb,
  required String? smokeTestFullPath,
  required bool useSkiaGold,
  required bool enableImpeller,
  required _ImpellerBackend? impellerBackend,
  required Directory logsDir,
  required String? contentsGolden,
  required String ndkStack,
}) async {
  const ProcessManager pm = LocalProcessManager();

  if (!outDir.existsSync()) {
    panic(<String>['out-dir does not exist: $outDir', 'make sure to build the selected engine variant']);
  }

  if (!adb.existsSync()) {
    panic(<String>['cannot find adb: $adb', 'make sure to run gclient sync']);
  }

  final String scenarioAppPath = join(outDir.path, 'scenario_app');
  final String logcatPath = join(logsDir.path, 'logcat.txt');

  // TODO(matanlurey): Use screenshots/ sub-directory (https://github.com/flutter/flutter/issues/143604).
  if (!logsDir.existsSync()) {
    logsDir.createSync(recursive: true);
  }
  final String screenshotPath = logsDir.path;
  final String apkOutPath = join(scenarioAppPath, 'app', 'outputs', 'apk');
  final File testApk = File(join(apkOutPath, 'androidTest', 'debug', 'app-debug-androidTest.apk'));
  final File appApk = File(join(apkOutPath, 'debug', 'app-debug.apk'));
  log('writing logs and screenshots to ${logsDir.path}');

  if (!testApk.existsSync()) {
    panic(<String>['test apk does not exist: ${testApk.path}', 'make sure to build the selected engine variant']);
  }

  if (!appApk.existsSync()) {
    panic(<String>['app apk does not exist: ${appApk.path}', 'make sure to build the selected engine variant']);
  }

  // Start a TCP socket in the host, and forward it to the device that runs the tests.
  // This allows the test process to start a connection with the host, and write the bytes
  // for the screenshots.
  // On LUCI, the host uploads the screenshots to Skia Gold.
  SkiaGoldClient? skiaGoldClient;
  late  ServerSocket server;
  final List<Future<void>> pendingComparisons = <Future<void>>[];
  await step('Starting server...', () async {
    server = await ServerSocket.bind(InternetAddress.anyIPv4, _tcpPort);
    if (verbose) {
      stdout.writeln('listening on host ${server.address.address}:${server.port}');
    }
    server.listen((Socket client) {
      if (verbose) {
        stdout.writeln('client connected ${client.remoteAddress.address}:${client.remotePort}');
      }
      client.transform(const ScreenshotBlobTransformer()).listen((Screenshot screenshot) {
        final String fileName = screenshot.filename;
        final Uint8List fileContent = screenshot.fileContent;
        if (verbose) {
          log('host received ${fileContent.lengthInBytes} bytes for screenshot `$fileName`');
        }
        assert(skiaGoldClient != null, 'expected Skia Gold client');
        late File goldenFile;
        try {
          goldenFile = File(join(screenshotPath, fileName))..writeAsBytesSync(fileContent, flush: true);
        } on FileSystemException catch (err) {
          panic(<String>['failed to create screenshot $fileName: $err']);
        }
        if (verbose) {
          log('wrote ${goldenFile.absolute.path}');
        }
        if (isSkiaGoldClientAvailable) {
          final Future<void> comparison = skiaGoldClient!
            .addImg(fileName, goldenFile,
                    screenshotSize: screenshot.pixelCount)
            .catchError((dynamic err) {
              panic(<String>['skia gold comparison failed: $err']);
            });
          pendingComparisons.add(comparison);
        }
      },
      onError: (dynamic err) {
        panic(<String>['error while receiving bytes: $err']);
      },
      cancelOnError: true);
    });
  });

  late Process logcatProcess;
  late Future<int> logcatProcessExitCode;

  final IOSink logcat = File(logcatPath).openWrite();
  try {
    await step('Creating screenshot directory `$screenshotPath`...', () async {
      Directory(screenshotPath).createSync(recursive: true);
    });

    await step('Starting logcat...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'logcat', '-c']);
      if (exitCode != 0) {
        panic(<String>['could not clear logs']);
      }

      logcatProcess = await pm.start(<String>[adb.path, 'logcat', '-T', '1']);
      final (Future<int> logcatExitCode, Stream<String> logcatOutput) = getProcessStreams(logcatProcess);

      logcatProcessExitCode = logcatExitCode;
      logcatOutput.listen((String line) {
        // Always write to the full log.
        logcat.writeln(line);

        // Conditionally parse and write to stderr.
        final AdbLogLine? adbLogLine = AdbLogLine.tryParse(line);
        switch (adbLogLine?.process) {
          case null:
            break;
          case 'ActivityManager':
            // These are mostly noise, i.e. "D ActivityManager: freezing 24632 com.blah".
            if (adbLogLine!.severity == 'D') {
              break;
            }
          // TODO(matanlurey): Figure out why this isn't 'flutter.scenario' or similar.
          // Also, why is there two different names?
          case 'utter.scenario':
          case 'utter.scenarios':
          case 'flutter':
          case 'FlutterJNI':
            log('[adb] $line');
        }
      });
    });

    await step('Configuring emulator...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'shell',
        'settings',
        'put',
        'secure',
        'immersive_mode_confirmations',
        'confirmed',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not configure emulator']);
      }
    });

    await step('Get API level of connected device...', () async {
      final ProcessResult apiLevelProcessResult = await pm.run(<String>[adb.path, 'shell', 'getprop', 'ro.build.version.sdk']);
      if (apiLevelProcessResult.exitCode != 0) {
        panic(<String>['could not get API level of the connected device']);
      }
      final String connectedDeviceAPILevel = (apiLevelProcessResult.stdout as String).trim();
      final Map<String, String> dimensions = <String, String>{
        'AndroidAPILevel': connectedDeviceAPILevel,
        'GraphicsBackend': enableImpeller ? 'impeller-${impellerBackend!.name}' : 'skia',
      };
      log('using dimensions: ${json.encode(dimensions)}');
      skiaGoldClient = SkiaGoldClient(
        outDir,
        dimensions: <String, String>{
          'AndroidAPILevel': connectedDeviceAPILevel,
          'GraphicsBackend': enableImpeller ? 'impeller-${impellerBackend!.name}' : 'skia',
        },
      );
    });

    await step('Skia Gold auth...', () async {
      if (isSkiaGoldClientAvailable) {
        await skiaGoldClient!.auth();
        log('skia gold client is available');
      } else {
        if (useSkiaGold) {
          panic(<String>['skia gold client is unavailable']);
        } else {
          log('skia gold client is unavaialble');
        }
      }
    });

    await step('Reverse port...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'reverse', 'tcp:3000', 'tcp:$_tcpPort']);
      if (exitCode != 0) {
        panic(<String>['could not forward port']);
      }
    });

    await step('Installing app APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'install', appApk.path]);
      if (exitCode != 0) {
        panic(<String>['could not install app apk']);
      }
    });

    await step('Installing test APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'install', testApk.path]);
      if (exitCode != 0) {
        panic(<String>['could not install test apk']);
      }
    });

    await step('Running instrumented tests...', () async {
      final (int exitCode, StringBuffer out) = await pm.runAndCapture(<String>[
        adb.path,
        'shell',
        'am',
        'instrument',
        '-w',
        if (smokeTestFullPath != null)
          '-e class $smokeTestFullPath',
        'dev.flutter.scenarios.test/dev.flutter.TestRunner',
        if (enableImpeller)
          '-e enable-impeller',
        if (impellerBackend != null)
          '-e impeller-backend ${impellerBackend.name}',
      ]);
      if (exitCode != 0) {
        panic(<String>['instrumented tests failed to run']);
      }
      // Unfortunately adb shell am instrument does not return a non-zero exit
      // code when tests fail, but it does seem to print "FAILURES!!!" to
      // stdout, so we can use that as a signal that something went wrong.
      if (out.toString().contains('FAILURES!!!')) {
        stdout.write(out);
        panic(<String>['1 or more tests failed']);
      }
    });
  } finally {
    await server.close();

    await step('Killing logcat process...', () async {
      final bool delivered = logcatProcess.kill(ProcessSignal.sigkill);
      assert(delivered);
      await logcatProcessExitCode;
    });

    await step('Flush logcat...', () async {
      await logcat.flush();
      await logcat.close();
      log('wrote logcat to $logcatPath');
    });

    await step('Symbolize stack traces', () async {
      final ProcessResult result = await pm.run(
        <String>[
          ndkStack,
          '-sym',
          outDir.path,
          '-dump',
          logcatPath,
        ],
      );
      if (result.exitCode != 0) {
        panic(<String>['Failed to symbolize stack traces']);
      }
    });

    await step('Remove reverse port...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'reverse',
        '--remove', 'tcp:3000',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not unforward port']);
      }
    });

    await step('Uninstalling app APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'uninstall', 'dev.flutter.scenarios']);
      if (exitCode != 0) {
        panic(<String>['could not uninstall app apk']);
      }
    });

    await step('Uninstalling test APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'uninstall', 'dev.flutter.scenarios.test']);
      if (exitCode != 0) {
        panic(<String>['could not uninstall app apk']);
      }
    });

    await step('Wait for Skia gold comparisons...', () async {
      await Future.wait(pendingComparisons);
    });

    if (contentsGolden != null) {
      // Check the output here.
      await step('Check output files...', () async {
        // TODO(matanlurey): Resolve this in a better way. On CI this file always exists.
        File(join(screenshotPath, 'noop.txt')).writeAsStringSync('');
        // TODO(gaaclarke): We should move this into dir_contents_diff.
        _withTemporaryCwd(contentsGolden, () {
          final int exitCode = dirContentsDiff(basename(contentsGolden), screenshotPath);
          if (exitCode != 0) {
            panic(<String>['Output contents incorrect.']);
          }
        });
      });
    }
  }
}
