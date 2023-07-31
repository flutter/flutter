library process_run.test.shell_common_api_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/src/context.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/env_utils.dart';
import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_environment_common.dart';
import 'package:test/test.dart';

class ShellContextMock implements ShellContext {
  @override
  // TODO: implement encoding
  Encoding get encoding => throw UnimplementedError();

  @override
  Shell newShell(
      {ShellOptions? options,
      Map<String, String>? environment,
      bool includeParentEnvironment = true}) {
    return ShellMock(options: options, context: this);
  }

  @override
  ShellEnvironment newShellEnvironment({Map<String, String>? environment}) {
    // TODO: implement newShellEnvironment
    throw UnimplementedError();
  }

  @override
  Context get path => throw UnimplementedError();

  @override
  final ShellEnvironment shellEnvironment = ShellEnvironmentMock();

  @override
  Future<String?> which(String command,
      {ShellEnvironment? environment, bool includeParentEnvironment = true}) {
    // TODO: implement which
    throw UnimplementedError();
  }
}

class ShellEnvironmentMock extends ShellEnvironmentBase
    implements ShellEnvironment {
  ShellEnvironmentMock() : super.empty();

  @override
  Future<String?> which(String command) async {
    // TODO: implement which
    throw UnimplementedError();
  }

  @override
  String? whichSync(String command) {
    throw UnimplementedError();
  }
}

class ProcessMock implements Process {
  final ProcessResult result;
  final List<String> outLines;

  ProcessMock(this.result, this.outLines);

  @override
  // TODO: implement exitCode
  Future<int> get exitCode => throw UnimplementedError();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    // TODO: implement kill
    // throw UnimplementedError();
    return true;
  }

  @override
  // TODO: implement pid
  int get pid => throw UnimplementedError();

  @override
  // TODO: implement stderr
  Stream<List<int>> get stderr => throw UnimplementedError();

  @override
  // TODO: implement stdin
  IOSink get stdin => throw UnimplementedError();

  @override
  // TODO: implement stdout
  Stream<List<int>> get stdout => throw UnimplementedError();
}

var shellOptionsMock =
    ShellOptions(environment: {}, includeParentEnvironment: false);

class ShellMock with ShellMixin implements Shell {
  var scripts = <String>[];

  ShellMock({ShellContextMock? context, ShellOptions? options}) {
    this.context = context ?? ShellContextMock();
    this.options = options ?? shellOptionsMock;
  }

  @override
  Shell cd(String path) {
    // TODO: implement cd
    throw UnimplementedError();
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    // TODO: implement kill
    throw UnimplementedError();
  }

  @override
  Shell popd() {
    // TODO: implement popd
    throw UnimplementedError();
  }

  @override
  Shell pushd(String path) {
    // TODO: implement pushd
    throw UnimplementedError();
  }

  @override
  Future<List<ProcessResult>> run(String script,
      {void Function(Process process)? onProcess}) async {
    scripts.add(script);
    // Take "hola" from "echo hola"
    var outLines = [script.split(' ').last];
    var result = ProcessResult(1, 0, outLines.join('\n'), '');
    if (onProcess != null) {
      onProcess(ProcessMock(result, outLines));
    }
    return <ProcessResult>[result];
  }

  @override
  Future<ProcessResult> runExecutableArguments(
      String executable, List<String> arguments,
      {void Function(Process process)? onProcess}) {
    // TODO: implement runExecutableArguments
    throw UnimplementedError();
  }

  @override
  late final ShellOptions options;
}

void main() {
  group('shell_common_test', () {
    Future<void> testLinuxEcho(Shell shell) async {
      var results = await shell.run('echo hola', onProcess: (process) {
        process.kill();
      });
      expect(results.first.exitCode, 0);

      var outLines = results.outLines;
      expect(outLines, ['hola']);
    }

    test('mock', () async {
      var shell = ShellMock();
      await testLinuxEcho(shell);
      expect(shell.scripts, ['echo hola']);
    });
    test('context', () async {
      if (!isRunningAsJavascript) {
        if (!Platform.isLinux) {
          // Only io linux test for now
          // TODO test on windows and mac
          return;
        }
      }
      shellContext = ShellContextMock();
      var shell = Shell();
      await testLinuxEcho(shell);

      if (isRunningAsJavascript) {
        clearShellContext();
      }
      try {
        shell = Shell();
        if (isRunningAsJavascript) {
          fail('should fail');
        }
      } on StateError catch (e) {
        if (!isRunningAsJavascript) {
          rethrow;
        }
        print(e);
      }
      //expect(shell.scripts, ['echo hola']);
    });
    test('io', () async {
      if (!isRunningAsJavascript) {
        if (Platform.isLinux) {
          var shell = Shell();
          await testLinuxEcho(shell);
        }
      }
      //expect(shell.scripts, ['hola']);
    });
    test('cloneWithOptions', () async {
      var shell = ShellMock().cloneWithOptions(ShellOptions(
          workingDirectory: 'a/b',
          environment: {},
          includeParentEnvironment: false));
      expect(shell.path, 'a/b');
      expect(shell.options.workingDirectory, 'a/b');
    });
    test('clone', () async {
      // ignore: deprecated_member_use_from_same_package
      var shell = ShellMock().clone(
          workingDirectory: 'a/b',
          environment: {},
          includeParentEnvironment: false);
      expect(shell.path, 'a/b');
      expect(shell.options.workingDirectory, 'a/b');
    });
  });
}
