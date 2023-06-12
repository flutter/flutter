// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:watcher/watcher.dart';

Future<void> _isolateMain(SendPort sendPort) async {
  var fromMainIsolate = ReceivePort();
  var bazelIsolate = BazelFileWatcherIsolate(
      fromMainIsolate, sendPort, PhysicalResourceProvider.INSTANCE)
    ..start();
  await bazelIsolate.hasFinished;
}

/// Exposes the ability to poll for changes in generated files.
///
/// The only logic here is that we may have multiple "candidate" paths where the
/// file might be located, but after the first time we actually find the file,
/// we can only focus on that particular path, since the files should be
/// consistently in the same place after rebuilds.
class BazelFilePoller {
  /// The possible "candidate" paths that we watch.
  final List<String> _candidates;

  /// The time of last modification of the file under [_validPath].
  _ModifiedInfo? _lastModified;

  /// The resource provider used for polling the files.
  final ResourceProvider _provider;

  /// One of the [_candidates] that is valid, i.e. we found a file with that
  /// path.
  String? _validPath;

  BazelFilePoller(this._provider, this._candidates);

  /// Checks if the file corresponding to the watched path has changed and
  /// returns the event or `null` if nothing changed.
  WatchEvent? poll() {
    _ModifiedInfo? modified;
    if (_validPath == null) {
      var info = _pollAll();
      if (info != null) {
        _validPath = info.path;
        modified = info.modified;
      }
    } else {
      modified = _pollOne(_validPath!);
    }

    // If there is no file, then we have nothing to do.
    if (_validPath == null) return null;

    WatchEvent? result;
    if (modified == null && _lastModified != null) {
      // The file is no longer there, so let's issue a REMOVE event, unset
      // `_validPath` and set the timer to poll more frequently.
      result = WatchEvent(ChangeType.REMOVE, _validPath!);
      _validPath = null;
    } else if (modified != null && _lastModified == null) {
      result = WatchEvent(ChangeType.ADD, _validPath!);
    } else if (_lastModified != null && modified != _lastModified) {
      result = WatchEvent(ChangeType.MODIFY, _validPath!);
    }

    _lastModified = modified;
    return result;
  }

  /// Starts watching the files.
  ///
  /// This should be called when creating an instance of this class to correctly
  /// categorize events (e.g. whether a file already existed or was added).
  void start() {
    assert(_validPath == null);
    assert(_lastModified == null);
    var info = _pollAll();
    if (info != null) {
      _validPath = info.path;
      _lastModified = info.modified;
    }
  }

  /// Tries polling all the possible paths.
  ///
  /// Will set [_validPath] and return its modified time if a file is found.
  /// Returns [null] if nothing is found.
  FileInfo? _pollAll() {
    assert(_validPath == null);
    for (var path in _candidates) {
      var modified = _pollOne(path);
      if (modified != null) {
        return FileInfo(path, modified);
      }
    }
    return null;
  }

  /// Returns the modified time of the path or `null` if the file does not
  /// exist.
  _ModifiedInfo? _pollOne(String path) {
    try {
      // This might seem a bit convoluted but is necessary to deal with a
      // symlink to a directory (e.g., `bazel-bin`).

      var pathResource = _provider.getResource(path);
      var symlinkTarget = pathResource.resolveSymbolicLinksSync().path;
      var resolvedResource = _provider.getResource(symlinkTarget);
      if (resolvedResource is File) {
        var timestamp = resolvedResource.modificationStamp;
        var length = resolvedResource.lengthSync;
        return _ModifiedInfo(timestamp, length, symlinkTarget);
      } else if (resolvedResource is Folder) {
        // `ResourceProvider` doesn't currently support getting timestamps of a
        // folder, so we use a dummy value here. But this shouldn't really
        // matter, since the `symlinkTarget` should detect any modifications.
        return _ModifiedInfo(0, 0, symlinkTarget);
      } else {
        return null;
      }
    } on FileSystemException catch (_) {
      // File doesn't exist, so return null.
      return null;
    }
  }
}

