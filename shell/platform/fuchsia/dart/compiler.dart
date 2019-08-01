// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';

import 'package:vm/kernel_front_end.dart'
    show createCompilerArgParser, runCompiler, successExitCode;

final ArgParser _argParser = createCompilerArgParser()
  ..addFlag('train',
      help: 'Run through sample command line to produce snapshot',
      negatable: false)
  ..addOption('component-name', help: 'Name of the component')
  ..addOption('data-dir',
      help: 'Name of the subdirectory of //data for output files')
  ..addOption('manifest', help: 'Path to output Fuchsia package manifest');

String _usage = '''
Usage: compiler [options] input.dart

Options:
${_argParser.usage}
''';

Future<void> main(List<String> args) async {
  ArgResults options;

  try {
    options = _argParser.parse(args);

    if (options['train']) {
      final Directory temp =
          Directory.systemTemp.createTempSync('train_kernel_compiler');
      try {
        options = _argParser.parse(<String>[
          '--manifest=flutter',
          '--data-dir=${temp.absolute}',
        ]);

        await runCompiler(options, _usage);
        return;
      } finally {
        temp.deleteSync(recursive: true);
      }
    }

    if (!options.rest.isNotEmpty) {
      throw Exception('Must specify input.dart');
    }
  } on Exception catch (error) {
    print('ERROR: $error\n');
    print(_usage);
    exitCode = 1;
    return;
  }

  final compilerExitCode = await runCompiler(options, _usage);
  if (compilerExitCode != successExitCode) {
    exitCode = compilerExitCode;
    return;
  }

  final String output = options['output'];
  final String dataDir = options.options.contains('component-name')
      ? options['component-name']
      : options['data-dir'];
  final String manifestFilename = options['manifest'];

  if (manifestFilename != null) {
    await createManifest(manifestFilename, dataDir, output);
  }
}

Future createManifest(
    String packageManifestFilename, String dataDir, String output) async {
  List<String> packages = await File('$output-packages').readAsLines();

  // Make sure the 'main' package is the last (convention with package loader).
  packages.remove('main');
  packages.add('main');

  final IOSink packageManifest = File(packageManifestFilename).openWrite();

  final String kernelListFilename = '$packageManifestFilename.dilplist';
  final IOSink kernelList = File(kernelListFilename).openWrite();
  for (String package in packages) {
    final String filenameInPackage = '$package.dilp';
    final String filenameInBuild = '$output-$package.dilp';
    packageManifest
        .write('data/$dataDir/$filenameInPackage=$filenameInBuild\n');
    kernelList.write('$filenameInPackage\n');
  }
  await kernelList.close();

  final String frameworkVersionFilename =
      '$packageManifestFilename.frameworkversion';
  final IOSink frameworkVersion = File(frameworkVersionFilename).openWrite();
  for (String package in [
    'collection',
    'flutter',
    'meta',
    'typed_data',
    'vector_math'
  ]) {
    Digest digest;
    if (packages.contains(package)) {
      final filenameInBuild = '$output-$package.dilp';
      final bytes = await File(filenameInBuild).readAsBytes();
      digest = sha256.convert(bytes);
    }
    frameworkVersion.write('$package=$digest\n');
  }
  await frameworkVersion.close();

  packageManifest.write('data/$dataDir/app.dilplist=$kernelListFilename\n');
  packageManifest
      .write('data/$dataDir/app.frameworkversion=$frameworkVersionFilename\n');
  await packageManifest.close();
}
