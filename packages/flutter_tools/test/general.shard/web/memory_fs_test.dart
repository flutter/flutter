// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('correctly parses source, source map, metadata, manifest files', () {
    final fileSystem = MemoryFileSystem();
    final File source = fileSystem.file('source')..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')..writeAsStringSync('{}');
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(
        json.encode(<String, Object>{
          '/foo.js': <String, Object>{
            'code': <int>[0, source.lengthSync()],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, 2],
          },
        }),
      );
    final webMemoryFS = WebMemoryFS();
    webMemoryFS.write(source, manifest, sourcemap, metadata);

    expect(utf8.decode(webMemoryFS.files['foo.js']!), 'main() {}');
    expect(utf8.decode(webMemoryFS.sourcemaps['foo.js.map']!), '{}');
    expect(utf8.decode(webMemoryFS.metadataFiles['foo.js.metadata']!), '{}');
    expect(webMemoryFS.mergedMetadata, '{}');
  });

  testWithoutContext('skips modules whose manifest offsets are malformed', () {
    final fileSystem = MemoryFileSystem();
    final File source = fileSystem.file('source')..writeAsStringSync('main() {}');
    final File sourcemap = fileSystem.file('sourcemap')..writeAsStringSync('{}');
    final File metadata = fileSystem.file('metadata')..writeAsStringSync('{}');
    final File manifest = fileSystem.file('manifest')
      ..writeAsStringSync(
        json.encode(<String, Object>{
          '/good.js': <String, Object>{
            'code': <int>[0, source.lengthSync()],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, 2],
          },
          '/not_ints.js': <String, Object>{
            'code': <Object>['0', source.lengthSync()],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, 2],
          },
          '/wrong_length.js': <String, Object>{
            'code': <int>[0],
            'sourcemap': <int>[0, 2],
            'metadata': <int>[0, 2],
          },
          '/missing_key.js': <String, Object>{
            'code': <int>[0, source.lengthSync()],
            'sourcemap': <int>[0, 2],
          },
          '/not_a_map.js': 'nope',
        }),
      );
    final webMemoryFS = WebMemoryFS();
    final List<String> modules = webMemoryFS.write(source, manifest, sourcemap, metadata);

    expect(modules, <String>['good.js']);
    expect(webMemoryFS.files.keys, <String>['good.js']);
    expect(webMemoryFS.sourcemaps.keys, <String>['good.js.map']);
    expect(webMemoryFS.metadataFiles.keys, <String>['good.js.metadata']);
  });
}
