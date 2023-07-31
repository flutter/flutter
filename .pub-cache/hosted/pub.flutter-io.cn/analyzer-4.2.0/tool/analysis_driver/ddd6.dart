import 'dart:async';

import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

Future<void> main(List<String> arguments) async {
  const path =
      r'/Users/scheglov/tmp/666'; // path to directory to watch (dart package in my case)
  final watcher = DirectoryWatcher(path);
  DartAnalyzer(watcher).units.listen((resolved) {});
}

class DartAnalyzer {
  final DriverBasedAnalysisContext _context;

  late final StreamSubscription<Object> _driverListener;

  late final StreamSubscription<WatchEvent> _fileListener;
  final StreamController<ResolvedUnitResult> _controller;
  DartAnalyzer(Watcher watcher)
      : _context = getContext(watcher),
        _controller = StreamController.broadcast() {
    _fileListener = watcher.events.listen(_updateDriver);
    _driverListener = _context.driver.results.listen(_updateDomain);
  }
  Stream<ResolvedUnitResult> get units =>
      _controller.stream.asBroadcastStream();

  Future<void> cancel() async {
    await _fileListener.cancel();
    await _driverListener.cancel();
  }

  String _sanitizePath(String path) =>
      p.relative(path, from: p.joinAll(p.split(path).sublist(0, 4)));

  Future<void> _updateDomain(Object result) async {
    late final ResolvedUnitResult resolved;

    if (result is ErrorsResult) {
      resolved = await result.session.getResolvedUnit(result.path)
          as ResolvedUnitResult;
    } else if (result is ResolvedUnitResult) {
      resolved = result;
    } else {
      throw UnsupportedError(
          'Driver returned unsupported return type: ${result.runtimeType}');
    }

    print('resolved: ${_sanitizePath(resolved.path)}');
    _controller.add(resolved);
  }

  Future<void> _updateDriver(WatchEvent evt) async {
    final type = evt.type;
    final path = evt.path;
    print('evt($type): ${_sanitizePath(path)}');

    switch (type) {
      case ChangeType.ADD:
        _context.contextRoot.isAnalyzed(path)
            ? _context.driver.addFile(path)
            : _context.driver.changeFile(path);
        break;
      case ChangeType.MODIFY:
        _context.driver.changeFile(path);
        break;
      case ChangeType.REMOVE:
        _context.driver.removeFile(path);
        break;
    }
  }

  static DriverBasedAnalysisContext getContext(Watcher watcher) {
    final contextLocator = ContextLocator();
    final roots = contextLocator.locateRoots(includedPaths: [watcher.path]);
    final root = roots.first;
    final contextBuilder = ContextBuilder();
    final context = contextBuilder.createContext(contextRoot: root)
        as DriverBasedAnalysisContext;
    return context;
  }
}
