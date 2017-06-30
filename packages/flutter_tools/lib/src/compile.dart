// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io' as io show File;

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/flutter_fasta.dart';
import 'package:kernel/target/targets.dart';

Map<String, Uri> loadDartLibraries() {
  final Uri libraries = new Uri.file(artifacts.getArtifactPath(Artifact.platformLibrariesJson));
  final dynamic map = JSON.decode(new io.File.fromUri(libraries).readAsStringSync())['libraries'];
  final Map<String, Uri> dartLibraries = <String, Uri>{};
  map.forEach((String k, String v) => dartLibraries[k] = libraries.resolve(v));
  return dartLibraries;
}

Future<String> compile({String packagesPath, String mainPath}) async {
  final String platformKernelDill = artifacts.getArtifactPath(
      Artifact.platformKernelDill);
  // TODO(aam): Move FlutterFastaTarget to flutter tools.
  final CompilerOptions options = new CompilerOptions()
    ..dartLibraries = loadDartLibraries()
    ..packagesFileUri = Uri.parse(packagesPath)
    ..sdkSummary = Uri.parse(platformKernelDill)
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
  await writeProgramToBinary(program, kernelBinaryFilename);
  return kernelBinaryFilename;
}