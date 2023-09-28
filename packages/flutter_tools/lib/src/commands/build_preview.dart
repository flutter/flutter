import 'package:file/file.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/io.dart';
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
    required bool verboseHelp,
    required this.fs,
    required this.flutterRoot,
    required this.processUtils,
    required this.artifacts,
  }) : super(verboseHelp: verboseHelp) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
  }

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
  final Artifacts artifacts;

  static const BuildInfo buildInfo = BuildInfo(
    BuildMode.debug,
    null, // no flavor
    // users may add icons later
    treeShakeIcons: false,
  );

  @override
  void requiresPubspecYaml() {}

  static const String appName = 'flutter_preview';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory targetDir = fs.systemTempDirectory.createTempSync('flutter-build-preview');
    final FlutterProject flutterProject = await _createProject(targetDir);
    if (!globals.platform.isWindows) {
      throwToolExit('"build _preview" is currently only supported on Windows hosts.');
    }
    await buildWindows(
      flutterProject.windows,
      buildInfo,
    );

    final File previewDevice = targetDir
        .childDirectory(getWindowsBuildDirectory(TargetPlatform.windows_x64))
        .childDirectory('runner')
        .childDirectory('Debug')
        .childFile('$appName.exe');
    if (!previewDevice.existsSync()) {
      throw StateError('Preview device not found at ${previewDevice.absolute.path}');
    }
    final String newPath = artifacts.getArtifactPath(Artifact.flutterPreviewDevice);
    fs.file(newPath).parent.createSync(recursive: true);
    previewDevice.copySync(newPath);
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
      final StringBuffer buffer = StringBuffer('${args.join(' ')} exited with code ${result.exitCode}');
      buffer.writeln('stdout:\n${result.stdout}\n');
      buffer.writeln('stderr:\n${result.stderr}');
      throw ProcessException(args.first, args.sublist(1), buffer.toString(), result.exitCode);
    }
    return FlutterProject.fromDirectory(targetDir);
  }
}