/// The watcher implementation that runs in a separate isolate.
///
/// It'll try to detect when Bazel finished running (through [PollTrigger] which
/// usually will be [_BazelInvocationWatcher]) and then poll all the files to
/// find any changes, which will be sent to the main isolate as
/// [BazelWatcherEvents].
class BazelFileWatcherIsolate {
  final ReceivePort _fromMainIsolate;
  final SendPort _toMainIsolate;
  late final StreamSubscription _fromMainIsolateSubscription;

  /// For each workspace tracks all the data associated with it.
  final _perWorkspaceData = <String, _PerWorkspaceData>{};

  /// A factory for [PollTrigger].
  ///
  /// Used mostly for testing to allow using a different trigger.
  late final PollTrigger Function(String) _pollTriggerFactory;

  /// Resource provider used for polling.
  ///
  /// NB: The default [PollTrigger] (i.e., [_BazelInvocationWatcher]) uses
  /// `dart:io` directly. So for testing both [_provider] and
  /// [_pollTriggerFactory] should be provided.
  final ResourceProvider _provider;

  final _hasFinished = Completer<void>();

  BazelFileWatcherIsolate(
      this._fromMainIsolate, this._toMainIsolate, this._provider,
      {PollTrigger Function(String)? pollTriggerFactory}) {
    _pollTriggerFactory = pollTriggerFactory ?? _defaultPollTrigger;
  }

  Future<void> get hasFinished => _hasFinished.future;

  void handleRequest(dynamic request) async {
    if (request is BazelWatcherStartWatching) {
      var workspaceData = _perWorkspaceData[request.workspace];
      if (workspaceData == null) {
        var trigger = _pollTriggerFactory(request.workspace);
        var subscription =
            trigger.stream.listen((_) => _pollAllWatchers(request.workspace));
        workspaceData = _PerWorkspaceData(trigger, subscription);
        _perWorkspaceData[request.workspace] = workspaceData;
      }
      var requestedPath = request.info.requestedPath;
      var count = workspaceData.watched.add(requestedPath);
      if (count > 1) {
        assert(workspaceData.pollers.containsKey(requestedPath));
        return;
      }
      workspaceData.pollers[requestedPath] =
          BazelFilePoller(_provider, request.info.candidatePaths)..start();
    } else if (request is BazelWatcherStopWatching) {
      var workspaceData = _perWorkspaceData[request.workspace];
      if (workspaceData == null) return;
      var count = workspaceData.watched.remove(request.requestedPath);
      if (count == 0) {
        workspaceData.pollers.remove(request.requestedPath);
        if (workspaceData.watched.isEmpty) {
          workspaceData.trigger.cancel();
          unawaited(workspaceData.pollSubscription.cancel());
          _perWorkspaceData.remove(request.workspace);
        }
      }
    } else if (request is BazelWatcherShutdownIsolate) {
      unawaited(_fromMainIsolateSubscription.cancel());
      _fromMainIsolate.close();
      for (var data in _perWorkspaceData.values) {
        data.trigger.cancel();
        unawaited(data.pollSubscription.cancel());
      }
      _hasFinished.complete();
      _perWorkspaceData.clear();
    } else {
      // We don't have access to the `InstrumentationService` so we send the
      // message to the main isolate to log it.
      _toMainIsolate.send(BazelWatcherError(
          'BazelFileWatcherIsolate got unexpected request: $request'));
    }
  }

  /// Returns the total number of requested file paths that are being watched.
  ///
  /// This is for testing *only*.
  int numWatchedFiles() {
    var total = 0;
    for (var data in _perWorkspaceData.values) {
      total += data.watched.length;
    }
    return total;
  }

  /// Starts listening for messages from the main isolate and sends it
  /// [BazelWatcherIsolateStarted].
  void start() {
    _fromMainIsolateSubscription = _fromMainIsolate.listen(handleRequest);
    _toMainIsolate.send(BazelWatcherIsolateStarted(_fromMainIsolate.sendPort));
  }

  PollTrigger _defaultPollTrigger(String workspacePath) =>
      _BazelInvocationWatcher(_provider, workspacePath);

