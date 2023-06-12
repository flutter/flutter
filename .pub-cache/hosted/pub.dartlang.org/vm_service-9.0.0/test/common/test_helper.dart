// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'service_test_common.dart';

export 'service_test_common.dart' show IsolateTest, VMTest;

/// The extra arguments to use
const List<String> extraDebuggingArgs = [];

/// Will be set to the http address of the VM's service protocol before
/// any tests are invoked.
late String serviceHttpAddress;
late String serviceWebsocketAddress;

const String _TESTEE_ENV_KEY = 'SERVICE_TEST_TESTEE';
const Map<String, String> _TESTEE_SPAWN_ENV = {_TESTEE_ENV_KEY: 'true'};
bool _isTestee() {
  return io.Platform.environment.containsKey(_TESTEE_ENV_KEY);
}

Uri _getTestUri(String script) {
  if (io.Platform.script.isScheme('data')) {
    // If running from pub we can assume that we're in the root of the package
    // directory.
    return Uri.parse('test/$script');
  } else {
    // Resolve the script to ensure that test will fail if the provided script
    // name doesn't match the actual script.
    return io.Platform.script.resolve(script);
  }
}

class _ServiceTesteeRunner {
  Future run(
      {Function()? testeeBefore,
      Function()? testeeConcurrent,
      bool pause_on_start = false,
      bool pause_on_exit = false}) async {
    if (!pause_on_start) {
      if (testeeBefore != null) {
        var result = testeeBefore();
        if (result is Future) {
          await result;
        }
      }
      print(''); // Print blank line to signal that testeeBefore has run.
    }
    if (testeeConcurrent != null) {
      var result = testeeConcurrent();
      if (result is Future) {
        await result;
      }
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      // ignore: unawaited_futures
      io.stdin.first.then((_) => io.exit(0));
    }
  }

  void runSync(
      {void Function()? testeeBeforeSync,
      void Function()? testeeConcurrentSync,
      bool pause_on_start = false,
      bool pause_on_exit = false}) {
    if (!pause_on_start) {
      if (testeeBeforeSync != null) {
        testeeBeforeSync();
      }
      print(''); // Print blank line to signal that testeeBefore has run.
    }
    if (testeeConcurrentSync != null) {
      testeeConcurrentSync();
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      io.stdin.first.then((_) => io.exit(0));
    }
  }
}

class _ServiceTesteeLauncher {
  io.Process? process;
  List<String> args;
  bool killedByTester = false;

  _ServiceTesteeLauncher(String script)
      : args = [_getTestUri(script).toFilePath()];

  // Spawn the testee process.
  Future<io.Process> _spawnProcess(
    bool pause_on_start,
    bool pause_on_exit,
    bool pause_on_unhandled_exceptions,
    bool testeeControlsServer,
    bool useAuthToken,
    List<String>? experiments,
    List<String>? extraArgs,
  ) {
    return _spawnDartProcess(
        pause_on_start,
        pause_on_exit,
        pause_on_unhandled_exceptions,
        testeeControlsServer,
        useAuthToken,
        experiments,
        extraArgs);
  }

  Future<io.Process> _spawnDartProcess(
      bool pause_on_start,
      bool pause_on_exit,
      bool pause_on_unhandled_exceptions,
      bool testeeControlsServer,
      bool useAuthToken,
      List<String>? experiments,
      List<String>? extraArgs) {
    String dartExecutable = io.Platform.executable;

    var fullArgs = <String>[
      '--disable-dart-dev',
    ];
    if (pause_on_start) {
      fullArgs.add('--pause-isolates-on-start');
    }
    if (pause_on_exit) {
      fullArgs.add('--pause-isolates-on-exit');
    }
    if (!useAuthToken) {
      fullArgs.add('--disable-service-auth-codes');
    }
    if (pause_on_unhandled_exceptions) {
      fullArgs.add('--pause-isolates-on-unhandled-exceptions');
    }
    fullArgs.add('--profiler');
    if (experiments != null) {
      fullArgs.addAll(experiments.map((e) => '--enable-experiment=$e'));
    }
    if (extraArgs != null) {
      fullArgs.addAll(extraArgs);
    }

    fullArgs.addAll(io.Platform.executableArguments);
    if (!testeeControlsServer) {
      fullArgs.add('--enable-vm-service:0');
    }
    fullArgs.addAll(args);
    return _spawnCommon(dartExecutable, fullArgs, <String, String>{});
  }

