// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/flutter_web_platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  for (final style in <FileSystemStyle>[FileSystemStyle.posix, FileSystemStyle.windows]) {
    final styleName = style == FileSystemStyle.windows ? 'Windows' : 'POSIX';
    testUsingContext('serves local CanvasKit assets with $styleName paths', () async {
      final FileSystem fileSystem = MemoryFileSystem.test(style: style);
      final logger = BufferLogger.test();
      final platform = FakePlatform(
        operatingSystem: style == FileSystemStyle.windows ? 'windows' : 'linux',
      );
      final processManager = FakeProcessManager.empty();
      final artifacts = Artifacts.test(fileSystem: fileSystem);
      final Directory projectDirectory = fileSystem.systemTempDirectory.createTempSync(
        'canvaskit_test.',
      );
      final server = _FakeServer();
      final chromiumLauncher = ChromiumLauncher(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        operatingSystemUtils: FakeOperatingSystemUtils(),
        browserFinder: (Platform platform, FileSystem fileSystem) => 'chrome',
        logger: logger,
      );
      final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
        projectDirectory.path,
        buildDirectory: projectDirectory.childDirectory('build'),
        buildInfo: const BuildInfo(
          BuildMode.debug,
          '',
          packageConfigPath: '.dart_tool/package_config.json',
          treeShakeIcons: false,
        ),
        chromiumLauncher: chromiumLauncher,
        crossOriginIsolation: false,
        flutterProject: FlutterProject.fromDirectoryTest(projectDirectory),
        flutterTesterBinPath: artifacts.getArtifactPath(Artifact.flutterTester),
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: logger,
          processManager: processManager,
        ),
        useWasm: false,
        webMemoryFS: WebMemoryFS(),
        webRenderer: WebRendererMode.canvaskit,
        serverFactory: () async => server,
        testPackageUri: Uri.parse('test'),
      );
      try {
        for (final relativePath in <String>[
          'canvaskit.js',
          'canvaskit.wasm',
          'chromium/canvaskit.js',
          'chromium/canvaskit.wasm',
        ]) {
          final contents = 'contents of $relativePath';
          final File asset =
              fileSystem.file(
                  fileSystem.path.joinAll(<String>[
                    artifacts.getHostArtifact(HostArtifact.flutterWebSdk).path,
                    'canvaskit',
                    ...relativePath.split('/'),
                  ]),
                )
                ..createSync(recursive: true)
                ..writeAsStringSync(contents);

          final shelf.Response response = await server.handler!(
            shelf.Request('GET', Uri.parse('http://localhost/canvaskit/$relativePath')),
          );
          expect(response.statusCode, HttpStatus.ok);
          expect(
            response.headers[HttpHeaders.contentTypeHeader],
            relativePath.endsWith('.js') ? 'text/javascript' : 'application/wasm',
          );
          expect(response.headers[HttpHeaders.contentLengthHeader], asset.lengthSync().toString());
          expect(response.headers[HttpHeaders.cacheControlHeader], 'public, max-age=3600');
          expect(await response.readAsString(), contents);
        }

        for (final path in <String>['canvaskit', 'canvaskit-other/canvaskit.js']) {
          final shelf.Response response = await server.handler!(
            shelf.Request('GET', Uri.parse('http://localhost/$path')),
          );
          expect(response.statusCode, HttpStatus.notFound);
        }
      } finally {
        await webPlatform.close();
      }
    });
  }
}

class _FakeServer implements shelf.Server {
  shelf.Handler? handler;

  @override
  Future<void> close() async {}

  @override
  void mount(shelf.Handler handler) {
    this.handler = handler;
  }

  @override
  Uri get url => Uri.parse('http://localhost');
}