  void _pollAllWatchers(String workspace) {
    try {
      var events = <WatchEvent>[];
      for (var watcher in _perWorkspaceData[workspace]!.pollers.values) {
        var event = watcher.poll();
        if (event != null) events.add(event);
      }
      if (events.isNotEmpty) {
        _toMainIsolate.send(BazelWatcherEvents(events));
      }
    } on Exception catch (_) {
      // This shouldn't really happen, but we shouldn't crash when polling
      // either, so just ignore the error and rely on the next try.
      return;
    }
  }
}

/// A watcher service that exposes batch-oriented notification interface for
/// changes to watched files.
///
/// The actual `stat`ing of file takes place in a separate isolate to avoid
/// blocking the main one. Since much of the analysis server is synchronous, we
/// can't use async functions and resort to launching the isolate and buffering
/// the requests until the isolate has started.
///
/// The isolate is started lazily on the first request to watch a path, so
/// instantiating [BazelFileWatcherService] is very cheap.
///
/// The protocol when communicating with the isolate:
/// 1. The watcher isolate sends to the main one a [BazelWatcherIsolateStarted]
///    and expects a [BazelWatcherInitializeIsolate] to be sent from the main
///    isolate as a reply.
/// 2. The main isolate can request to start watching a file by sending
///    [BazelWatcherStartWatching] request. There is no response expected.
/// 3. The watcher isolate will send a [BazelWatcherEvents] notification when
///    changes are detected. Again, no response from the main isolate is
///    expected.
/// 4. The main isolate will send a [BazelWatcherShutdownIsolate] when the
///    isolate is supposed to shut down. No more messages should be exchanged
///    afterwards.
class BazelFileWatcherService {
  final InstrumentationService _instrumetation;

  final _events = StreamController<List<WatchEvent>>.broadcast();

  /// Buffers files to watch until the isolate is ready.
  final _buffer = <BazelWatcherMessage>[];

  late final ReceivePort _fromIsolatePort;
  late final SendPort _toIsolatePort;
  late final StreamSubscription _fromIsolateSubscription;

  /// True if we have launched the isolate.
  bool _isolateIsStarting = false;

  /// True if the isolate is ready to watch files.
  final _isolateHasStarted = Completer<void>();

  BazelFileWatcherService(this._instrumetation);

  Stream<List<WatchEvent>> get events => _events.stream;

  /// Shuts everything down including the watcher isolate.
  /// FIXME(michalt): Remove this if we really never need to shut down the
  /// isolate.
  void shutdown() {
    if (_isolateHasStarted.isCompleted) {
      _toIsolatePort.send(BazelWatcherShutdownIsolate());
    }
    if (_isolateIsStarting) {
      _fromIsolateSubscription.cancel();
      _fromIsolatePort.close();
    }
    _events.close();
  }

  void startWatching(String workspace, BazelSearchInfo info) {
    assert(!_events.isClosed);
    _startIsolateIfNeeded();
    var request = BazelWatcherStartWatching(workspace, info);
    if (!_isolateHasStarted.isCompleted) {
      _buffer.add(request);
    } else {
      _toIsolatePort.send(request);
    }
  }

  void stopWatching(String workspace, String requestedPath) {
    assert(!_events.isClosed);
    var request = BazelWatcherStopWatching(workspace, requestedPath);
    if (!_isolateHasStarted.isCompleted) {
      _buffer.add(request);
    } else {
      _toIsolatePort.send(request);
    }
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is BazelWatcherIsolateStarted) {
      _toIsolatePort = message.sendPort;
      _isolateHasStarted.complete();
    } else if (message is BazelWatcherEvents) {
      _events.add(message.events);
    } else if (message is BazelWatcherError) {
      _instrumetation.logError(message.message);
    } else {
      _instrumetation.logError(
          'Received unexpected message from BazelFileWatcherIsolate: $message');
    }
  }

  /// Starts the isolate if it has not yet been started.
  void _startIsolateIfNeeded() {
    if (_isolateIsStarting) return;
    _isolateIsStarting = true;
    _startIsolateImpl();
    _isolateHasStarted.future.then((_) {
      _buffer.forEach(_toIsolatePort.send);
      _buffer.clear();
    });
  }

  Future<void> _startIsolateImpl() async {
    _fromIsolatePort = ReceivePort();
    _fromIsolateSubscription = _fromIsolatePort.listen(_handleIsolateMessage);
    await Isolate.spawn(_isolateMain, _fromIsolatePort.sendPort);
  }
}

