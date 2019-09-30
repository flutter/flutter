// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../project.dart';

CompilerGenerator get compilerGenerator => context.get<CompilerGenerator>() ?? const CompilerGenerator();

/// Manages generation of a custom frontend_server.
abstract class CompilerGenerator {
  const factory CompilerGenerator() = _PubspecBasedCompilerGenerator;

  /// Creates a new frontend server instance based on project transformers.
  ///
  /// This generated server is injected into the cache artifacts. If the
  /// flutter project has no transformers, this method is a no-op.
  Future<void> generate();
}

class _PubspecBasedCompilerGenerator implements CompilerGenerator {
  const _PubspecBasedCompilerGenerator();

  @override
  Future<void> generate() async {
    final FlutterProject flutterProject = FlutterProject.current();
    // if (featureFlags.isKernelTransformersEnabled) {
    //   return;
    // }
    final YamlMap transformers = flutterProject.transformers;
    if (transformers == null || transformers.isEmpty) {
      return;
    }
    // TODO(jonahwilliams): support this on non-local engine build once
    // artifacts are published.
    if (artifacts is! LocalEngineArtifacts) {
      printError('transformers currently requires a local engine build.');
      return;
    }
    // Generating and/or checking the validity of the generated compiled
    // on each invocation of the flutter tool will be quite slow. Since
    // we run from source, our only input is the subset of the pubspec.
    final Directory generatedDirectory = flutterProject.dartTool
      .childDirectory('kernel_compiler');
    final File scriptIdFile = generatedDirectory.childFile('kernel_compiler.digest');
    final File buildSnapshot = generatedDirectory.childFile('kernel_compiler.dart.snapshot');
    final File buildScript = generatedDirectory.childFile('kernel_compiler.dart');
    final File syntheticPubspec = generatedDirectory.childFile('pubspec.yaml');
    final List<int> appliedBuilderDigest = _produceScriptId(transformers);

    if (scriptIdFile.existsSync() && buildSnapshot.existsSync()) {
      final List<int> previousAppliedBuilderDigest = scriptIdFile.readAsBytesSync();
      bool digestsAreEqual = false;
      if (appliedBuilderDigest.length == previousAppliedBuilderDigest.length) {
        digestsAreEqual = true;
        for (int i = 0; i < appliedBuilderDigest.length; i++) {
          if (appliedBuilderDigest[i] != previousAppliedBuilderDigest[i]) {
            digestsAreEqual = false;
            break;
          }
        }
      }
      if (digestsAreEqual) {
        KernelCompilerFactory.frontendServerLocation = buildSnapshot;
        ResidentCompiler.frontendServerOverride = buildSnapshot;
        return;
      }
    }
    // Clean-up all existing artifacts.
    if (flutterProject.dartTool.existsSync()) {
      flutterProject.dartTool.deleteSync(recursive: true);
    }
    final Status status = logger.startProgress('generating kernel coompiler...', timeout: null);
    try {
      generatedDirectory.createSync(recursive: true);
      final StringBuffer stringBuffer = StringBuffer();

      stringBuffer.writeln('name: flutter_tool');
      stringBuffer.writeln('dependencies:');
      if (transformers != null) {
        for (String name in transformers.keys) {
          final Object node = transformers[name];
          // For relative paths, make sure it is accounted for
          // parent directories.
          if (node is YamlMap && node['path'] != null) {
            final String path = node['path'];
            if (fs.path.isRelative(path)) {
              final String convertedPath = fs.path.join('..', '..', node['path']);
              stringBuffer.writeln('  $name:');
              stringBuffer.writeln('    path: $convertedPath');
            } else {
              stringBuffer.writeln('  $name: $node');
            }
          } else {
            stringBuffer.writeln('  $name: $node');
          }
        }
      }
      final String frontendServerSource = artifacts.getArtifactPath(Artifact.frontendServerSource);
      stringBuffer.writeln('  frontend_server:');
      stringBuffer.writeln('    path: $frontendServerSource');
      syntheticPubspec.writeAsStringSync(stringBuffer.toString());

      await pubGet(
        context: PubContext.pubGet,
        directory: generatedDirectory.path,
        upgrade: false,
        checkLastModified: false,
      );
      if (!scriptIdFile.existsSync()) {
        scriptIdFile.createSync(recursive: true);
      }
      scriptIdFile.writeAsBytesSync(appliedBuilderDigest);

      _writeEntrypoint(transformers.keys.cast<String>().toList(), generatedDirectory);

      final ProcessResult result = await processManager.run(<String>[
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        '--snapshot=${buildSnapshot.path}',
        '--snapshot-kind=kernel',
        '--packages=${fs.path.join(generatedDirectory.path, '.packages')}',
        buildScript.path,
      ]);
      if (result.exitCode != 0) {
        throwToolExit('Error generating build_script snapshot: ${result.stderr}');
      }
    } finally {
      status.stop();
    }
    KernelCompilerFactory.frontendServerLocation = buildSnapshot;
    ResidentCompiler.frontendServerOverride = buildSnapshot;
  }

  void _writeEntrypoint(List<String> transformers, Directory generatedDirectory) {
    int import = 0;
    final Map<String, Uri> packageMap = PackageMap(generatedDirectory.childFile('.packages').path).map;
    final StringBuffer buffer = StringBuffer();
    buffer.write('''
import 'dart:io';

import 'package:frontend_server/server.dart';

''');
    for (String transformer in transformers) {
      final Uri packageUri = packageMap[transformer].resolve('$transformer.dart');
      buffer.write('import "${packageUri.toFilePath()}" as i$import;');
      import += 1;
    }
    buffer.write('''
final CompositeProgramTransformer transformer = CompositeProgramTransformer(
[${<String>[for (int i = 0; i < transformers.length; i++) 'i$i.KernelTransformer()'].join(',')}]
);

void main(List<String> args) async {
  final int exitCode = await starter(args, transformer: transformer);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
''');
    generatedDirectory.childFile('kernel_compiler.dart')
      .writeAsStringSync(buffer.toString());
  }

  // Sorts the builders by name and produces a hashcode of the resulting iterable.
  List<int> _produceScriptId(YamlMap builders) {
    if (builders == null || builders.isEmpty) {
      return md5.convert(platform.version.codeUnits).bytes;
    }
    final List<String> orderedBuilderNames = builders.keys
      .cast<String>()
      .toList()..sort();
    final List<String> orderedBuilderValues = builders.values
      .map((dynamic value) => value.toString())
      .toList()..sort();
    return md5.convert(<String>[
      ...orderedBuilderNames,
      ...orderedBuilderValues,
      platform.version,
    ].join('').codeUnits).bytes;
  }
}
