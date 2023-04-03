// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';

import '../src/common.dart';
import '../src/flutter_tree.dart';
import '../src/process.dart';
import 'test_utils.dart';

/// The Flutter source tree that this program is part of.
///
/// The tree is the one located by [getFlutterRoot].
final FlutterTree hostFlutterTree = FlutterTree(
    fileSystem.directory(getFlutterRoot()).absolute);

/// The value the entrypoint writes into `flutterToolsStampFile`.
///
/// The [toolArgs] parameter corresponds to `FLUTTER_TOOL_ARGS`
/// in the entrypoint scripts.
String flutterToolsStampValue({required String revision, String toolArgs = ''}) {
  return '$revision:$toolArgs';
}

/// Additional members on [FlutterTree] which are helpful for [TestFlutterTree]
/// and its users.
extension FlutterTreeExtension on FlutterTree {
  Directory get binCacheDir => root.childDirectory('bin').childDirectory('cache'); // bin/cache/
  File get snapshotFile => binCacheDir.childFile('flutter_tools.snapshot'); // bin/cache/flutter_tools.snapshot
  File get flutterToolsStampFile => binCacheDir.childFile('flutter_tools.stamp'); // bin/cache/flutter_tools.stamp
  Directory get dartSdkDir => binCacheDir.childDirectory('dart-sdk'); // bin/cache/dart-sdk/
  File get engineStampFile => binCacheDir.childFile('engine-dart-sdk.stamp'); // bin/cache/engine-dart-sdk.stamp

  String headRevision() => runSyncSuccess(<String>['git', 'rev-parse', 'HEAD']).shellOutput as String;

  /// List the files where the worktree differs from the HEAD revision.
  ///
  /// Each file is represented as a path relative to [root].
  ///
  /// By default this includes files that have been added, deleted,
  /// or in any way modified.  If `diffFilter` is provided, it will be
  /// passed to `git diff --diff-filter=…` to filter the files
  /// by type of change.
  ///
  /// No rename detection is performed; if a file was renamed, it will appear
  /// as a deletion and an addition (as further filtered by `diffFilter`).
  List<String> gitModifiedFiles({String? diffFilter}) {
    final List<String> command = <String>[
      'git', 'diff',
      '--no-renames', // disables finding renames, and finding copies too
      '--name-only', '-z',
      if (diffFilter != null)
        '--diff-filter=$diffFilter',
      'HEAD',
    ];
    return (runSyncSuccess(command).stdout as String).split('\x00')..removeLast();
  }

  /// Run a trivial command with the tree's `bin/dart`, to ensure the cache
  /// is up to date.
  ///
  /// This happens to update all the same caches as [ensureToolSync],
  /// but in principle in the future it might not.
  void ensureDartSync() {
    // `dart --version` is faster than simply `dart`
    runSyncSuccess(<String>[binDart.path, '--version']);
  }

  /// Run a trivial command with the tree's `bin/flutter`, to ensure the cache
  /// is up to date.
  void ensureToolSync() {
    // plain `flutter` is faster than `flutter --version`
    runSyncSuccess(<String>[binFlutter.path]);
  }

  /// Start a process at [root] and run it to completion, throwing an exception
  /// on failure.
  ///
  /// This is a convenience wrapper for [ProcessManagerExtension.runSyncSuccess],
  /// providing `workingDirectory`.
  ProcessResult runSyncSuccess(
    List<String> command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    // no runInShell; keep that always false
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    return processManager.runSyncSuccess(
      command,
      workingDirectory: root.path,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }
}

/// Use `rsync` to copy one directory tree to another, exactly,
/// deleting stray files.
///
/// For each file or directory found under [source], there will be a
/// corresponding entity at the same relative path under [target],
/// with the same contents, same last-modified time, and same other metadata.
/// Any entities under [target] that do not correspond to an entity under
/// [source] will be deleted.
///
/// This is equivalent to the shell command
/// `rsync -a --delete "${source}/" "${target}/"`.
void _rsyncTreesSync(Directory source, Directory target) {
  processManager.runSyncSuccess(<String>[
    'rsync', '-a', '--delete',
    source.path + Platform.pathSeparator,
    target.path + Platform.pathSeparator,
  ]);
}

/// A temporary copy of the Flutter tree, to be freely mutated for testing.
///
/// This is a real Git worktree in the real filesystem.
/// Its contents are based on those of [hostFlutterTree]: the Git commit
/// [baseRevision] is the current HEAD of [hostFlutterTree], plus one
/// added commit for any changes in the [hostFlutterTree] worktree
/// that are not yet committed to Git.
///
/// To save resources, this tree reuses the Git object and pack files from
/// [hostFlutterTree].  When using [TestFlutterTree.takeWarm], it also
/// uses a copy of the Dart SDK from [hostFlutterTree] as its own cached
/// Dart SDK.
///
/// Successive test cases can reuse the tree by calling
/// [TestFlutterTree.takeWarm] or [TestFlutterTree.takeClean],
/// either of which will reset it to a known state.
///
/// After all tests have run, [TestFlutterTree.dispose] should be called
/// in order to delete the temporary tree.
///
/// See also:
/// * [hostFlutterTree], the Flutter tree that the running program
///   is itself part of.
class TestFlutterTree extends FlutterTree {
  /// Take the shared global tree, resetting it to a pristine state.
  ///
  /// The tree will be on branch `main` at commit [baseRevision].
  /// There will be no files or directories in the tree except
  /// those put there by Git.
  ///
  /// Using this can be expensive because any operation involving the
  /// [binDart] or [binFlutter] entrypoint scripts may cause the Dart SDK
  /// to be downloaded from scratch and the tool snapshot to be recompiled.
  /// Consider [TestFlutterTree.takeWarm].
  ///
  /// When using this, be sure to call [TestFlutterTree.dispose] after
  /// all tests have run, in order to avoid leaving a large temporary tree
  /// lying around in the filesystem.
  factory TestFlutterTree.takeClean() {
    return TestFlutterTree._take().._reset();
  }

