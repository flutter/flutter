// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:bazel_tools/bazel_tools.dart';
import 'package:test/test.dart';

void main() {
  const lock = '''
packages:
  async:
    dependency: "direct main"
    description:
      name: async
      sha256: e2eb0491ba5ddb6177742d2da23904574082139b07c1e33b8503b9f46f3e1a37
      url: "https://pub.dev"
    source: hosted
    version: "2.13.0"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_tools:
    dependency: "direct main"
    description:
      path: "packages/flutter_tools"
      relative: true
    source: path
    version: "0.0.0"
sdks:
  dart: ">=3.13.0 <4.0.0"
''';

  test('parses the hosted packages with their pins and keeps the rest by source', () {
    final PubLock parsed = PubLock.parse(lock);
    expect(parsed.hosted.keys, <String>['async']);
    final HostedPackage async = parsed.hosted['async']!;
    expect(async.version, '2.13.0');
    expect(async.sha256, 'e2eb0491ba5ddb6177742d2da23904574082139b07c1e33b8503b9f46f3e1a37');
    expect(async.archiveUrl, 'https://pub.dev/api/archives/async-2.13.0.tar.gz');
    expect(parsed.others, <String, String>{'sky_engine': 'sdk', 'flutter_tools': 'path'});
  });

  // The configuration `pub get` writes for that lock: the hosted package in
  // the pub cache (its root URI without a trailing slash, as pub writes it),
  // the tree's packages relative to .dart_tool/.
  const packageConfig = '''
{
  "configVersion": 2,
  "packages": [
    {"name": "async", "rootUri": "file:///home/me/.pub-cache/hosted/pub.dev/async-2.13.0", "packageUri": "lib/"},
    {"name": "sky_engine", "rootUri": "file:///home/me/repo/bin/cache/pkg/sky_engine", "packageUri": "lib/"},
    {"name": "flutter_tools", "rootUri": "../packages/flutter_tools", "packageUri": "lib/"},
    {"name": "flutter", "rootUri": "../packages/flutter/", "packageUri": "lib/"},
    {"name": "_root", "rootUri": "../", "packageUri": "lib/"}
  ]
}
''';
  const pubspecs = <String, String>{
    '/home/me/.pub-cache/hosted/pub.dev/async-2.13.0/pubspec.yaml': '''
name: async
dependencies:
  meta: ^1.0.0
  collection: any
dev_dependencies:
  test: any
''',
    '/home/me/repo/packages/flutter_tools/pubspec.yaml': '''
name: flutter_tools
dependencies:
  async: any
''',
    '/home/me/repo/packages/flutter/pubspec.yaml': '''
name: flutter
dependencies:
  sky_engine:
    sdk: flutter
dev_dependencies:
  flutter_tools:
    path: ../flutter_tools
''',
    '/home/me/repo/pubspec.yaml': '''
name: _root
workspace:
  - packages/flutter
''',
  };
  PubWorkspace resolve() => PubWorkspace.resolve(
    lock: PubLock.parse(lock),
    packageConfigJson: packageConfig,
    packageConfigUri: Uri.parse('file:///home/me/repo/.dart_tool/package_config.json'),
    repositoryRoot: Uri.parse('file:///home/me/repo/'),
    readPubspec: (Uri pubspec) => pubspecs[pubspec.toFilePath()],
  );

  test('parses the names a pubspec declares', () {
    final PubspecDependencies parsed = PubspecDependencies.parse('''
name: x
dependencies:
  b: any
  a:
    sdk: flutter
''');
    expect(parsed.dependencies, <String>['a', 'b']);
    expect(parsed.devDependencies, isEmpty);
  });

  test("resolves the workspace: hosted dependencies, the tree's packages by path", () {
    final PubWorkspace workspace = resolve();
    expect(workspace.hostedDependencies, <String, List<String>>{
      'async': <String>['collection', 'meta'],
    });
    expect(workspace.packages.keys, <String>['flutter_tools', 'flutter', '_root']);
    expect(workspace.packages['flutter_tools']!.path, 'packages/flutter_tools');
    expect(workspace.packages['flutter_tools']!.dependencies.dependencies, <String>['async']);
    expect(workspace.packages['flutter']!.path, 'packages/flutter');
    expect(workspace.packages['flutter']!.dependencies.dependencies, <String>['sky_engine']);
    expect(workspace.packages['flutter']!.dependencies.devDependencies, <String>['flutter_tools']);
    expect(workspace.packages['_root']!.path, '.');
  });

  test("rejects a configuration without the lock's hosted packages", () {
    expect(
      () => PubWorkspace.resolve(
        lock: PubLock.parse(lock),
        packageConfigJson: '{"configVersion": 2, "packages": []}',
        packageConfigUri: Uri.parse('file:///home/me/repo/.dart_tool/package_config.json'),
        repositoryRoot: Uri.parse('file:///home/me/repo/'),
        readPubspec: (Uri pubspec) => null,
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('async'),
        ),
      ),
    );
  });

  test('rejects a package without a pubspec', () {
    expect(
      () => PubWorkspace.resolve(
        lock: PubLock.parse(lock),
        packageConfigJson: packageConfig,
        packageConfigUri: Uri.parse('file:///home/me/repo/.dart_tool/package_config.json'),
        repositoryRoot: Uri.parse('file:///home/me/repo/'),
        readPubspec: (Uri pubspec) => null,
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('run `pub get` first'),
        ),
      ),
    );
  });

  test('renders pub.lock.bzl', () {
    final String bzl = generatePubLock(
      PubLock.parse(lock),
      resolve(),
      generator: 'gen_pub_lock.dart',
    );
    expect(bzl, contains("Generated from //pubspec.lock and the packages' pubspecs by"));
    expect(
      bzl,
      contains('''
PUB_HOSTED = {
    "async": struct(
        version = "2.13.0",
        sha256 = "e2eb0491ba5ddb6177742d2da23904574082139b07c1e33b8503b9f46f3e1a37",
        url = "https://pub.dev/api/archives/async-2.13.0.tar.gz",
        deps = [
            "collection",
            "meta",
        ],
    ),
}
'''),
    );
    expect(
      bzl,
      contains('''
PUB_WORKSPACE = {
    "_root": struct(
        path = ".",
        deps = [],
        dev_deps = [],
    ),
    "flutter": struct(
        path = "packages/flutter",
        deps = [
            "sky_engine",
        ],
        dev_deps = [
            "flutter_tools",
        ],
    ),
    "flutter_tools": struct(
        path = "packages/flutter_tools",
        deps = [
            "async",
        ],
        dev_deps = [],
    ),
}
'''),
    );
    // The path packages are the tree's; only the SDK's stays on record.
    expect(
      bzl,
      contains('''
PUB_OTHER_SOURCES = {
    "sky_engine": "sdk",
}
'''),
    );
    expect(bzl, endsWith('PUB_LOCKS = {\n}\n'));
  });

  test("renders the tree's other locks under PUB_LOCKS, by directory", () {
    // A lock resolved apart from the workspace, pinning its own version of a
    // hosted package and a path package of the tree.
    const otherLock = '''
packages:
  async:
    dependency: "direct dev"
    description:
      name: async
      sha256: "0000000000000000000000000000000000000000000000000000000000000000"
      url: "https://pub.dev"
    source: hosted
    version: "2.11.0"
  web_engine_tester:
    dependency: "direct dev"
    description:
      path: "../../web_sdk/web_engine_tester"
      relative: true
    source: path
    version: "0.0.0"
''';
    const otherConfig = '''
{
  "configVersion": 2,
  "packages": [
    {"name": "async", "rootUri": "file:///home/me/.pub-cache/hosted/pub.dev/async-2.11.0", "packageUri": "lib/"},
    {"name": "web_engine_tester", "rootUri": "../../../web_sdk/web_engine_tester", "packageUri": "lib/"},
    {"name": "ui", "rootUri": "../", "packageUri": "lib/"}
  ]
}
''';
    const otherPubspecs = <String, String>{
      '/home/me/.pub-cache/hosted/pub.dev/async-2.11.0/pubspec.yaml': '''
name: async
dependencies:
  meta: any
''',
      '/home/me/repo/engine/src/flutter/web_sdk/web_engine_tester/pubspec.yaml': '''
name: web_engine_tester
dependencies:
  ui:
    path: ../../lib/web_ui
''',
      '/home/me/repo/engine/src/flutter/lib/web_ui/pubspec.yaml': '''
name: ui
dev_dependencies:
  async: 2.11.0
  web_engine_tester:
    path: ../../web_sdk/web_engine_tester
''',
    };
    final PubLock parsed = PubLock.parse(otherLock);
    final String bzl = generatePubLock(
      PubLock.parse(lock),
      resolve(),
      generator: 'gen_pub_lock.dart',
      otherLocks: <String, ResolvedLock>{
        'engine/src/flutter/lib/web_ui': (
          lock: parsed,
          workspace: PubWorkspace.resolve(
            lock: parsed,
            packageConfigJson: otherConfig,
            packageConfigUri: Uri.parse(
              'file:///home/me/repo/engine/src/flutter/lib/web_ui/.dart_tool/package_config.json',
            ),
            repositoryRoot: Uri.parse('file:///home/me/repo/'),
            readPubspec: (Uri pubspec) => otherPubspecs[pubspec.toFilePath()],
          ),
        ),
      },
    );
    expect(
      bzl,
      endsWith('''
PUB_LOCKS = {
    "engine/src/flutter/lib/web_ui": struct(
        hosted = {
            "async": struct(
                version = "2.11.0",
                sha256 = "0000000000000000000000000000000000000000000000000000000000000000",
                url = "https://pub.dev/api/archives/async-2.11.0.tar.gz",
                deps = [
                    "meta",
                ],
            ),
        },
        packages = {
            "ui": struct(
                path = "engine/src/flutter/lib/web_ui",
                deps = [],
                dev_deps = [
                    "async",
                    "web_engine_tester",
                ],
            ),
            "web_engine_tester": struct(
                path = "engine/src/flutter/web_sdk/web_engine_tester",
                deps = [
                    "ui",
                ],
                dev_deps = [],
            ),
        },
        others = {
        },
    ),
}
'''),
    );
  });

  test('rejects a package without a pin', () {
    expect(
      () => PubLock.parse('''
packages:
  broken:
    description:
      name: broken
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
'''),
      throwsFormatException,
    );
  });
}
