// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../compile.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../web/compile.dart';

// TODO(jonahwilliams): this class was kept around to reduce the diff in the migration
// from build_runner to the frontend_server, but should be removed/refactored to be
// similar to the test_compiler pattern used for regular flutter tests
class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  @override
  Future<WebVirtualFS> initialize({
    @required Directory projectDirectory,
    @required String testOutputDir,
    @required List<String> testFiles,
    @required BuildInfo buildInfo,
  }) async {
    if (buildInfo.nullSafetyMode == NullSafetyMode.sound) {
      throwToolExit('flutter test --platform=chrome does not currently support sound mode');
    }
    final List<String> extraFrontEndOptions = List<String>.of(buildInfo.extraFrontEndOptions ?? <String>[]);
    if (!extraFrontEndOptions.contains('--no-sound-null-safety')) {
      extraFrontEndOptions.add('--no-sound-null-safety');
    }
    final Directory outputDirectory = globals.fs.directory(testOutputDir)
      ..createSync(recursive: true);
    final List<File> generatedFiles = <File>[];
    for (final String testFilePath in testFiles) {
      final List<String> relativeTestSegments = globals.fs.path.split(
        globals.fs.path.relative(testFilePath, from: projectDirectory.childDirectory('test').path));
      final File generatedFile = globals.fs.file(
        globals.fs.path.join(outputDirectory.path, '${relativeTestSegments.join('_')}.test.dart'));
      generatedFile
        ..createSync(recursive: true)
        ..writeAsStringSync(_generateEntrypoint(relativeTestSegments.join('/'), testFilePath));
      generatedFiles.add(generatedFile);
    }
    // Generate a fake main file that imports all tests to be executed. This will force
    // each of them to be compiled.
    final StringBuffer buffer = StringBuffer('// @dart=2.8\n');
    for (final File generatedFile in generatedFiles) {
      buffer.writeln('import "${globals.fs.path.basename(generatedFile.path)}";');
    }
    buffer.writeln('void main() {}');
    globals.fs.file(globals.fs.path.join(outputDirectory.path, 'main.dart'))
      ..createSync()
      ..writeAsStringSync(buffer.toString());

    final ResidentCompiler residentCompiler = ResidentCompiler(
      globals.artifacts.getArtifactPath(Artifact.flutterWebSdk, mode: buildInfo.mode),
      buildMode: buildInfo.mode,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      fileSystemRoots: <String>[
        projectDirectory.childDirectory('test').path,
        testOutputDir,
      ],
      // Override the filesystem scheme so that the frontend_server can find
      // the generated entrypoint code.
      fileSystemScheme: 'org-dartlang-app',
      initializeFromDill: getDefaultCachedKernelPath(
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        dartDefines: buildInfo.dartDefines,
        extraFrontEndOptions: extraFrontEndOptions,
      ),
      targetModel: TargetModel.dartdevc,
      extraFrontEndOptions: extraFrontEndOptions,
      platformDill: globals.fs.file(globals.artifacts
        .getArtifactPath(Artifact.webPlatformKernelDill, mode: buildInfo.mode))
        .absolute.uri.toString(),
      dartDefines: buildInfo.dartDefines,
      librariesSpec: globals.fs.file(globals.artifacts
        .getArtifactPath(Artifact.flutterWebLibrariesJson)).uri.toString(),
      packagesPath: buildInfo.packagesPath,
      artifacts: globals.artifacts,
      processManager: globals.processManager,
      logger: globals.logger,
      platform: globals.platform,
    );

    final CompilerOutput output = await residentCompiler.recompile(
      Uri.parse('org-dartlang-app:///main.dart'),
      <Uri>[],
      outputPath: outputDirectory.childFile('out').path,
      packageConfig: buildInfo.packageConfig,
    );
    if (output.errorCount > 0) {
      throwToolExit('Failed to compile');
    }
    final File codeFile = outputDirectory.childFile('${output.outputFilename}.sources');
    final File manifestFile = outputDirectory.childFile('${output.outputFilename}.json');
    final File sourcemapFile = outputDirectory.childFile('${output.outputFilename}.map');
    final File metadataFile = outputDirectory.childFile('${output.outputFilename}.metadata');
    final WebVirtualFS webVirtualFS = WebVirtualFS();
    _write(
      codeFile,
      manifestFile,
      sourcemapFile,
      metadataFile,
      webVirtualFS,
    );
    return webVirtualFS;
  }

  void _write(
    File codeFile,
    File manifestFile,
    File sourcemapFile,
    File metadataFile,
    WebVirtualFS webVirtualFS,
  ) {
    final Uint8List codeBytes = codeFile.readAsBytesSync();
    final Uint8List sourcemapBytes = sourcemapFile.readAsBytesSync();
    final Uint8List metadataBytes = metadataFile.readAsBytesSync();
    final Map<String, dynamic> manifest =
        castStringKeyedMap(json.decode(manifestFile.readAsStringSync()));
    for (final String filePath in manifest.keys) {
      if (filePath == null) {
        globals.printTrace('Invalid manifest file: $filePath');
        continue;
      }
      final Map<String, dynamic> offsets =
          castStringKeyedMap(manifest[filePath]);
      final List<int> codeOffsets =
          (offsets['code'] as List<dynamic>).cast<int>();
      final List<int> sourcemapOffsets =
          (offsets['sourcemap'] as List<dynamic>).cast<int>();
      final List<int> metadataOffsets =
          (offsets['metadata'] as List<dynamic>).cast<int>();
      if (codeOffsets.length != 2 ||
          sourcemapOffsets.length != 2 ||
          metadataOffsets.length != 2) {
        globals.printTrace('Invalid manifest byte offsets: $offsets');
        continue;
      }

      final int codeStart = codeOffsets[0];
      final int codeEnd = codeOffsets[1];
      if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
        globals.printTrace('Invalid byte index: [$codeStart, $codeEnd]');
        continue;
      }
      final Uint8List byteView = Uint8List.view(
        codeBytes.buffer,
        codeStart,
        codeEnd - codeStart,
      );
      final String fileName =
          filePath.startsWith('/') ? filePath.substring(1) : filePath;
      webVirtualFS.files[fileName] = byteView;

      final int sourcemapStart = sourcemapOffsets[0];
      final int sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        globals.printTrace('Invalid byte index: [$sourcemapStart, $sourcemapEnd]');
        continue;
      }
      final Uint8List sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      final String sourcemapName = '$fileName.map';
      webVirtualFS.sourcemaps[sourcemapName] = sourcemapView;

      final int metadataStart = metadataOffsets[0];
      final int metadataEnd = metadataOffsets[1];
      if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
        globals
            .printTrace('Invalid byte index: [$metadataStart, $metadataEnd]');
        continue;
      }
      final Uint8List metadataView = Uint8List.view(
        metadataBytes.buffer,
        metadataStart,
        metadataEnd - metadataStart,
      );
      final String metadataName = '$fileName.metadata';
      webVirtualFS.metadataFiles[metadataName] = metadataView;
    }
  }

  String _generateEntrypoint(String relativeTestPath, String absolutePath) {
    return '''
  // @dart = 2.8
  import 'org-dartlang-app:///$relativeTestPath' as test;
  import 'dart:ui' as ui;
  import 'dart:html';
  import 'dart:js';
  import 'package:stream_channel/stream_channel.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:test_api/src/backend/stack_trace_formatter.dart'; // ignore: implementation_imports
  import 'package:test_api/src/remote_listener.dart'; // ignore: implementation_imports
  import 'package:test_api/src/suite_channel_manager.dart'; // ignore: implementation_imports

  // Extra initialization for flutter_web.
  // The following parameters are hard-coded in Flutter's test embedder. Since
  // we don't have an embedder yet this is the lowest-most layer we can put
  // this stuff in.
  Future<void> main() async {
    ui.debugEmulateFlutterTesterEnvironment = true;
    await ui.webOnlyInitializePlatform();
    webGoldenComparator = DefaultWebGoldenComparator(Uri.parse('$absolutePath'));
    (ui.window as dynamic).debugOverrideDevicePixelRatio(3.0);
    (ui.window as dynamic).webOnlyDebugPhysicalSizeOverride = const ui.Size(2400, 1800);
    internalBootstrapBrowserTest(() => test.main);
  }

  void internalBootstrapBrowserTest(Function getMain()) {
    var channel = serializeSuite(getMain, hidePrints: false);
    postMessageChannel().pipe(channel);
  }

  StreamChannel serializeSuite(Function getMain(), {bool hidePrints = true, Future beforeLoad()}) => RemoteListener.start(getMain, hidePrints: hidePrints, beforeLoad: beforeLoad);

  StreamChannel suiteChannel(String name) {
    var manager = SuiteChannelManager.current;
    if (manager == null) {
      throw StateError('suiteChannel() may only be called within a test worker.');
    }
    return manager.connectOut(name);
  }

  StreamChannel postMessageChannel() {
    var controller = StreamChannelController(sync: true);
    window.onMessage.firstWhere((message) {
      return message.origin == window.location.origin && message.data == "port";
    }).then((message) {
      var port = message.ports.first;
      var portSubscription = port.onMessage.listen((message) {
        controller.local.sink.add(message.data);
      });
      controller.local.stream.listen((data) {
        port.postMessage({"data": data});
      }, onDone: () {
        port.postMessage({"event": "done"});
        portSubscription.cancel();
      });
    });
    context['parent'].callMethod('postMessage', [
      JsObject.jsify({"href": window.location.href, "ready": true}),
      window.location.origin,
    ]);
    return controller.foreign;
  }
  ''';
  }
}
