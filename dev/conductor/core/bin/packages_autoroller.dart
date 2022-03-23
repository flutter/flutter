import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:conductor_core/conductor_core.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const String kTokenOption = 'token';
const String kGithubClient = 'github-client';

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser.addOption(
    kTokenOption,
    help: 'GitHub access token.',
    mandatory: true,
  );
  parser.addOption(
    kGithubClient,
    help: 'Path to GitHub CLI client.',
    mandatory: true,
  );

  final FrameworkRepository framework = FrameworkRepository(_localCheckouts);
  final ArgResults results = parser.parse(args);
  await PackageAutoroller(
    framework: framework,
    githubClient: results[kGithubClient] as String,
    token: results[kTokenOption] as String,
  ).roll();
}

Checkouts get _localCheckouts {
  const FileSystem fileSystem = LocalFileSystem();
  const ProcessManager processManager = LocalProcessManager();
  const Platform platform = LocalPlatform();
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );
  return Checkouts(
    fileSystem: fileSystem,
    parentDirectory: _localFlutterRoot.parent,
    platform: platform,
    processManager: processManager,
    stdio: stdio,
  );
}

Directory get _localFlutterRoot {
  String filePath;
  const FileSystem fileSystem = LocalFileSystem();
  const Platform platform = LocalPlatform();

  filePath = platform.script.toFilePath();
  final String checkoutsDirname = fileSystem.path.normalize(
    fileSystem.path.join(
      fileSystem.path.dirname(filePath), // flutter/dev/conductor/core/bin
      '..', // flutter/dev/conductor/core
      '..', // flutter/dev/conductor
      '..', // flutter/dev
      '..', // flutter
    ),
  );
  return fileSystem.directory(checkoutsDirname);
}
