

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/context.dart';

void main() {
  final MockProcessManager mockProcessManager = MockProcessManager();
  final MockProcess mockProcess = MockProcess();

  testUsingContext('invokes dart2js with correct arguments', () async {
    const WebCompiler webCompiler = WebCompiler();
    final String engineDartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final String dart2jsPath = artifacts.getArtifactPath(Artifact.dart2jsSnapshot);
    final String librariesPath = fs.path.join(artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath), 'libraries.json');

    when(mockProcess.stdout).thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
    when(mockProcess.stderr).thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async => 0);
    when(mockProcessManager.start(any)).thenAnswer((Invocation invocation) async => mockProcess);
    when(mockProcessManager.canRun(engineDartPath)).thenReturn(true);

    await webCompiler.compile(target: 'lib/main.dart');

    verify(mockProcessManager.start(<String>[
      engineDartPath,
      dart2jsPath,
      'lib/main.dart',
      '--libraries-spec=$librariesPath',
    ]));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}