  Future<io.Process> _spawnCommon(String executable,
      List<String> /*!*/ arguments, Map<String, String> dartEnvironment) {
    var environment = _TESTEE_SPAWN_ENV;
    var bashEnvironment = StringBuffer();
    environment.forEach((k, v) => bashEnvironment.write("$k=$v "));
    dartEnvironment.forEach((k, v) {
      arguments.insert(0, '-D$k=$v');
    });
    print('** Launching $bashEnvironment$executable ${arguments.join(' ')}');
    return io.Process.start(
      executable,
      arguments,
      environment: environment,
    );
  }

  Future<Uri> launch(
      bool pause_on_start,
      bool pause_on_exit,
      bool pause_on_unhandled_exceptions,
      bool testeeControlsServer,
      bool useAuthToken,
      List<String>? experiments,
      List<String>? extraArgs) {
    return _spawnProcess(
            pause_on_start,
            pause_on_exit,
            pause_on_unhandled_exceptions,
            testeeControlsServer,
            useAuthToken,
            experiments,
            extraArgs)
        .then((p) {
      Completer<Uri> completer = Completer<Uri>();
      process = p;
      Uri? uri;
      var blank;
      var first = true;
      process!.stdout
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        const kDartVMServiceListening = 'The Dart VM service is listening on ';
        if (line.startsWith(kDartVMServiceListening)) {
          uri = Uri.parse(line.substring(kDartVMServiceListening.length));
        }
        if (pause_on_start || line == '') {
          // Received blank line.
          blank = true;
        }
        if ((uri != null) && (blank == true) && (first == true)) {
          completer.complete(uri);
          // Stop repeat completions.
          first = false;
          print('** Signaled to run test queries on $uri');
        }
        io.stdout.write('>testee>out> ${line}\n');
      });
      process!.stderr
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        io.stdout.write('>testee>err> ${line}\n');
      });
      process!.exitCode.then((exitCode) {
        if ((exitCode != 0) && !killedByTester) {
          throw "Testee exited with $exitCode";
        }
        print("** Process exited: $exitCode");
      });
      return completer.future;
    });
  }

  void requestExit() {
    if (process != null) {
      print('** Killing script');
      if (process!.kill()) {
        killedByTester = true;
      }
    }
  }
}

void setupAddresses(Uri /*!*/ serverAddress) {
  serviceWebsocketAddress =
      'ws://${serverAddress.authority}${serverAddress.path}ws';
  serviceHttpAddress = 'http://${serverAddress.authority}${serverAddress.path}';
}

class _ServiceTesterRunner {
  Future run({
    List<String>? mainArgs,
    List<String>? extraArgs,
    List<String>? experiments,
    List<VMTest>? vmTests,
    List<IsolateTest>? isolateTests,
    required String scriptName,
    bool pause_on_start = false,
    bool pause_on_exit = false,
    bool verbose_vm = false,
    bool pause_on_unhandled_exceptions = false,
    bool testeeControlsServer = false,
    bool useAuthToken = false,
  }) async {
    var process = _ServiceTesteeLauncher(scriptName);
    late VmService vm;
    late IsolateRef isolate;
    setUp(() async {
      await process
          .launch(pause_on_start, pause_on_exit, pause_on_unhandled_exceptions,
              testeeControlsServer, useAuthToken, experiments, extraArgs)
          .then((Uri serverAddress) async {
        if (mainArgs!.contains("--gdb")) {
          var pid = process.process!.pid;
          var wait = Duration(seconds: 10);
          print("Testee has pid $pid, waiting $wait before continuing");
          io.sleep(wait);
        }
        setupAddresses(serverAddress);
        vm = await vmServiceConnectUri(serviceWebsocketAddress);
        print('Done loading VM');
        isolate = await getFirstIsolate(vm);
      });
    });

    final name = _getTestUri(scriptName).pathSegments.last;

    test(
      name,
      () async {
        // Run vm tests.
        if (vmTests != null) {
          var testIndex = 1;
          var totalTests = vmTests.length;
          for (var t in vmTests) {
            print('$name [$testIndex/$totalTests]');
            await t(vm);
            testIndex++;
          }
        }

        // Run isolate tests.
        if (isolateTests != null) {
          var testIndex = 1;
          var totalTests = isolateTests.length;
          for (var t in isolateTests) {
            print('$name [$testIndex/$totalTests]');
            await t(vm, isolate);
            testIndex++;
          }
        }
      },
      retry: 0,
      timeout: Timeout.none,
    );

    tearDown(() {
      print('All service tests completed successfully.');
      process.requestExit();
    });
  }

