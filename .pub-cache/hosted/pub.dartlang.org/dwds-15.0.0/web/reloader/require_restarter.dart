// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library require_reloading_manager;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:js_util';

import 'package:graphs/graphs.dart' as graphs;
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import '../promise.dart';
import '../run_main.dart';
import 'restarter.dart';

/// The last known digests of all the modules in the application.
///
/// This is updated in place during calls to hotRestart.
/// TODO(annagrin): can this be a private field in RequireRestarter?
late Map<String, String> _lastKnownDigests;

@JS(r'$requireLoader')
external RequireLoader get requireLoader;

@JS(r'$loadModuleConfig')
external Object Function(String module) get require;

@JS(r'$dartRunMain')
external set dartRunMain(Function() func);

@JS(r'$dartRunMain')
external Function() get dartRunMain;

List<K> keys<K, V>(JsMap<K, V> map) {
  return List.from(_jsArrayFrom(map.keys()));
}

@JS('Array.from')
external List _jsArrayFrom(Object any);

@JS('Object.values')
external List _jsObjectValues(Object any);

@anonymous
@JS()
class RequireLoader {
  @JS()
  external String get digestsPath;

  @JS()
  external JsMap<String, List<String>> get moduleParentsGraph;

  @JS()
  external void forceLoadModule(String moduleId, void Function() callback,
      void Function(JsError e) onError);
}

class HotReloadFailedException implements Exception {
  final String _s;

  HotReloadFailedException(this._s);
  @override
  String toString() => "HotReloadFailedException: '$_s'";
}

@JS('Error')
abstract class JsError {
  @JS()
  external String get message;

  @JS()
  external String get stack;
}

@JS('Map')
abstract class JsMap<K, V> {
  @JS()
  external V get(K key);

  @JS()
  external Object keys();
}

/// Handles hot restart reloading for use with the require module system.
class RequireRestarter implements Restarter {
  final _moduleOrdering = HashMap<String, int>();
  late SplayTreeSet<String> _dirtyModules;
  var _running = Completer<bool>()..complete(true);

  var count = 0;

  RequireRestarter._() {
    _dirtyModules = SplayTreeSet(_moduleTopologicalCompare);
  }

  @override
  Future<bool> restart({String? runId}) async {
    final developer = getProperty(require('dart_sdk'), 'developer');
    if (callMethod(getProperty(developer, '_extensions'), 'containsKey',
        ['ext.flutter.disassemble']) as bool) {
      await toFuture(callMethod(
              developer, 'invokeExtension', ['ext.flutter.disassemble', '{}'])
          as Promise<void>);
    }

    final newDigests = await _getDigests();
    final modulesToLoad = <String>[];
    for (var moduleId in newDigests.keys) {
      if (!_lastKnownDigests.containsKey(moduleId)) {
        print('Error during script reloading, refreshing the page. \n'
            'Unable to find an existing digest for module: $moduleId.');
        _reloadPage();
      } else if (_lastKnownDigests[moduleId] != newDigests[moduleId]) {
        _lastKnownDigests[moduleId] = newDigests[moduleId]!;
        modulesToLoad.add(moduleId);
      }
    }

    var result = true;
    if (modulesToLoad.isNotEmpty) {
      _updateGraph();
      result = await _reload(modulesToLoad);
    }
    callMethod(getProperty(require('dart_sdk'), 'dart'), 'hotRestart', []);
    runMain();
    return result;
  }

  List<String> _allModules() => keys(requireLoader.moduleParentsGraph);

  Future<Map<String, String>> _getDigests() async {
    final request = await HttpRequest.request(requireLoader.digestsPath,
        responseType: 'json', method: 'GET');
    return (request.response as Map).cast<String, String>();
  }

  Future<void> _initialize() async {
    _lastKnownDigests = await _getDigests();
  }

  List<String> _moduleParents(String module) =>
      requireLoader.moduleParentsGraph.get(module).cast();

  int _moduleTopologicalCompare(String module1, String module2) {
    var topological = 0;

    final order1 = _moduleOrdering[module1];
    final order2 = _moduleOrdering[module2];

    if (order1 == null || order2 == null) {
      final missing = order1 == null ? module1 : module2;
      throw HotReloadFailedException(
          'Unable to fetch ordering info for module: $missing');
    }

    topological = Comparable.compare(
        _moduleOrdering[module2]!, _moduleOrdering[module1]!);

    if (topological == 0) {
      // If modules are in cycle (same strongly connected component) compare
      // their string id, to ensure total ordering for SplayTreeSet uniqueness.
      topological = module1.compareTo(module2);
    }

    return topological;
  }

  /// Returns `true` if the reload was fully handled, `false` if it failed
  /// explicitly, or `null` for an unhandled reload.
  Future<bool> _reload(List<String> modules) async {
    // As function is async, it can potentially be called second time while
    // first invocation is still running. In this case just mark as dirty and
    // wait until loop from the first call will do the work
    if (!_running.isCompleted) return await _running.future;
    _running = Completer();

    var reloadedModules = 0;
    try {
      _dirtyModules.addAll(modules);
      String? previousModuleId;
      while (_dirtyModules.isNotEmpty) {
        final moduleId = _dirtyModules.first;
        _dirtyModules.remove(moduleId);
        final parentIds = _moduleParents(moduleId);
        // Check if this is the root / bootstrap module.
        if (parentIds.isEmpty) {
          // The bootstrap module is not reloaded but we need to update the
          // $dartRunMain reference to the newly loaded child module.
          final childModule = callMethod(
              getProperty(require('dart_sdk'), 'dart'),
              'getModuleLibraries',
              [previousModuleId]);
          dartRunMain = allowInterop(() {
            callMethod(_jsObjectValues(childModule).first, 'main', []);
          });
        } else {
          ++reloadedModules;
          await _reloadModule(moduleId);
          parentIds.sort(_moduleTopologicalCompare);
          _dirtyModules.addAll(parentIds);
          previousModuleId = moduleId;
        }
      }
      print('$reloadedModules module(s) were hot-reloaded.');
      _running.complete(true);
    } on HotReloadFailedException catch (e) {
      print('Error during script reloading. Firing full page reload. $e');
      _reloadPage();
      _running.complete(false);
    }
    return _running.future;
  }

  Future<void> _reloadModule(String moduleId) {
    final completer = Completer();
    final stackTrace = StackTrace.current;
    requireLoader.forceLoadModule(moduleId, allowInterop(() {
      completer.complete();
    }),
        allowInterop((e) => completer.completeError(
            HotReloadFailedException(e.message), stackTrace)));
    return completer.future;
  }

  void _reloadPage() {
    window.location.reload();
  }

  void _updateGraph() {
    final allModules = _allModules();
    final stronglyConnectedComponents =
        graphs.stronglyConnectedComponents(allModules, _moduleParents);
    _moduleOrdering.clear();
    for (var i = 0; i < stronglyConnectedComponents.length; i++) {
      for (var module in stronglyConnectedComponents[i]) {
        _moduleOrdering[module] = i;
      }
    }
  }

  static Future<RequireRestarter> create() async {
    final reloader = RequireRestarter._();
    await reloader._initialize();
    return reloader;
  }
}