  /// Take the shared global tree, resetting it to a warm-cache state.
  ///
  /// This is equivalent to [TestFlutterTree.takeClean] followed by
  /// [ensureToolSync], but more efficient.
  ///
  /// The Dart SDK at [dartSdkDir] and tool snapshot at [snapshotFile] will be
  /// copied from [hostFlutterTree], to avoid downloading and compiling anew.
  /// On the first call to this factory constructor, the warm tree is memoized;
  /// subsequent calls will copy the memoized version.
  ///
  /// When using this, be sure to call [TestFlutterTree.dispose] after
  /// all tests have run, in order to avoid leaving a large temporary tree
  /// lying around in the filesystem.
  factory TestFlutterTree.takeWarm() {
    return TestFlutterTree._take().._warm();
  }

  /// Take the shared global tree, in whatever state it currently is in.
  factory TestFlutterTree._take() {
    return _instance ??= TestFlutterTree._create();
  }

  TestFlutterTree._(this._origRevision, super.root);

  factory TestFlutterTree._create() {
    final String origRevision = hostFlutterTree.headRevision();
    final Directory root = fileSystem
      .systemTempDirectory.createTempSync('flutter_test_tree.').absolute;
    return TestFlutterTree._(origRevision, root).._initialize();
  }

  /// Delete the shared global temporary tree from the filesystem.
  static void dispose() {
    _instance?._dispose();
    _instance = null;
  }

  /// The shared global instance of [TestFlutterTree].
  static TestFlutterTree? _instance;

  /// The Git commit ID of this tree in its baseline state.
  ///
  /// This will be the current HEAD of [hostFlutterTree], plus one
  /// added commit for any changes in the [hostFlutterTree] worktree
  /// that are not yet committed to Git.
  late final String baseRevision;

  /// The Git commit ID that is HEAD in [hostFlutterTree].
  final String _origRevision;

  /// The memoized warm tree for [TestFlutterTree.takeWarm].
  Directory? _warmTree;

  void _initialize() {
    processManager.runSyncSuccess(<String>[
      'git', 'clone',
      '--shared',
      '--origin', 'origin',
      hostFlutterTree.root.childDirectory('.git').path,
      root.path,
    ]);
    runSyncSuccess(<String>['git', 'checkout', '-B', 'main', _origRevision]);

    // Sync uncommitted changes from [hostFlutterTree].
    final List<String> filesAdded = hostFlutterTree.gitModifiedFiles(diffFilter: 'A');
    final List<String> filesEdited = hostFlutterTree.gitModifiedFiles(diffFilter: 'MUT');
    final List<String> filesDeleted = hostFlutterTree.gitModifiedFiles(diffFilter: 'D');
    if (filesAdded.isNotEmpty || filesEdited.isNotEmpty) {
      hostFlutterTree.runSyncSuccess(<String>[
        'rsync', '-a', '--relative',
        ...filesAdded, ...filesEdited,
        root.path + Platform.pathSeparator,
      ]);
      if (filesAdded.isNotEmpty) {
        runSyncSuccess(<String>[
          'git', 'add', '--', ...filesAdded,
        ]);
      }
    }
    for (final String file in filesDeleted) {
      fileSystem.file(fileSystem.path.join(root.path, file)).deleteSync();
    }
    if (filesAdded.isNotEmpty || filesEdited.isNotEmpty || filesDeleted.isNotEmpty) {
      runSyncSuccess(<String>[
        'git', 'commit', '-am', 'uncommitted changes from host tree',
      ]);
      baseRevision = headRevision();
    } else {
      baseRevision = _origRevision;
    }
  }

  void _reset({bool keepDartSdk = false}) {
    runSyncSuccess(<String>['git', 'checkout', '-B', 'main', baseRevision]);
    runSyncSuccess(<String>[
      'git', 'clean',
      '--quiet',
      '--force',
      '-d', // directories too
      '-x', // ignored files too
      if (keepDartSdk)
        '--exclude=bin/cache/dart-sdk/', // dartSdkDir but relative to root
    ]);
  }

