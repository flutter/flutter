// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/web/web_resources.dart';

import '../../src/common.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late Directory webDirectory;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    webDirectory = fileSystem.directory('/app/web')..createSync(recursive: true);
  });

  File writeFile(String relativePath, {String? inDirectory}) {
    final File file = fileSystem.file(
      fileSystem.path.joinAll(<String>[
        inDirectory ?? webDirectory.path,
        ...relativePath.split('/'),
      ]),
    );
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(relativePath);
    return file;
  }

  List<String> paths(List<WebResource> resources) => <String>[
    for (final WebResource resource in resources) resource.relativePath,
  ];

  test('returns shared resources when no flavor is given', () {
    writeFile('index.html');
    writeFile('manifest.json');
    writeFile('icons/icon.png');

    final List<WebResource> resources = resolveWebResources(webDirectory: webDirectory);

    expect(paths(resources), <String>['icons/icon.png', 'index.html', 'manifest.json']);
  });

  test('does not expose the flavors directory as a resource path', () {
    writeFile('index.html');
    writeFile('flavors/staging/manifest.json');

    final List<WebResource> resources = resolveWebResources(
      webDirectory: webDirectory,
      flavor: 'staging',
    );

    expect(paths(resources), <String>['index.html', 'manifest.json']);
    expect(
      paths(resources).where((String path) => path.startsWith('flavors/')),
      isEmpty,
    );
  });

  test('a flavor file replaces the shared file', () {
    writeFile('index.html');
    writeFile('manifest.json');
    final File flavorManifest = writeFile('flavors/staging/manifest.json');

    final List<WebResource> resources = resolveWebResources(
      webDirectory: webDirectory,
      flavor: 'staging',
    );

    expect(paths(resources), <String>['index.html', 'manifest.json']);
    final WebResource manifest = resources.firstWhere(
      (WebResource resource) => resource.relativePath == 'manifest.json',
    );
    expect(manifest.file.path, flavorManifest.path);
  });

  test('files that only exist in the flavor directory are added', () {
    writeFile('index.html');
    writeFile('flavors/staging/robots.txt');

    final List<WebResource> resources = resolveWebResources(
      webDirectory: webDirectory,
      flavor: 'staging',
    );

    expect(paths(resources), <String>['index.html', 'robots.txt']);
  });

  test('nested directories are merged rather than replaced', () {
    writeFile('.well-known/assetlinks.json');
    writeFile('flavors/staging/.well-known/apple-app-site-association');

    final List<WebResource> resources = resolveWebResources(
      webDirectory: webDirectory,
      flavor: 'staging',
    );

    expect(paths(resources), <String>[
      '.well-known/apple-app-site-association',
      '.well-known/assetlinks.json',
    ]);
  });

  test('other flavor directories are never included', () {
    writeFile('index.html');
    writeFile('flavors/development/index.html');
    writeFile('flavors/staging/manifest.json');

    final List<WebResource> resources = resolveWebResources(
      webDirectory: webDirectory,
      flavor: 'development',
    );

    expect(paths(resources), <String>['index.html']);
  });

  test('a missing flavor directory falls back to shared resources', () {
    writeFile('index.html');
    writeFile('manifest.json');

    final List<WebResource> resources = resolveWebResources(
      webDirectory: webDirectory,
      flavor: 'production',
    );

    expect(paths(resources), <String>['index.html', 'manifest.json']);
  });

  test('a flavor name that is not a single path segment is ignored', () {
    writeFile('index.html');
    writeFile('secret.json', inDirectory: '/app');

    for (final flavor in <String>['..', '.', '../app', 'a/b', r'a\b', '']) {
      final List<WebResource> resources = resolveWebResources(
        webDirectory: webDirectory,
        flavor: flavor,
      );

      expect(paths(resources), <String>['index.html'], reason: 'flavor "$flavor"');
    }
  });

  test('a missing web directory resolves to no resources', () {
    expect(
      resolveWebResources(webDirectory: fileSystem.directory('/app/missing'), flavor: 'staging'),
      isEmpty,
    );
  });

  test('resolveWebResourceFile prefers the flavor file', () {
    writeFile('index.html');
    final File flavorIndex = writeFile('flavors/staging/index.html');

    final File? resolved = resolveWebResourceFile(
      webDirectory: webDirectory,
      relativePath: 'index.html',
      flavor: 'staging',
    );

    expect(resolved?.path, flavorIndex.path);
  });

  test('resolveWebResourceFile falls back to the shared file', () {
    final File sharedIndex = writeFile('index.html');

    final File? resolved = resolveWebResourceFile(
      webDirectory: webDirectory,
      relativePath: 'index.html',
      flavor: 'staging',
    );

    expect(resolved?.path, sharedIndex.path);
  });

  test('resolveWebResourceFile returns null when neither file exists', () {
    expect(
      resolveWebResourceFile(
        webDirectory: webDirectory,
        relativePath: 'index.html',
        flavor: 'staging',
      ),
      isNull,
    );
  });
}
