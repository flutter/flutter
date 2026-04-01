// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:watcher/watcher.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../dart/analysis.dart';
import '../project.dart';
import 'analytics.dart';
import 'dependency_graph.dart';
import 'dtd_services.dart';
import 'dtd_types.dart';
import 'utils.dart';

typedef WatcherBuilder = Watcher Function(String path);

Watcher _defaultWatcherBuilder(String path) {
  return Watcher(path);
}

class LspPreviewDetector {
  LspPreviewDetector({
    required this.platform,
    required this.previewAnalytics,
    required this.project,
    required this.fs,
    required this.logger,
    required this.onChangeDetected,
    required this.onPubspecChangeDetected,
    required this.dtd,
    required this.processManager,
    required this.terminal,
    required this.suppressAnalytics,
    this.analysisServerFactory,
    required this.artifacts,
    @visibleForTesting this.watcherBuilder = _defaultWatcherBuilder,
    @visibleForTesting this.onPackageConfigChangeDetected,
  }) : projectRoot = project.directory;

  final Artifacts artifacts;
  final Platform platform;
  final WidgetPreviewAnalytics previewAnalytics;
  final FlutterProject project;
  final Directory projectRoot;
  final FileSystem fs;
  final Logger logger;
  final void Function(FlutterWidgetPreviews) onChangeDetected;
  final void Function(String path) onPubspecChangeDetected;
  @visibleForTesting
  final void Function(String path)? onPackageConfigChangeDetected;
  final WatcherBuilder watcherBuilder;
  final WidgetPreviewDtdServices dtd;
  final ProcessManager processManager;
  final Terminal terminal;
  final bool suppressAnalytics;
  final Future<AnalysisServer> Function()? analysisServerFactory;

  AnalysisServer? get analysisServer => _analysisServer;
  AnalysisServer? _analysisServer;

  @visibleForTesting
  static const kDirectoryWatcherClosedUnexpectedlyPrefix = 'Directory watcher closed unexpectedly';
  @visibleForTesting
  static const kWindowsFileWatcherRestartedMessage =
      'WindowsDirectoryWatcher has closed and been restarted.';
  StreamSubscription<WatchEvent>? _fileWatcher;
  @visibleForTesting
  final mutex = PreviewDetectorMutex();

  var _disposed = false;
  bool _initialized = false;

  /// Starts listening for changes to Dart sources under [projectRoot] and returns
  /// the initial [PreviewDependencyGraph] for the project.
  Future<void> initialize() async {
    return mutex.runGuarded(() async {
      if (_initialized) {
        return;
      }
      _initialized = true;
      final Watcher watcher = watcherBuilder(projectRoot.path);
      _fileWatcher = watcher.events.listen(
        (WatchEvent event) {
          _onFileSystemEvent(event);
        },
        onError: (Object e, StackTrace st) {
          if (platform.isWindows &&
              e is FileSystemException &&
              e.message.startsWith(kDirectoryWatcherClosedUnexpectedlyPrefix)) {
            // The Windows directory watcher sometimes decides to shutdown on its own. It's
            // automatically restarted by package:watcher, but we need to handle this exception.
            // See https://github.com/dart-lang/tools/issues/1713 for details.
            logger.printTrace(kWindowsFileWatcherRestartedMessage);
            return;
          }
          Error.throwWithStackTrace(e, st);
        },
      );

      // Wait for file watcher to finish initializing, otherwise we might miss changes and cause
      // tests to flake.
      await watcher.ready;

      // Ensure the project's manifest is up to date, just in case an update was made before the
      // file watcher finished initializing.
      project.reloadManifest(logger: logger, fs: fs);

      if (!dtd.lspServiceAvailable) {
        logger.printStatus('Launching analysis server...');
        _analysisServer = analysisServerFactory != null
            ? await analysisServerFactory!()
            : await launchAnalysisServer();
        await _analysisServer!.start();

        final Uri? dtdUri = dtd.dtdUri;
        if (dtdUri != null) {
          await _analysisServer!.connectToDtd(dtdUri: dtdUri);
        } else {
          logger.printTrace('Launching a fresh DTD instance...');
          await dtd.launchAndConnect(analysisServer: _analysisServer!);
        }
      }
    });
  }

  Future<AnalysisServer> launchAnalysisServer() async {
    final analysisServer = AnalysisServer(
      artifacts.getArtifactPath(Artifact.engineDartSdkPath),
      [projectRoot.path],
      fileSystem: fs,
      logger: logger,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
      suppressAnalytics: suppressAnalytics,
    );
    return analysisServer;
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    // Guard disposal behind a mutex to make sure the analyzer has finished
    // processing the latest file updates to avoid throwing an exception.
    await mutex.runGuarded(() async {
      await _fileWatcher?.cancel();
      _fileWatcher = null;
      await _analysisServer?.dispose();
      _analysisServer = null;
    });
  }

  Future<void> _onFileSystemEvent(WatchEvent event) async {
    // Only process one FileSystemEntity at a time so we don't invalidate an AnalysisSession that's
    // in use when we call context.changeFile(...).
    await mutex.runGuarded(() async {
      await _fileAddedOrUpdated(filePath: event.path);
    });
  }

  Future<void> _fileAddedOrUpdated({required String filePath}) async {
    if (filePath.isPubspec) {
      onPubspecChangeDetected(filePath);
      return;
    }
    await _analysisServer?.waitForAnalysis();
    final FlutterWidgetPreviews result = await dtd.getFlutterWidgetPreviews();
    onChangeDetected(result);
  }
}
