// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/file_system.dart';
import '../depfile.dart';

/// Unpack the artifact list [artifacts] from [artifactPath] into a directory
/// [outputDirectory], returning a [Depfile] including all copied files.
Depfile unpackDesktopArtifacts({
  @required FileSystem fileSystem,
  @required List<String> artifacts,
  @required Directory outputDirectory,
  @required String artifactPath,
}) {
  final List<File> inputs = <File>[];
  final List<File> outputs = <File>[];
  for (final String artifact in artifacts) {
    final String entityPath = fileSystem.path.join(artifactPath, artifact);
    final FileSystemEntityType entityType = fileSystem.typeSync(entityPath);

    if (entityType == FileSystemEntityType.notFound
     || entityType == FileSystemEntityType.link) {
      throw Exception('Unsupported file type: $entityType');
    }

    // If this artifact is a file then copy the source over.
    if (entityType == FileSystemEntityType.file) {
      final String outputPath = fileSystem.path.join(
        outputDirectory.path,
        fileSystem.path.relative(entityPath, from: artifactPath),
      );
      final File destinationFile = fileSystem.file(outputPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      final File inputFile = fileSystem.file(entityPath);
      inputFile.copySync(destinationFile.path);
      inputs.add(inputFile);
      outputs.add(destinationFile);
      continue;
    }

    // If the artifact is a directory, recursively copy every file from it.
    for (final File input in fileSystem.directory(entityPath)
      .listSync(recursive: true)
      .whereType<File>()) {
      final String outputPath = fileSystem.path.join(
        outputDirectory.path,
        fileSystem.path.relative(input.path, from: artifactPath),
      );
      final File destinationFile = fileSystem.file(outputPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      final File inputFile = fileSystem.file(input);
      inputFile.copySync(destinationFile.path);
      inputs.add(inputFile);
      outputs.add(destinationFile);
    }
  }
  return Depfile(inputs, outputs);
}
