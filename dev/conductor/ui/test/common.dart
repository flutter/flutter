// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/src/stdio.dart';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import '../../../../packages/flutter_tools/test/src/fake_process_manager.dart';
export '../../../../packages/flutter_tools/test/src/fake_process_manager.dart';

const String kFlutterRoot = '/flutter';
const String kCheckoutsParentDirectory = '$kFlutterRoot/dev/tools/';

class TestStdio extends Stdio {
  TestStdio({
    this.verbose = false,
    List<String>? stdin,
  }) : _stdin = stdin ?? <String>[];

  String get error => logs.where((String log) => log.startsWith(r'[error] ')).join('\n');

  String get stdout => logs.where((String log) {
    return log.startsWith(r'[status] ') || log.startsWith(r'[trace] ') || log.startsWith(r'[write] ');
  }).join('\n');

  final bool verbose;
  late final List<String> _stdin;
  List<String> get stdin => _stdin;

  @override
  String readLineSync() {
    if (_stdin.isEmpty) {
      throw Exception('Unexpected call to readLineSync!');
    }
    return _stdin.removeAt(0);
  }
}

class FakeStartContext extends StartContext {
  factory FakeStartContext({
    String candidateBranch = 'flutter-1.2-candidate.3',
    Checkouts? checkouts,
    String? dartRevision,
    List<String> engineCherrypickRevisions = const <String>[],
    String engineMirror = 'git@github:user/engine',
    String engineUpstream = EngineRepository.defaultUpstream,
    List<String> frameworkCherrypickRevisions = const <String>[],
    String frameworkMirror = 'git@github:user/flutter',
    String frameworkUpstream = FrameworkRepository.defaultUpstream,
    Directory? flutterRoot,
    String incrementLetter = 'm',
    FakeProcessManager? processManager,
    String releaseChannel = 'dev',
    File? stateFile,
    Stdio? stdio,
    Future<void> Function()? runOverride,
  }) {
    final FileSystem fileSystem = MemoryFileSystem.test();
    flutterRoot ??= fileSystem.directory(kFlutterRoot);
    stateFile ??= fileSystem.file(kStateFileName);
    final Platform platform = FakePlatform(
      environment: <String, String>{'HOME': '/path/to/user/home'},
      operatingSystem: const LocalPlatform().operatingSystem,
      pathSeparator: r'/',
    );
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    stdio ??= TestStdio();
    checkouts = Checkouts(
      fileSystem: fileSystem,
      parentDirectory: fileSystem.directory(kCheckoutsParentDirectory),
      platform: platform,
      processManager: processManager,
      stdio: stdio,
    );
    return FakeStartContext._(
      candidateBranch: candidateBranch,
      checkouts: checkouts,
      dartRevision: dartRevision,
      engineCherrypickRevisions: engineCherrypickRevisions,
      engineMirror: engineMirror,
      engineUpstream: engineUpstream,
      flutterRoot: flutterRoot,
      frameworkCherrypickRevisions: frameworkCherrypickRevisions,
      frameworkMirror: frameworkMirror,
      frameworkUpstream: frameworkUpstream,
      incrementLetter: incrementLetter,
      processManager: processManager,
      releaseChannel: releaseChannel,
      stateFile: stateFile,
      stdio: stdio,
      runOverride: runOverride,
    );
  }

  FakeStartContext._({
    required String candidateBranch,
    required Checkouts checkouts,
    String? dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required String engineUpstream,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required String frameworkUpstream,
    required Directory flutterRoot,
    required String incrementLetter,
    required ProcessManager processManager,
    required String releaseChannel,
    required File stateFile,
    required Stdio stdio,
    this.runOverride,
  }) : super(
        candidateBranch: candidateBranch,
        checkouts: checkouts,
        dartRevision: dartRevision,
        engineCherrypickRevisions: engineCherrypickRevisions,
        engineMirror: engineMirror,
        engineUpstream: engineUpstream,
        flutterRoot: flutterRoot,
        frameworkCherrypickRevisions: frameworkCherrypickRevisions,
        frameworkMirror: frameworkMirror,
        frameworkUpstream: frameworkUpstream,
        incrementLetter: incrementLetter,
        processManager: processManager,
        releaseChannel: releaseChannel,
        stateFile: stateFile,
        stdio: stdio,
  );

  /// An optional override async callback for the real [run] method.
  Future<void> Function()? runOverride;

  /// Either call [runOverride] if it is not null, else call [super.run].
  @override
  Future<void> run() {
    if (runOverride != null) {
      return runOverride!();
    }
    return super.run();
  }

  void addCommand(FakeCommand command) {
    (checkouts.processManager as FakeProcessManager).addCommand(command);
  }

  void addCommands(List<FakeCommand> commands) {
    (checkouts.processManager as FakeProcessManager).addCommands(commands);
  }
}
