// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:test_core/src/executable.dart' as test; // ignore: implementation_imports
import 'package:watcher/watcher.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../base/terminal.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import 'bootstrap.dart';
import 'compiler.dart';
import 'flutter_platform.dart' as loader;
import 'watcher.dart';

/// Runs tests using package:test and the Flutter engine.
Future<int> runTests(
  List<String> testFiles, {
  Directory workDir,
  List<String> names = const <String>[],
  List<String> plainNames = const <String>[],
  bool enableObservatory = false,
  bool startPaused = false,
  bool ipv6 = false,
  bool machine = false,
  String precompiledDillPath,
  Map<String, String> precompiledDillFiles,
  bool trackWidgetCreation = false,
  bool updateGoldens = false,
  bool watchTests = false,
  TestWatcher watcher,
  @required int concurrency,
}) async {
  // Compute the command-line arguments for package:test.
  final List<String> testArgs = <String>[];
  if (!terminal.supportsColor) {
    testArgs.addAll(<String>['--no-color']);
  }

  if (machine) {
    testArgs.addAll(<String>['-r', 'json']);
  } else {
    testArgs.addAll(<String>['-r', 'compact']);
  }

  testArgs.add('--concurrency=$concurrency');

  for (String name in names) {
    testArgs..add('--name')..add(name);
  }

  for (String plainName in plainNames) {
    testArgs..add('--plain-name')..add(plainName);
  }

  testArgs.add('--');
  testArgs.addAll(testFiles);

  // Configure package:test to use the Flutter engine for child processes.
  final String shellPath = artifacts.getArtifactPath(Artifact.flutterTester);
  if (!processManager.canRun(shellPath))
    throwToolExit('Cannot find Flutter shell at $shellPath');

  final Uri projectRootDirectory = fs.currentDirectory.uri;
  final TestCompiler compiler = TestCompiler(trackWidgetCreation, projectRootDirectory);
  final List<String> invalidatedFiles = <String>[];
  final InternetAddressType serverType =
      ipv6 ? InternetAddressType.IPv6 : InternetAddressType.IPv4;

  final Function compileTestFiles = () async {
    int index = 0;
    final Map<String, String> precompiledDillFiles = <String, String>{};
    final Map<String, List<Finalizer>> finalizers = <String, List<Finalizer>>{};
    for (String file in testFiles) {
      final List<Finalizer> fileFinalizers = <Finalizer>[];
      final String mainDart = createListenerDart(
        fileFinalizers,
        index,
        file,
        loader.kHosts[serverType],
        updateGoldens,
      );

      final String dillPath = await compiler.compile(mainDart, invalidatedFiles: invalidatedFiles);
      // We only need to invalidate the changed file once, so clear the list
      if (invalidatedFiles.isNotEmpty) {
        invalidatedFiles.clear();
      }
      precompiledDillFiles[file] = dillPath;
      finalizers[file] = fileFinalizers;
      index++;
    }

    loader.installHook(
      shellPath: shellPath,
      watcher: watcher,
      enableObservatory: enableObservatory,
      machine: machine,
      startPaused: startPaused,
      serverType: serverType,
      precompiledDillFiles: precompiledDillFiles,
      trackWidgetCreation: trackWidgetCreation,
      updateGoldens: updateGoldens,
      projectRootDirectory: projectRootDirectory,
      fileFinalizers: finalizers,
    );
  };
  await compileTestFiles();

  // Make the global packages path absolute.
  // (Makes sure it still works after we change the current directory.)
  PackageMap.globalPackagesPath =
      fs.path.normalize(fs.path.absolute(PackageMap.globalPackagesPath));

  // Call package:test's main method in the appropriate directory.
  final Directory saved = fs.currentDirectory;
  
  final Function printReloadMessage = () {
    printStatus(
      "Press 'r' to rerun your tests, 'q' to quit",
      color: TerminalColor.red
    );
  };

  try {
    if (workDir != null) {
      printTrace('switching to directory $workDir to run tests');
      fs.currentDirectory = workDir;
    }

    printTrace('running test package with arguments: $testArgs');
    await test.runTests(testArgs);

    if (watchTests) {
      final Completer<void> completer = Completer<void>();
      final DirectoryWatcher directoryWatcher = DirectoryWatcher(saved.path);

      directoryWatcher.events.listen((WatchEvent event) {
        if (event.path.endsWith('.dart')) {
          invalidatedFiles.add(event.path);
        }
      });

      terminal.singleCharMode = true;
      terminal.onCharInput.asBroadcastStream().listen((String char) async {
        switch(char) {
          case 'r':
            final Status status =
                logger.startProgress('Recompiling test files...\n');
            await compileTestFiles();
            status.stop();

            await test.runTests(testArgs);

            printReloadMessage();
            break;
          case 'q':
            completer.complete();
        }
      }, onDone: completer.complete);

      await directoryWatcher.ready;

      printReloadMessage();

      await completer.future;
      stdout.writeln(terminal.clearScreen());
    }

    try {
      test.completeShutdown();
    } on StateError catch (e) {
      printError(e.toString());
    } finally {
      await compiler.dispose();
    }

    // test.main() sets dart:io's exitCode global.
    printTrace('test package returned with exit code $exitCode');

    return exitCode;
  } finally {
    fs.currentDirectory = saved;
  }
}
