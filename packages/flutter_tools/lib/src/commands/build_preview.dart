import 'package:file/file.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../windows/build_windows.dart';
import 'build.dart';

class BuildPreviewCommand extends BuildSubCommand {
  BuildPreviewCommand({
    required super.logger,
    required super.verboseHelp,
    required this.fs,
    required this.flutterRoot,
    required this.processUtils,
  }) : super();

  @override
  final String name = '_preview';

  @override
  final bool hidden = true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.windows,
  };

  @override
  final String description = 'Build Flutter preview (desktop) app.';

  final FileSystem fs;
  final String flutterRoot;
  final ProcessUtils processUtils;

  static const BuildInfo buildInfo = BuildInfo(
    BuildMode.debug,
    null, // no flavor
    treeShakeIcons: false,
  );

  static const String appName = 'flutter_preview';

  @override
  Future<FlutterCommandResult> runCommand() async {
    //final Directory targetDir = fs.systemTempDirectory.createTempSync('flutter-build-preview');
    final Directory targetDir = fs.directory(flutterRoot).parent.createTempSync('flutter-build-preview-');
    final FlutterProject flutterProject = await _createProject(targetDir);
    print('about to build project at ${flutterProject.directory.path}');
    if (!globals.platform.isWindows) {
      throwToolExit('"build _preview" is only supported on Windows hosts.');
    }
    await buildWindows(
      flutterProject.windows,
      buildInfo,
    );
    final File previewDevice = targetDir
        // TODO this can be broken by config build-dir
        .childDirectory('build')
        .childDirectory('windows')
        .childDirectory('runner')
        .childDirectory('Debug')
        .childFile('$appName.exe');
    previewDevice.copySync(fs.path.join(
      flutterRoot,
      'artifacts_temp',
      'Debug',
      'flutter_preview.exe',
    ));
    return FlutterCommandResult.success();
  }

  Future<FlutterProject> _createProject(Directory targetDir) async {
    final List<String> args = <String>[
      fs.path.join(flutterRoot, 'bin', 'flutter.bat'),
      'create',
      '--empty',
      '--project-name',
      'flutter_preview',
      targetDir.path,
    ];
    final RunResult result = await processUtils.run(
      args,
      allowReentrantFlutter: true,
    );
    if (result.exitCode != 0) {
      logger.printError('${args.join(' ')} exited with code ${result.exitCode}');
      logger.printError('stdout:\n${result.stdout}\n');
      logger.printError('stderr:\n${result.stderr}\n');
      throw 'yikes';
    }
    return FlutterProject.fromDirectory(targetDir);
  }
}