/// Notification that we issue when searching for generated files in a Bazel
/// workspace.
///
/// This allows clients to watch for changes to the generated files.
class BazelSearchInfo {
  /// Candidate paths that we searched.
  final List<String> candidatePaths;

  /// Absolute path that we tried searching for.
  ///
  /// This is not necessarily the path of the actual file that will be used. See
  /// `BazelWorkspace.findFile` for details.
  final String requestedPath;

  BazelSearchInfo(this.requestedPath, this.candidatePaths);
}

class BazelWatcherError implements BazelWatcherMessage {
  final String message;
  BazelWatcherError(this.message);
}

class BazelWatcherEvents implements BazelWatcherMessage {
  final List<WatchEvent> events;
  BazelWatcherEvents(this.events);
}

/// Sent by the watcher isolate to transfer the [SendPort] to the main isolate.
class BazelWatcherIsolateStarted implements BazelWatcherMessage {
  final SendPort sendPort;
  BazelWatcherIsolateStarted(this.sendPort);
}

abstract class BazelWatcherMessage {}

class BazelWatcherShutdownIsolate implements BazelWatcherMessage {}

class BazelWatcherStartWatching implements BazelWatcherMessage {
  final String workspace;
  final BazelSearchInfo info;
  BazelWatcherStartWatching(this.workspace, this.info);
}

class BazelWatcherStopWatching implements BazelWatcherMessage {
  final String workspace;
  final String requestedPath;
  BazelWatcherStopWatching(this.workspace, this.requestedPath);
}

class FileInfo {
  String path;
  _ModifiedInfo modified;
  FileInfo(this.path, this.modified);
}

/// Triggers polling every time something appears in the [stream].
abstract class PollTrigger {
  Stream<Object> get stream;
  void cancel();
}

/// Watches for finished Bazel invocations.
///
/// The idea here is to detect when Bazel finished running and use that to
/// trigger polling. To detect that we use the `command.log` file that bazel
/// contiuously updates as the build progresses. We find that file based on [1]:
///
/// - In the workspace directory there should be a `bazel-out` symlink whose
///   target should be of the form:
///   `[...]/<hash of workspace>/execroot/<workspace name>/bazel-out`
/// - The file should be in `[...]/<hash of workspace>/command.log`.
///
/// In other words, we need to get the target of the symlink and then trim three
/// last parts of the path.
///
/// [1] https://docs.bazel.build/versions/master/output_directories.html
///
/// NB: We're not using a [ResourceProvider] because it doesn't support finding a
/// target of a symlink.
class _BazelInvocationWatcher implements PollTrigger {
  /// Determines how often do we check for `command.log` changes.
  ///
  /// Note that on some systems the granularity is about 1s, so let's set this
  /// to some greater value just to be safe we don't miss any updates.
  static const _pollInterval = Duration(seconds: 2);

  /// To confirm that a build finished, we check for these messages in the
  /// `command.log`.
  static const _buildCompletedMsgs = [
    'Build completed successfully',
    'Build completed',
    'Build did NOT complete successfully',
  ];

  final _controller = StreamController<WatchEvent>.broadcast();
  final ResourceProvider _provider;
  final String _workspacePath;
  late final Timer _timer;
  BazelFilePoller? _poller;
  String? _commandLogPath;

  _BazelInvocationWatcher(this._provider, this._workspacePath) {
    _timer = Timer.periodic(_pollInterval, _poll);
  }

  @override
  Stream<WatchEvent> get stream => _controller.stream;

  @override
  void cancel() => _timer.cancel();

