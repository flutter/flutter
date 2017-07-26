// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/flutter_fasta.dart';
import 'package:kernel/target/targets.dart';

Map<String, Uri> loadDartLibraries(FileSystem fs) {
  final Uri libraries = new Uri.file(artifacts.getArtifactPath(Artifact.platformLibrariesJson));
  final dynamic map =
      JSON.decode(fs.file(libraries).readAsStringSync())['libraries'];
  final Map<String, Uri> dartLibraries = <String, Uri>{};
  map.forEach((String k, String v) => dartLibraries[k] = libraries.resolve(v));
  return dartLibraries;
}

Future<String> compile({String packagesPath, String mainPath}) async {
  final String platformKernelDill = artifacts.getArtifactPath(
      Artifact.platformKernelDill);
  // TODO(aam): Move FlutterFastaTarget to flutter tools.
  final CompilerOptions options = new CompilerOptions()
    ..packagesFileUri = Uri.parse(packagesPath)
    ..compileSdk = true
    ..linkedDependencies = <Uri>[Uri.parse(platformKernelDill)]
    ..target = new FlutterFastaTarget(new TargetFlags());
  final Program program =
      await kernelForProgram(new Uri.file(mainPath), options);
  if (program == null) {
    throwToolExit('Failed to produce kernel output.');
  }
  // TODO(aam): Is there better place for the output .dill file rather
  // than next to the source main dart file? It goes into .flx and
  // is interpreted by Dart VM as if it is a source code.
  final String kernelBinaryFilename = mainPath + ".dill";
  // TODO(aam): Consider using serializeProgram from
  // pkg/front_end/lib/src/fasta/kernel/utils.dart (helper function should be
  // moved to the kernel package too).
  // This is only relevant when we can use a summary input file
  // (and no linked-dependencies). At that point instead of serializing
  // a .dill file with an outline of the SDK, we can serialize just the
  // program portion and exclude the sdk code. This logic is what is used in
  // kernel-service.dart and in the incremental kernel generator to serialize
  // an incremental build.
  await writeProgramToBinary(program, kernelBinaryFilename);
  return kernelBinaryFilename;
}