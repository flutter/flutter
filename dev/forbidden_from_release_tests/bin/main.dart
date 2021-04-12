// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

const ProcessManager processManager = LocalProcessManager();
const FileSystem fs = LocalFileSystem();

Future<void> main(List<String> args) async {
  final Options options = Options.fromArgs(args);

  final Directory tempDirectory = fs.systemTempDirectory.createTempSync('forbidden_imports');
  print('Using $tempDirectory for temporary files.');

  await pubGet(options.flutter, options.target.parent);
  final File dill = await compileKernel(
    tempDirectory: tempDirectory,
    dart: options.dart,
    target: options.target,
    feSnapshot: options.feSnapshot,
    sdkProduct: options.sdkProduct,
    packageConfig: options.packageConfig,
    packageName: options.packageName,
  );

  final File v8SnapshotInfo = await compileAOTSnapshot(
    tempDirectory: tempDirectory,
    genSnapshot: options.genSnapshot,
    dill: dill,
  );

  final String json = v8SnapshotInfo.readAsStringSync();
  final List<String> foundForbiddenTypes = <String>[];
  for (final String forbiddenType in options.forbiddenTypes) {
    if (json.contains(forbiddenType)) {
      foundForbiddenTypes.add(forbiddenType);
    }
  }
  if (foundForbiddenTypes.isNotEmpty) {
    print('The output contained the following forbidden types:');
    print(foundForbiddenTypes);
    exit(-1);
  }

  print('No forbidden types found.');
  tempDirectory.deleteSync(recursive: true);
}

Future<void> pubGet(File flutter, Directory target) async {
  final List<String> command = <String>[flutter.path, 'pub', 'get'];

  await _runStreamed(
    command,
    workingDirectory: target.path,
  );
}

Future<File> compileKernel({
  required Directory tempDirectory,
  required File dart,
  required File target,
  required File feSnapshot,
  required Directory sdkProduct,
  required File packageConfig,
  required String packageName,
}) async {
  final File dill = tempDirectory.childFile('forbidden_release_imports.dill');
  final List<String> command = <String>[
    dart.path,
    '--disable-dart-dev',
    feSnapshot.path,
    '--sdk-root',
    sdkProduct.path,
    '--target',
    'flutter',
    '--no-print-incremental-dependencies',
    '-Ddart.vm.profile=false',
    '-Ddart.vm.product=true',
    '--aot',
    '--tfa',
    '--packages',
    packageConfig.path,
    '--output-dill',
    dill.path,
    packageName,
  ];

  await _runStreamed(command);
  return dill;
}

Future<File> compileAOTSnapshot({
  required Directory tempDirectory,
  required File genSnapshot,
  required File dill,
}) async {
  final File v8SnapshotProfile = tempDirectory.childFile('size.json');
  final List<String> command = <String>[
    genSnapshot.path,
    '--deterministic',
    '--write-v8-snapshot-profile-to=${v8SnapshotProfile.path}',
    '--snapshot_kind=app-aot-elf',
    '--elf=${tempDirectory.childFile('app.so').path}',
    '--strip',
    dill.path,
  ];

  await _runStreamed(command);
  return v8SnapshotProfile;
}

class Options {
  const Options({
    required this.flutter,
    required this.dart,
    required this.genSnapshot,
    required this.feSnapshot,
    required this.target,
    required this.sdkProduct,
    required this.packageConfig,
    required this.packageName,
    required this.forbiddenTypes,
  });

