// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate_utils.dart';
import '../cache.dart';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    requiresPubspecYaml();
  }

  final bool _verbose;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrates flutter generated project files to the current flutter version';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();

    final Directory buildDir = globals.fs.directory(getBuildDirectory());
    print('HERE');

    List<String> files = await MigrateUtils.getFileNamesInDirectory(
      revision: '5344ed71561b924fb23300fb7fdb306744718767',
      searchPath: 'packages/flutter_tools/lib/src/android',
      workingDirectory: Cache.flutterRoot!,
    );
    for (String f in files) {
      print(f);
    }

    Directory tempDir = await MigrateUtils.createTempDirectory('tempdir1');

    String contents = await MigrateUtils.getFileContents(
      revision: '5344ed71561b924fb23300fb7fdb306744718767',
      file: files[4],
      workingDirectory: Cache.flutterRoot!,
    );
    print(contents);
    File fileOld = tempDir.childFile(files[4]);
    fileOld.createSync(recursive: true);
    fileOld.writeAsStringSync(contents, flush: true);

    File fileNew = globals.fs.file('${Cache.flutterRoot}/${files[4]}');
    // fileNew.createSync();

    String diff = await MigrateUtils.diffFiles(fileOld, fileNew);
    print(diff);

    print('DONE');

    return const FlutterCommandResult(ExitStatus.success);
  }
}
