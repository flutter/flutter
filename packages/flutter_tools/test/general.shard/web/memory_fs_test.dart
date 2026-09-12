// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';
import 'package:flutter_tools/src/web/module_metadata.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('correctly parses source, source map, metadata, manifest files', () {
    const fooModuleFile = 'foo.js';
    const fooSourceMapFile = 'foo.js.map';
    const fooMetadataFile = 'foo.js.metadata';

    final fileSystem = MemoryFileSystem();
    final File source = fileSystem.file('source')..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')..writeAsStringSync('{}');
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(
        json.encode(<String, Object>{
          '/$fooModuleFile': <String, Object>{
            'code': <int>[0, source.lengthSync()],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, 2],
          },
        }),
      );
    final webMemoryFS = WebMemoryFS();
    webMemoryFS.write(source, manifest, sourcemap, metadata);

    expect(utf8.decode(webMemoryFS.files[fooModuleFile]!), 'main() {}');
    expect(utf8.decode(webMemoryFS.sourcemaps[fooSourceMapFile]!), '{}');
    expect(utf8.decode(webMemoryFS.metadataFiles[fooMetadataFile]!), '{}');
    expect(webMemoryFS.mergedMetadata, '{}');
  });

  testWithoutContext('evicts stale modules when libraries move to a new module bundle', () {
    const dummyModuleFile = 'packages/app/dummy.dart.lib.js';
    const dummyMetadataFile = 'packages/app/dummy.dart.lib.js.metadata';
    const dummySourceMapFile = 'packages/app/dummy.dart.lib.js.map';
    const dummyLibUri = 'package:app/dummy.dart';

    const mainModuleFile = 'packages/app/main.dart.lib.js';
    const mainMetadataFile = 'packages/app/main.dart.lib.js.metadata';
    const mainLibUri = 'package:app/main.dart';

    final fileSystem = MemoryFileSystem();
    final webMemoryFS = WebMemoryFS();

    // 1. Initial compilation: dummy.dart and main.dart are in an import cycle and
    // bundled together into 'packages/app/dummy.dart.lib.js'.
    final File initialSource = fileSystem.file('initial_source')
      ..writeAsStringSync('// dummy + main v1');
    final File initialSourcemap = fileSystem.file('initial_sourcemap')..writeAsStringSync('{}');
    final String initialMetadataJson = json.encode(
      ModuleMetadata('dummy.dart.lib.js', 'closure', 'dummy.map', 'dummy.dart.lib.js')
        ..addLibrary(LibraryMetadata('dummy', dummyLibUri, <String>[]))
        ..addLibrary(LibraryMetadata('main', mainLibUri, <String>[]))
        ..toJson(),
    );
    final File initialMetadata = fileSystem.file('initial_metadata')
      ..writeAsStringSync(initialMetadataJson);
    final File initialManifest = fileSystem.file('initial_manifest')
      ..writeAsStringSync(
        json.encode(<String, Object>{
          '/$dummyModuleFile': <String, Object>{
            'code': <int>[0, initialSource.lengthSync()],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, initialMetadata.lengthSync()],
          },
        }),
      );

    webMemoryFS.write(initialSource, initialManifest, initialSourcemap, initialMetadata);

    expect(utf8.decode(webMemoryFS.files[dummyModuleFile]!), '// dummy + main v1');
    expect(webMemoryFS.metadataFiles.containsKey(dummyMetadataFile), isTrue);
    expect(webMemoryFS.mergedMetadata, contains(dummyLibUri));
    expect(webMemoryFS.mergedMetadata, contains(mainLibUri));

    // 2. Recompilation: The cycle is broken by modifying main.dart.
    // main.dart is now compiled into its own module 'packages/app/main.dart.lib.js'.
    // dummy.dart was not modified, so it is not recompiled.
    final File updatedSource = fileSystem.file('updated_source')..writeAsStringSync('// main v2');
    final File updatedSourcemap = fileSystem.file('updated_sourcemap')..writeAsStringSync('{}');
    final String updatedMetadataJson = json.encode(
      ModuleMetadata('main.dart.lib.js', 'closure', 'main.map', 'main.dart.lib.js')
        ..addLibrary(LibraryMetadata('main', mainLibUri, <String>[]))
        ..toJson(),
    );
    final File updatedMetadata = fileSystem.file('updated_metadata')
      ..writeAsStringSync(updatedMetadataJson);
    final File updatedManifest = fileSystem.file('updated_manifest')
      ..writeAsStringSync(
        json.encode(<String, Object>{
          '/$mainModuleFile': <String, Object>{
            'code': <int>[0, updatedSource.lengthSync()],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, updatedMetadata.lengthSync()],
          },
        }),
      );

    webMemoryFS.write(updatedSource, updatedManifest, updatedSourcemap, updatedMetadata);

    // The new module should be present.
    expect(utf8.decode(webMemoryFS.files[mainModuleFile]!), '// main v2');
    expect(webMemoryFS.metadataFiles.containsKey(mainMetadataFile), isTrue);

    // The stale module containing the old main.dart definition MUST be evicted.
    expect(webMemoryFS.files.containsKey(dummyModuleFile), isFalse);
    expect(webMemoryFS.sourcemaps.containsKey(dummySourceMapFile), isFalse);
    expect(webMemoryFS.metadataFiles.containsKey(dummyMetadataFile), isFalse);

    // Merged metadata must not contain the stale dummy module metadata.
    expect(webMemoryFS.mergedMetadata, contains(mainLibUri));
    expect(webMemoryFS.mergedMetadata, isNot(contains('dummy.dart.lib.js')));
  });
}