  bool _buildFinished(String contents) {
    // Only look at the last 1024 characters.
    var offset = max(0, contents.length - 1024);
    return _buildCompletedMsgs.any((msg) => contents.contains(msg, offset));
  }

  Future<String?> _getCommandLogPath() async {
    String? resolvedLink;
    var bazelOut = _inWorkspace('bazel-out');
    var blazeOut = _inWorkspace('blaze-out');
    if (await io.Link(bazelOut).exists()) {
      resolvedLink = await io.Link(bazelOut).target();
    } else if (await io.Link(blazeOut).exists()) {
      resolvedLink = await io.Link(blazeOut).target();
    }
    if (resolvedLink == null) return null;
    var pathContext = _provider.pathContext;
    return pathContext.join(
        pathContext
            .dirname(pathContext.dirname(pathContext.dirname(resolvedLink))),
        'command.log');
  }

  String _inWorkspace(String p) =>
      _provider.pathContext.join(_workspacePath, p);

  Future<void> _poll(Timer _) async {
    try {
      _commandLogPath ??= await _getCommandLogPath();
      if (_commandLogPath == null) return;

      _poller ??= BazelFilePoller(_provider, [_commandLogPath!]);
      var event = _poller!.poll();
      if (event == null) return;

      var file = io.File(_commandLogPath!);
      var contents = file.readAsStringSync();
      if (_buildFinished(contents)) {
        _controller.add(WatchEvent(ChangeType.MODIFY, _commandLogPath!));
      }
    } on Exception catch (_) {
      // Ignore failures, it's possible that the file was deleted between when
      // we checked and tried to read it, etc.
      return;
    }
  }
}

/// Data used to determines if a file has changed.
///
/// This turns out to be important for tracking files that change a lot, like
/// the `command.log` that we use to detect the finished build.  Bazel writes to
/// the file continuously and because the resolution of a timestamp is pretty
/// low, it's quite possible to receive the same timestamp even though the file
/// has changed.  We use its length to remedy that.  It's not perfect (for that
/// we'd have to compute the hash), but it should be reasonable trade-off (to
/// avoid any performance impact from reading and hashing the file).
class _ModifiedInfo {
  final int timestamp;
  final int length;

  /// Stores the resolved path in case a symlink or just the path for ordinary
  /// files.
  final String symlinkTarget;

  _ModifiedInfo(this.timestamp, this.length, this.symlinkTarget);

  @override
  int get hashCode =>
      // We don't really need to compute hashes, just check the equality. But
      // throw in case someone expects this to work.
      throw UnimplementedError(
          '_ModifiedInfo.hashCode has not been implemented yet');

  @override
  bool operator ==(Object other) {
    if (other is! _ModifiedInfo) return false;
    return timestamp == other.timestamp &&
        length == other.length &&
        symlinkTarget == other.symlinkTarget;
  }

  // For debugging only.
  @override
  String toString() => '_ModifiedInfo('
      'timestamp=$timestamp, length=$length, symlinkTarget=$symlinkTarget)';
}

class _Multiset<T> {
  final _counts = <T, int>{};

  bool get isEmpty => _counts.isEmpty;

  int get length =>
      _counts.values.fold(0, (accumulator, count) => accumulator + count);

  /// Returns the number of [elem] objects after the addition.
  int add(T elem) =>
      _counts.update(elem, (count) => count + 1, ifAbsent: () => 1);

  /// Returns the number of [elem] objects after the removal.
  int remove(T elem) {
    var newCount = _counts.update(elem, (count) => count - 1);
    if (newCount == 0) {
      _counts.remove(elem);
    }
    return newCount;
  }
}

class _PerWorkspaceData {
  /// For each requested file stores the corresponding [BazelFilePoller].
  final pollers = <String, BazelFilePoller>{};

  /// Keeps count of the number of requests to watch a file, so that we can stop
  /// watching when we reach 0 clients.
  final watched = _Multiset();

  /// The [PollTrigger] that detects when we should poll files.
  final PollTrigger trigger;

  /// Subscription of [trigger].
  final StreamSubscription<Object> pollSubscription;

  _PerWorkspaceData(this.trigger, this.pollSubscription);
}