  Future<IsolateRef> getFirstIsolate(VmService service) async {
    var vm = await service.getVM();
    final vmIsolates = vm.isolates!;
    if (vmIsolates.isNotEmpty) {
      return vmIsolates.first;
    }
    Completer<dynamic>? completer = Completer();
    late StreamSubscription subscription;
    subscription = service.onIsolateEvent.listen((Event event) async {
      if (completer == null) {
        await subscription.cancel();
        return;
      }
      if (event.kind == EventKind.kIsolateRunnable) {
        vm = await service.getVM();
        await subscription.cancel();
        await service.streamCancel(EventStreams.kIsolate);
        completer!.complete(event.isolate!);
        completer = null;
      }
    });
    await service.streamListen(EventStreams.kIsolate);

    // The isolate may have started before we subscribed.
    vm = await service.getVM();
    if (vmIsolates.isNotEmpty) {
      await subscription.cancel();
      completer!.complete(vmIsolates.first);
      completer = null;
    }
    return (await completer!.future) as IsolateRef;
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
Future<void> runIsolateTests(
  List<String> mainArgs,
  List<IsolateTest> tests,
  String scriptName, {
  testeeBefore()?,
  testeeConcurrent()?,
  bool pause_on_start = false,
  bool pause_on_exit = false,
  bool verbose_vm = false,
  bool pause_on_unhandled_exceptions = false,
  bool testeeControlsServer = false,
  bool useAuthToken = false,
  List<String>? experiments,
  List<String>? extraArgs,
}) async {
  assert(!pause_on_start || testeeBefore == null);
  if (_isTestee()) {
    await _ServiceTesteeRunner().run(
        testeeBefore: testeeBefore,
        testeeConcurrent: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    await _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        scriptName: scriptName,
        extraArgs: extraArgs,
        isolateTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        verbose_vm: verbose_vm,
        experiments: experiments,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions,
        testeeControlsServer: testeeControlsServer,
        useAuthToken: useAuthToken);
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
///
/// This is a special version of this test harness specifically for the
/// pause_on_unhandled_exceptions_test, which cannot properly function
/// in an async context (because exceptions are *always* handled in async
/// functions).
void runIsolateTestsSynchronous(
  List<String> mainArgs,
  List<IsolateTest> tests,
  String scriptName, {
  void testeeBefore()?,
  void testeeConcurrent()?,
  bool pause_on_start = false,
  bool pause_on_exit = false,
  bool verbose_vm = false,
  bool pause_on_unhandled_exceptions = false,
  List<String>? extraArgs,
}) {
  assert(!pause_on_start || testeeBefore == null);
  if (_isTestee()) {
    _ServiceTesteeRunner().runSync(
        testeeBeforeSync: testeeBefore,
        testeeConcurrentSync: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        scriptName: scriptName,
        extraArgs: extraArgs,
        isolateTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        verbose_vm: verbose_vm,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions);
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
Future<void> runVMTests(
  List<String> mainArgs,
  List<VMTest> tests,
  String scriptName, {
  testeeBefore()?,
  testeeConcurrent()?,
  bool pause_on_start = false,
  bool pause_on_exit = false,
  bool verbose_vm = false,
  bool pause_on_unhandled_exceptions = false,
  List<String>? extraArgs,
}) async {
  if (_isTestee()) {
    await _ServiceTesteeRunner().run(
        testeeBefore: testeeBefore,
        testeeConcurrent: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    await _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        scriptName: scriptName,
        extraArgs: extraArgs,
        vmTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        verbose_vm: verbose_vm,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions);
  }
}
