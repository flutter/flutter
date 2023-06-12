import 'dart:async';

import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  late _MemFs memFs;
  final memFsFactoryId = 'MemFs';
  final noOpFactoryId = 'NoOp';

  setUpAll(() {
    memFs = _MemFs();
    var memFsWatcherFactory = _MemFsWatcherFactory(memFs);
    var noOpWatcherFactory = _NoOpWatcherFactory();
    registerCustomWatcher(
        noOpFactoryId,
        noOpWatcherFactory.createDirectoryWatcher,
        noOpWatcherFactory.createFileWatcher);
    registerCustomWatcher(
        memFsFactoryId,
        memFsWatcherFactory.createDirectoryWatcher,
        memFsWatcherFactory.createFileWatcher);
  });

  test('notifies for files', () async {
    var watcher = FileWatcher('file.txt');

    var completer = Completer<WatchEvent>();
    watcher.events.listen((event) => completer.complete(event));
    await watcher.ready;
    memFs.add('file.txt');
    var event = await completer.future;

    expect(event.type, ChangeType.ADD);
    expect(event.path, 'file.txt');
  });

  test('notifies for directories', () async {
    var watcher = DirectoryWatcher('dir');

    var completer = Completer<WatchEvent>();
    watcher.events.listen((event) => completer.complete(event));
    await watcher.ready;
    memFs.add('dir');
    var event = await completer.future;

    expect(event.type, ChangeType.ADD);
    expect(event.path, 'dir');
  });

  test('registering twice throws', () async {
    expect(
        () => registerCustomWatcher(memFsFactoryId,
            (_, {pollingDelay}) => throw 0, (_, {pollingDelay}) => throw 0),
        throwsA(isA<ArgumentError>()));
  });

  test('finding two applicable factories throws', () async {
    // Note that _MemFsWatcherFactory always returns a watcher, so having two
    // will always produce a conflict.
    var watcherFactory = _MemFsWatcherFactory(memFs);
    registerCustomWatcher('Different id', watcherFactory.createDirectoryWatcher,
        watcherFactory.createFileWatcher);
    expect(() => FileWatcher('file.txt'), throwsA(isA<StateError>()));
    expect(() => DirectoryWatcher('dir'), throwsA(isA<StateError>()));
  });
}

class _MemFs {
  final _streams = <String, Set<StreamController<WatchEvent>>>{};

  StreamController<WatchEvent> watchStream(String path) {
    var controller = StreamController<WatchEvent>();
    _streams
        .putIfAbsent(path, () => <StreamController<WatchEvent>>{})
        .add(controller);
    return controller;
  }

  void add(String path) {
    var controllers = _streams[path];
    if (controllers != null) {
      for (var controller in controllers) {
        controller.add(WatchEvent(ChangeType.ADD, path));
      }
    }
  }

  void remove(String path) {
    var controllers = _streams[path];
    if (controllers != null) {
      for (var controller in controllers) {
        controller.add(WatchEvent(ChangeType.REMOVE, path));
      }
    }
  }
}

class _MemFsWatcher implements FileWatcher, DirectoryWatcher, Watcher {
  final String _path;
  final StreamController<WatchEvent> _controller;

  _MemFsWatcher(this._path, this._controller);

  @override
  String get path => _path;

  @override
  String get directory => throw UnsupportedError('directory is not supported');

  @override
  Stream<WatchEvent> get events => _controller.stream;

  @override
  bool get isReady => true;

  @override
  Future<void> get ready async {}
}

class _MemFsWatcherFactory {
  final _MemFs _memFs;
  _MemFsWatcherFactory(this._memFs);

  DirectoryWatcher? createDirectoryWatcher(String path,
          {Duration? pollingDelay}) =>
      _MemFsWatcher(path, _memFs.watchStream(path));

  FileWatcher? createFileWatcher(String path, {Duration? pollingDelay}) =>
      _MemFsWatcher(path, _memFs.watchStream(path));
}

class _NoOpWatcherFactory {
  DirectoryWatcher? createDirectoryWatcher(String path,
          {Duration? pollingDelay}) =>
      null;

  FileWatcher? createFileWatcher(String path, {Duration? pollingDelay}) => null;
}
