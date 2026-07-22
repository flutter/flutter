// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_hook_config/flutter_hook_config.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';

import '../../src/common.dart';

void main() {
  late FileSystem fileSystem;
  late Artifacts artifacts;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    artifacts = Artifacts.test(fileSystem: fileSystem);
  });

  testWithoutContext('createFlutterExtension resolves host tools to absolute file URIs', () {
    final FlutterExtension extension = createFlutterExtension(
      artifacts: artifacts,
      engineVersion: 'abc123',
    );

    expect(extension.engineVersion, 'abc123');
    expect(extension.impellerc.isScheme('file'), true);
    expect(extension.impellerc.isAbsolute, true);
    expect(
      extension.impellerc,
      Uri.file(artifacts.getHostArtifact(HostArtifact.impellerc).absolute.path),
    );
    expect(extension.libtessellator.isScheme('file'), true);
    expect(extension.libtessellator.isAbsolute, true);
    expect(
      extension.libtessellator,
      Uri.file(artifacts.getHostArtifact(HostArtifact.libtessellator).absolute.path),
    );
  });

  testWithoutContext('local engine version is stable until a host tool changes', () {
    final File impellerc = fileSystem.file(artifacts.getHostArtifact(HostArtifact.impellerc).path)
      ..writeAsStringSync('impellerc binary');
    fileSystem
        .file(artifacts.getHostArtifact(HostArtifact.libtessellator).path)
        .writeAsStringSync('libtessellator binary');

    final String before = createFlutterExtension(
      artifacts: artifacts,
      engineVersion: null,
    ).engineVersion;
    expect(before, isNotEmpty);
    expect(createFlutterExtension(artifacts: artifacts, engineVersion: null).engineVersion, before);

    impellerc.writeAsStringSync('rebuilt impellerc binary');
    final String after = createFlutterExtension(
      artifacts: artifacts,
      engineVersion: null,
    ).engineVersion;
    expect(after, isNot(before));
  });
}