  void _warm() {
    if (_warmTree != null) {
      _rsyncTreesSync(_warmTree!, root);
      return;
    }

    _reset();

    // Borrow the Dart SDK from the host tree.
    // This saves having to download it again.
    hostFlutterTree.ensureDartSync();
    dartSdkDir.createSync(recursive: true);
    _rsyncTreesSync(hostFlutterTree.dartSdkDir, dartSdkDir);
    hostFlutterTree.engineStampFile.copySync(engineStampFile.path);

    // Warm the rest of the cache directly in the test tree.
    assert(flutterToolsStampFile.readStringLikeShell() == null);
    final String stampValue = flutterToolsStampValue(revision: baseRevision);
    final List<String> log = ensureToolWithFakeDart();
    final String? actualStamp = flutterToolsStampFile.readStringLikeShell();
    if (actualStamp != stampValue) {
      print('stamp contents: $actualStamp');
      print('stamp expected: $stampValue');
      print('fake-dart log:\n${log.join('\n')}\n================================');
      print('cacheDir contents:\n${runSyncSuccess(<String>['ls', '-Alrt', binCacheDir.path]).stdout}');
    }
    assert(actualStamp == stampValue);

    _warmTree = fileSystem
      .systemTempDirectory.createTempSync('flutter_test_tree_warm.').absolute;
    _rsyncTreesSync(root, _warmTree!);
  }

  void _dispose() {
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // ignore
    }
    try {
      _warmTree?.deleteSync(recursive: true);
    } on FileSystemException {
      // ignore
    }
  }

  File get fakeDartLog => binCacheDir.childFile('fake-dart.log'); // bin/cache/fake-dart.log
  File get dartBinary => dartSdkDir.childDirectory('bin').childFile('dart'); // bin/cache/dart-sdk/bin/dart
  File get dartBinaryOrig => dartSdkDir.childDirectory('bin').childFile('dart.orig'); // bin/cache/dart-sdk/bin/dart.orig

  /// Run the tool entrypoint to update the cache, with the Dart binary faked out.
  ///
  /// The fake `dart` logs the commands it receives, and this method returns
  /// the list of log entries, for testing the entrypoint's behavior.
  ///
  /// The fake `dart` ignores most possible commands, except for logging them.
  /// For some commands used by the entrypoint when it tries to update the tool,
  /// it provides the needed behavior using shortcuts for efficiency:
  ///
  ///  * A command that looks like the entrypoint's `dart pub upgrade`
  ///    will fake it by updating the last-modified time on `pubspec.lock`.
  ///    (Each `pubspec.lock` in the baseline tree comes from [hostFlutterTree],
  ///    so effectively we rely on those being up to date.)
  ///
  ///  * A command that looks like the entrypoint's command to generate the
  ///    tool snapshot will fake it by copying from [hostFlutterTree].
  ///
  /// In particular, if this tree contains changes relative to [hostFlutterTree]
  /// that would affect the behavior of the tool, the resulting snapshot will
  /// not reflect those changes.
  List<String> ensureToolWithFakeDart() {
    fakeDartLog.writeAsStringSync('');
    dartBinary.renameSync(dartBinaryOrig.path);
    _writeFakeDart();
    ensureToolSync();
    dartBinaryOrig.renameSync(dartBinary.path);
    return fakeDartLog.readAsLinesSync();
  }

  /// Write to [dartBinary] a script that fakes out the `dart` command.
  ///
  /// See [ensureToolWithFakeDart].
  void _writeFakeDart() {
    dartBinary.writeAsStringSync('''
#!/usr/bin/env bash

full_command="dart \$*"

function log_command() {
  local description="\$1"
  echo "\$description: \$full_command" >>${shellEscapeString(fakeDartLog.path)}
}

case "\$*" in
  "pub upgrade "*)
    # This is a `dart pub upgrade` command, as in pub_upgrade_with_retry .
    # Just update the last-modified time on the pubspec.lock .
    touch pubspec.lock
    log_command "pub upgrade"
    ;;

  *" --disable-dart-dev "*" --snapshot-kind=app-jit "*)
    # This is the command to generate the snapshot,
    # in the upgrade_flutter function in bin/internal/shared.sh .
    # Fake generating the snapshot, by copying from the host tree.
    cp ${shellEscapeString(hostFlutterTree.snapshotFile.path)} \\
      ${shellEscapeString(snapshotFile.path)}
    log_command generate-snapshot
    ;;

  *" --disable-dart-dev "*" "${shellEscapeString(snapshotFile.path)} \\
  | *" --disable-dart-dev "*" "${shellEscapeString(snapshotFile.path)}" "*)
    # This looks like the "flutter" case at the end of shared::execute.
    # Do nothing.
    log_command flutter
    ;;

  *)
    # This is some other `dart` invocation we don't recognize;
    # perhaps the "dart" case at the end of shared::execute,
    # which leaves no recognizable signature of its own.
    # Do nothing.
    log_command other
esac
''');
    processManager.runSyncSuccess(<String>['chmod', '+x', dartBinary.path]); // https://github.com/dart-lang/sdk/issues/15078
  }
}