  factory Options.fromArgs(List<String> args) {
    final String exe = Platform.isWindows ? '.exe' : '';
    final String bat = Platform.isWindows ? '.bat' : '';

    final ArgParser argParser = ArgParser();
    argParser.addOption(
      'dart',
      help: 'The path to the dart binary.',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'bin', 'cache', 'dart-sdk', 'bin', 'dart$exe'),
      defaultsTo: path.join(fs.currentDirectory.path, 'bin', 'cache', 'dart-sdk', 'bin', 'dart$exe'),
    );
    argParser.addOption(
      'flutter',
      help: 'The path to the flutter binary.',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'bin', 'flutter$bat'),
      defaultsTo: path.join(fs.currentDirectory.path, 'bin', 'flutter$bat'),
    );
    argParser.addOption(
      'gen-snapshot',
      help: 'The path to gen_snapshot.',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'bin', 'cache', 'artifacts', 'engine', 'android-arm64-release', _getPlatformName(), 'gen_snapshot$exe'),
      defaultsTo: path.join(fs.currentDirectory.path, 'bin', 'cache', 'artifacts', 'engine', 'android-arm64-release', _getPlatformName(),'gen_snapshot$exe'),
    );
    argParser.addOption(
      'fe-snapshot',
      help: 'The path to the frontend server snapshot.',
      valueHelp: path.join(
          r'$FLUTTER_ROOT', 'bin', 'cache', 'artifacts', 'engine', _getPlatformName(), 'frontend_server.dart.snapshot'),
      defaultsTo: path.join(fs.currentDirectory.path, 'bin', 'cache', 'artifacts', 'engine', _getPlatformName(),
          'frontend_server.dart.snapshot'),
    );
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'The Dart entrypoint file.',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'examples', 'hello_world', 'lib', 'main.dart'),
      defaultsTo: path.join(fs.currentDirectory.path, 'examples', 'hello_world', 'lib', 'main.dart'),
    );
    argParser.addOption(
      'sdk-product',
      help: 'The flutter patched sdk.',
      valueHelp:
          path.join(r'$FLUTTER_ROOT', 'bin', 'cache', 'artifacts', 'engine', 'common', 'flutter_patched_sdk_product'),
      defaultsTo: path.join(
          fs.currentDirectory.path, 'bin', 'cache', 'artifacts', 'engine', 'common', 'flutter_patched_sdk_product'),
    );
    argParser.addOption(
      'package-config',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'examples', 'hello_world', '.dart_tool', 'package_config.json'),
      defaultsTo: path.join(fs.currentDirectory.path, 'examples', 'hello_world', '.dart_tool', 'package_config.json'),
    );

    argParser.addOption(
      'package-name',
      valueHelp: 'package:hello_world/main.dart',
      defaultsTo: 'package:hello_world/main.dart',
    );

    argParser.addMultiOption(
      'forbidden-type',
      help: 'Type name(s) to forbid from release compilation.',
    );

    argParser.addFlag('help', help: 'Prints usage.', negatable: false);
    final ArgResults argResults = argParser.parse(args);

    if (argResults['help'] == true) {
      print(argParser.usage);
      exit(0);
    }

    return Options(
      flutter: _getFileArg(argResults, 'flutter'),
      dart: _getFileArg(argResults, 'dart'),
      genSnapshot: _getFileArg(argResults, 'gen-snapshot'),
      target: _getFileArg(argResults, 'target'),
      feSnapshot: _getFileArg(argResults, 'fe-snapshot'),
      sdkProduct: _getDirectoryArg(argResults, 'sdk-product'),
      packageConfig: _getFileArg(argResults, 'package-config'),
      packageName: argResults['package-name'] as String,
      forbiddenTypes: Set<String>.from(argResults['forbidden-type'] as List<String>),
    );
  }

  final File flutter;
  final File dart;
  final File genSnapshot;
  final File feSnapshot;
  final File target;
  final Directory sdkProduct;
  final File packageConfig;
  final String packageName;
  final Set<String> forbiddenTypes;

  static String _getPlatformName() {
    if (Platform.isMacOS) {
      return 'darwin-x64';
    }
    if (Platform.isLinux) {
      return 'linux-x64';
    }
    if (Platform.isWindows) {
      return 'windows-x64';
    }
    throw UnsupportedError('Platform not supported.');
  }

  static File _getFileArg(ArgResults argResults, String argName) {
    final File result = fs.file(argResults[argName] as String);
    if (!result.existsSync()) {
      print('The $argName file at $result could not be found.');
      exit(-1);
    }
    return result;
  }

  static Directory _getDirectoryArg(ArgResults argResults, String argName) {
    final Directory result = fs.directory(argResults[argName] as String);
    if (!result.existsSync()) {
      print('The $argName file at $result could not be found.');
      exit(-1);
    }
    return result;
  }
}

Future<void> _runStreamed(List<String> command, {String? workingDirectory}) async {
  final String workingDirectoryInstruction = workingDirectory != null
      ? ' in directory $workingDirectory'
      : '';

  print('Running command ${command.join(' ')}$workingDirectoryInstruction');
  final Process process = await processManager.start(command, workingDirectory: workingDirectory);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);

  final int exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}