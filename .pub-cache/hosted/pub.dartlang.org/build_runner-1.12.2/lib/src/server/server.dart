// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/generate/performance_tracker.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:timing/timing.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../generate/watch_impl.dart';
import 'asset_graph_handler.dart';
import 'path_to_asset_id.dart';

const _performancePath = r'$perf';
final _graphPath = r'$graph';
final _assetsDigestPath = r'$assetDigests';
final _buildUpdatesProtocol = r'$buildUpdates';
final entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

final _logger = Logger('Serve');

enum PerfSortOrder {
  startTimeAsc,
  startTimeDesc,
  stopTimeAsc,
  stopTimeDesc,
  durationAsc,
  durationDesc,
  innerDurationAsc,
  innerDurationDesc
}

ServeHandler createServeHandler(WatchImpl watch) {
  var rootPackage = watch.packageGraph.root.name;
  var assetGraphHanderCompleter = Completer<AssetGraphHandler>();
  var assetHandlerCompleter = Completer<AssetHandler>();
  watch.ready.then((_) async {
    assetHandlerCompleter.complete(AssetHandler(watch.reader, rootPackage));
    assetGraphHanderCompleter.complete(
        AssetGraphHandler(watch.reader, rootPackage, watch.assetGraph));
  });
  return ServeHandler._(watch, assetHandlerCompleter.future,
      assetGraphHanderCompleter.future, rootPackage);
}

class ServeHandler implements BuildState {
  final WatchImpl _state;
  BuildResult _lastBuildResult;
  final String _rootPackage;

  final Future<AssetHandler> _assetHandler;
  final Future<AssetGraphHandler> _assetGraphHandler;

  final BuildUpdatesWebSocketHandler _webSocketHandler;

  ServeHandler._(this._state, this._assetHandler, this._assetGraphHandler,
      this._rootPackage)
      : _webSocketHandler = BuildUpdatesWebSocketHandler(_state) {
    _state.buildResults.listen((result) {
      _lastBuildResult = result;
      _webSocketHandler.emitUpdateMessage(result);
    }).onDone(_webSocketHandler.close);
  }

  @override
  Future<BuildResult> get currentBuild => _state.currentBuild;

  @override
  Stream<BuildResult> get buildResults => _state.buildResults;

  shelf.Handler handlerFor(String rootDir,
      {bool logRequests, BuildUpdatesOption buildUpdates}) {
    buildUpdates ??= BuildUpdatesOption.none;
    logRequests ??= false;
    if (p.url.split(rootDir).length != 1 || rootDir == '.') {
      throw ArgumentError.value(
        rootDir,
        'directory',
        'Only top level directories such as `web` or `test` can be served, got',
      );
    }
    _state.currentBuild.then((_) {
      // If the first build fails with a handled exception, we might not have
      // an asset graph and can't do this check.
      if (_state.assetGraph == null) return;
      _warnForEmptyDirectory(rootDir);
    });
    var cascade = shelf.Cascade();
    if (buildUpdates != BuildUpdatesOption.none) {
      cascade = cascade.add(_webSocketHandler.createHandlerByRootDir(rootDir));
    }
    cascade =
        cascade.add(_blockOnCurrentBuild).add((shelf.Request request) async {
      if (request.url.path == _performancePath) {
        return _performanceHandler(request);
      }
      if (request.url.path == _assetsDigestPath) {
        return _assetsDigestHandler(request, rootDir);
      }
      if (request.url.path.startsWith(_graphPath)) {
        var graphHandler = await _assetGraphHandler;
        return await graphHandler.handle(
            request.change(path: _graphPath), rootDir);
      }
      var assetHandler = await _assetHandler;
      return assetHandler.handle(request, rootDir: rootDir);
    });
    var pipeline = shelf.Pipeline();
    if (logRequests) {
      pipeline = pipeline.addMiddleware(_logRequests);
    }
    switch (buildUpdates) {
      case BuildUpdatesOption.liveReload:
        pipeline = pipeline.addMiddleware(_injectLiveReloadClientCode);
        break;
      case BuildUpdatesOption.none:
        break;
    }
    return pipeline.addHandler(cascade.handler);
  }

  Future<shelf.Response> _blockOnCurrentBuild(void _) async {
    await currentBuild;
    return shelf.Response.notFound('');
  }

  shelf.Response _performanceHandler(shelf.Request request) {
    var hideSkipped = false;
    var detailedSlices = false;
    var slicesResolution = 5;
    var sortOrder = PerfSortOrder.startTimeAsc;
    var filter = request.url.queryParameters['filter'] ?? '';
    if (request.url.queryParameters['hideSkipped']?.toLowerCase() == 'true') {
      hideSkipped = true;
    }
    if (request.url.queryParameters['detailedSlices']?.toLowerCase() ==
        'true') {
      detailedSlices = true;
    }
    if (request.url.queryParameters.containsKey('slicesResolution')) {
      slicesResolution =
          int.parse(request.url.queryParameters['slicesResolution']);
    }
    if (request.url.queryParameters.containsKey('sortOrder')) {
      sortOrder = PerfSortOrder
          .values[int.parse(request.url.queryParameters['sortOrder'])];
    }
    return shelf.Response.ok(
        _renderPerformance(_lastBuildResult.performance, hideSkipped,
            detailedSlices, slicesResolution, sortOrder, filter),
        headers: {HttpHeaders.contentTypeHeader: 'text/html'});
  }

  Future<shelf.Response> _assetsDigestHandler(
      shelf.Request request, String rootDir) async {
    var assertPathList =
        (jsonDecode(await request.readAsString()) as List).cast<String>();
    var rootPackage = _state.packageGraph.root.name;
    var results = <String, String>{};
    for (final path in assertPathList) {
      try {
        var assetId = pathToAssetId(rootPackage, rootDir, p.url.split(path));
        var digest = await _state.reader.digest(assetId);
        results[path] = digest.toString();
      } on AssetNotFoundException {
        results.remove(path);
      }
    }
    return shelf.Response.ok(jsonEncode(results),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'});
  }

  void _warnForEmptyDirectory(String rootDir) {
    if (!_state.assetGraph
        .packageNodes(_rootPackage)
        .any((n) => n.id.path.startsWith('$rootDir/'))) {
      _logger.warning('Requested a server for `$rootDir` but this directory '
          'has no assets in the build. You may need to add some sources or '
          'include this directory in some target in your `build.yaml`');
    }
  }
}

/// Class that manages web socket connection handler to inform clients about
/// build updates
class BuildUpdatesWebSocketHandler {
  final connectionsByRootDir = <String, List<WebSocketChannel>>{};
  final shelf.Handler Function(Function, {Iterable<String> protocols})
      _handlerFactory;
  final _internalHandlers = <String, shelf.Handler>{};
  final WatchImpl _state;

  BuildUpdatesWebSocketHandler(this._state,
      [this._handlerFactory = webSocketHandler]);

  shelf.Handler createHandlerByRootDir(String rootDir) {
    if (!_internalHandlers.containsKey(rootDir)) {
      var closureForRootDir = (WebSocketChannel webSocket, String protocol) =>
          _handleConnection(webSocket, protocol, rootDir);
      _internalHandlers[rootDir] = _handlerFactory(closureForRootDir,
          protocols: [_buildUpdatesProtocol]);
    }
    return _internalHandlers[rootDir];
  }

  Future emitUpdateMessage(BuildResult buildResult) async {
    if (buildResult.status != BuildStatus.success) return;
    var digests = <AssetId, String>{};
    for (var assetId in buildResult.outputs) {
      var digest = await _state.reader.digest(assetId);
      digests[assetId] = digest.toString();
    }
    for (var rootDir in connectionsByRootDir.keys) {
      var resultMap = <String, String>{};
      for (var assetId in digests.keys) {
        var path = assetIdToPath(assetId, rootDir);
        if (path != null) {
          resultMap[path] = digests[assetId];
        }
      }
      for (var connection in connectionsByRootDir[rootDir]) {
        connection.sink.add(jsonEncode(resultMap));
      }
    }
  }

  void _handleConnection(
      WebSocketChannel webSocket, String protocol, String rootDir) async {
    if (!connectionsByRootDir.containsKey(rootDir)) {
      connectionsByRootDir[rootDir] = [];
    }
    connectionsByRootDir[rootDir].add(webSocket);
    await webSocket.stream.drain();
    connectionsByRootDir[rootDir].remove(webSocket);
    if (connectionsByRootDir[rootDir].isEmpty) {
      connectionsByRootDir.remove(rootDir);
    }
  }

  Future<void> close() {
    return Future.wait(connectionsByRootDir.values
        .expand((x) => x)
        .map((connection) => connection.sink.close()));
  }
}

shelf.Handler Function(shelf.Handler) _injectBuildUpdatesClientCode(
        String scriptName) =>
    (innerHandler) {
      return (shelf.Request request) async {
        if (!request.url.path.endsWith('.js')) {
          return innerHandler(request);
        }
        var response = await innerHandler(request);
        // TODO: Find a way how to check and/or modify body without reading it
        // whole.
        var body = await response.readAsString();
        if (body.startsWith(entrypointExtensionMarker)) {
          body += _buildUpdatesInjectedJS(scriptName);
          var originalEtag = response.headers[HttpHeaders.etagHeader];
          if (originalEtag != null) {
            var newEtag = base64.encode(md5.convert(body.codeUnits).bytes);
            var newHeaders = Map.of(response.headers);
            newHeaders[HttpHeaders.etagHeader] = newEtag;

            if (request.headers[HttpHeaders.ifNoneMatchHeader] == newEtag) {
              return shelf.Response.notModified(headers: newHeaders);
            }

            response = response.change(headers: newHeaders);
          }
        }
        return response.change(body: body);
      };
    };

final _injectLiveReloadClientCode =
    _injectBuildUpdatesClientCode('live_reload_client');

/// Hot-/live- reload config
///
/// Listen WebSocket for updates in build results
String _buildUpdatesInjectedJS(String scriptName) => '''\n
// Injected by build_runner for build updates support
window.\$dartLoader.forceLoadModule('packages/build_runner/src/server/build_updates_client/$scriptName');
''';

class AssetHandler {
  final FinalizedReader _reader;
  final String _rootPackage;

  final _typeResolver = MimeTypeResolver();

  AssetHandler(this._reader, this._rootPackage);

  Future<shelf.Response> handle(shelf.Request request, {String rootDir}) =>
      (request.url.path.endsWith('/') || request.url.path.isEmpty)
          ? _handle(
              request.headers,
              pathToAssetId(
                  _rootPackage,
                  rootDir,
                  request.url.pathSegments
                      .followedBy(const ['index.html']).toList()),
              fallbackToDirectoryList: true)
          : _handle(request.headers,
              pathToAssetId(_rootPackage, rootDir, request.url.pathSegments));

  Future<shelf.Response> _handle(
      Map<String, String> requestHeaders, AssetId assetId,
      {bool fallbackToDirectoryList = false}) async {
    try {
      if (!await _reader.canRead(assetId)) {
        var reason = await _reader.unreadableReason(assetId);
        switch (reason) {
          case UnreadableReason.failed:
            return shelf.Response.internalServerError(
                body: 'Build failed for $assetId');
          case UnreadableReason.notOutput:
            return shelf.Response.notFound('$assetId was not output');
          case UnreadableReason.notFound:
            if (fallbackToDirectoryList) {
              return shelf.Response.notFound(await _findDirectoryList(assetId));
            }
            return shelf.Response.notFound('Not Found');
          default:
            return shelf.Response.notFound('Not Found');
        }
      }
    } on ArgumentError catch (_) {
      return shelf.Response.notFound('Not Found');
    }

    var etag = base64.encode((await _reader.digest(assetId)).bytes);
    var contentType = _typeResolver.lookup(assetId.path);
    if (contentType == 'text/x-dart') contentType += '; charset=utf-8';
    var headers = {
      HttpHeaders.contentTypeHeader: contentType,
      HttpHeaders.etagHeader: etag,
      // We always want this revalidated, which requires specifying both
      // max-age=0 and must-revalidate.
      //
      // See spec https://goo.gl/Lhvttg for more info about this header.
      HttpHeaders.cacheControlHeader: 'max-age=0, must-revalidate',
    };

    if (requestHeaders[HttpHeaders.ifNoneMatchHeader] == etag) {
      // This behavior is still useful for cases where a file is hit
      // without a cache-busting query string.
      return shelf.Response.notModified(headers: headers);
    }

    var bytes = await _reader.readAsBytes(assetId);
    headers[HttpHeaders.contentLengthHeader] = '${bytes.length}';
    return shelf.Response.ok(bytes, headers: headers);
  }

  Future<String> _findDirectoryList(AssetId from) async {
    var directoryPath = p.url.dirname(from.path);
    var glob = p.url.join(directoryPath, '*');
    var result =
        await _reader.findAssets(Glob(glob)).map((a) => a.path).toList();
    var message = StringBuffer('Could not find ${from.path}');
    if (result.isEmpty) {
      message.write(' or any files in $directoryPath. ');
    } else {
      message
        ..write('. $directoryPath contains:')
        ..writeAll(result, '\n')
        ..writeln();
    }
    message
        .write(' See https://github.com/dart-lang/build/blob/master/docs/faq.md'
            '#why-cant-i-see-a-file-i-know-exists');
    return '$message';
  }
}

String _renderPerformance(
    BuildPerformance performance,
    bool hideSkipped,
    bool detailedSlices,
    int slicesResolution,
    PerfSortOrder sortOrder,
    String filter) {
  try {
    var rows = StringBuffer();
    final resolution = Duration(milliseconds: slicesResolution);
    var count = 0,
        maxSlices = 1,
        max = 0,
        min = performance.stopTime.millisecondsSinceEpoch -
            performance.startTime.millisecondsSinceEpoch;

    void writeRow(BuilderActionPerformance action,
        BuilderActionStagePerformance stage, TimeSlice slice) {
      var actionKey = '${action.builderKey}:${action.primaryInput}';
      var tooltip = '<div class=perf-tooltip>'
          '<p><b>Builder:</b> ${action.builderKey}</p>'
          '<p><b>Input:</b> ${action.primaryInput}</p>'
          '<p><b>Stage:</b> ${stage.label}</p>'
          '<p><b>Stage time:</b> '
          '${stage.startTime.difference(performance.startTime).inMilliseconds / 1000}s - '
          '${stage.stopTime.difference(performance.startTime).inMilliseconds / 1000}s</p>'
          '<p><b>Stage real duration:</b> ${stage.duration.inMilliseconds / 1000} seconds</p>'
          '<p><b>Stage user duration:</b> ${stage.innerDuration.inMilliseconds / 1000} seconds</p>';
      if (slice != stage) {
        tooltip += '<p><b>Slice time:</b> '
            '${slice.startTime.difference(performance.startTime).inMilliseconds / 1000}s - '
            '${slice.stopTime.difference(performance.startTime).inMilliseconds / 1000}s</p>'
            '<p><b>Slice duration:</b> ${slice.duration.inMilliseconds / 1000} seconds</p>';
      }
      tooltip += '</div>';
      var start = slice.startTime.millisecondsSinceEpoch -
          performance.startTime.millisecondsSinceEpoch;
      var end = slice.stopTime.millisecondsSinceEpoch -
          performance.startTime.millisecondsSinceEpoch;

      if (min > start) min = start;
      if (max < end) max = end;

      rows.writeln(
          '          ["$actionKey", "${stage.label}", "$tooltip", $start, $end],');
      ++count;
    }

    final filterRegex = filter.isNotEmpty ? RegExp(filter) : null;

    final actions = performance.actions
        .where((action) =>
            !hideSkipped ||
            action.stages.any((stage) => stage.label == 'Build'))
        .where((action) =>
            filterRegex == null ||
            filterRegex.hasMatch('${action.builderKey}:${action.primaryInput}'))
        .toList();

    int Function(BuilderActionPerformance, BuilderActionPerformance) comparator;
    switch (sortOrder) {
      case PerfSortOrder.startTimeAsc:
        comparator = (a1, a2) => a1.startTime.compareTo(a2.startTime);
        break;
      case PerfSortOrder.startTimeDesc:
        comparator = (a1, a2) => a2.startTime.compareTo(a1.startTime);
        break;
      case PerfSortOrder.stopTimeAsc:
        comparator = (a1, a2) => a1.stopTime.compareTo(a2.stopTime);
        break;
      case PerfSortOrder.stopTimeDesc:
        comparator = (a1, a2) => a2.stopTime.compareTo(a1.stopTime);
        break;
      case PerfSortOrder.durationAsc:
        comparator = (a1, a2) => a1.duration.compareTo(a2.duration);
        break;
      case PerfSortOrder.durationDesc:
        comparator = (a1, a2) => a2.duration.compareTo(a1.duration);
        break;
      case PerfSortOrder.innerDurationAsc:
        comparator = (a1, a2) => a1.innerDuration.compareTo(a2.innerDuration);
        break;
      case PerfSortOrder.innerDurationDesc:
        comparator = (a1, a2) => a2.innerDuration.compareTo(a1.innerDuration);
        break;
    }
    actions.sort(comparator);

    for (var action in actions) {
      if (hideSkipped &&
          !action.stages.any((stage) => stage.label == 'Build')) {
        continue;
      }
      for (var stage in action.stages) {
        if (!detailedSlices) {
          writeRow(action, stage, stage);
          continue;
        }
        var slices = stage.slices.fold<List<TimeSlice>>([], (list, slice) {
          if (list.isNotEmpty &&
              slice.startTime.difference(list.last.stopTime) < resolution) {
            // concat with previous if gap less than resolution
            list.last = TimeSlice(list.last.startTime, slice.stopTime);
          } else {
            if (list.length > 1 && list.last.duration < resolution) {
              // remove previous if its duration less than resolution
              list.last = slice;
            } else {
              list.add(slice);
            }
          }
          return list;
        });
        if (slices.isNotEmpty) {
          for (var slice in slices) {
            writeRow(action, stage, slice);
          }
        } else {
          writeRow(action, stage, stage);
        }
        if (maxSlices < slices.length) maxSlices = slices.length;
      }
    }
    if (max - min < 1000) {
      rows.writeln('          ['
          '"https://github.com/google/google-visualization-issues/issues/2269"'
          ', "", "", $min, ${min + 1000}]');
    }
    return '''
  <html>
    <head>
      <script src="https://www.gstatic.com/charts/loader.js"></script>
      <script>
        google.charts.load('current', {'packages':['timeline']});
        google.charts.setOnLoadCallback(drawChart);
        function drawChart() {
          var container = document.getElementById('timeline');
          var chart = new google.visualization.Timeline(container);
          var dataTable = new google.visualization.DataTable();

          dataTable.addColumn({ type: 'string', id: 'ActionKey' });
          dataTable.addColumn({ type: 'string', id: 'Stage' });
          dataTable.addColumn({ type: 'string', role: 'tooltip', p: { html: true } });
          dataTable.addColumn({ type: 'number', id: 'Start' });
          dataTable.addColumn({ type: 'number', id: 'End' });
          dataTable.addRows([
  $rows
          ]);

          console.log('rendering', $count, 'blocks, max', $maxSlices,
            'slices in stage, resolution', $slicesResolution, 'ms');
          var options = {
            tooltip: { isHtml: true }
          };
          var statusText = document.getElementById('status');
          var timeoutId;
          var updateFunc = function () {
              if (timeoutId) {
                  // don't schedule more than one at a time
                  return;
              }
              statusText.innerText = 'Drawing table...';
              console.time('draw-time');

              timeoutId = setTimeout(function () {
                  chart.draw(dataTable, options);
                  console.timeEnd('draw-time');
                  statusText.innerText = '';
                  timeoutId = null;
              });
          };

          updateFunc();

          window.addEventListener('resize', updateFunc);
        }
      </script>
      <style>
      html, body {
        width: 100%;
        height: 100%;
        margin: 0;
      }

      body {
        display: flex;
        flex-direction: column;
      }

      #timeline {
        display: flex;
        flex-direction: row;
        flex: 1;
      }
      .controls-header p {
        display: inline-block;
        margin: 0.5em;
      }
      .perf-tooltip {
        margin: 0.5em;
      }
      </style>
    </head>
    <body>
      <form class="controls-header" action="/$_performancePath" onchange="this.submit()">
        <p><label><input type="checkbox" name="hideSkipped" value="true" ${hideSkipped ? 'checked' : ''}> Hide Skipped Actions</label></p>
        <p><label><input type="checkbox" name="detailedSlices" value="true" ${detailedSlices ? 'checked' : ''}> Show Async Slices</label></p>
        <p>Sort by: <select name="sortOrder">
          <option value="0" ${sortOrder.index == 0 ? 'selected' : ''}>Start Time Asc</option>
          <option value="1" ${sortOrder.index == 1 ? 'selected' : ''}>Start Time Desc</option>
          <option value="2" ${sortOrder.index == 2 ? 'selected' : ''}>Stop Time Asc</option>
          <option value="3" ${sortOrder.index == 3 ? 'selected' : ''}>Stop Time Desc</option>
          <option value="5" ${sortOrder.index == 4 ? 'selected' : ''}>Real Duration Asc</option>
          <option value="5" ${sortOrder.index == 5 ? 'selected' : ''}>Real Duration Desc</option>
          <option value="6" ${sortOrder.index == 6 ? 'selected' : ''}>User Duration Asc</option>
          <option value="7" ${sortOrder.index == 7 ? 'selected' : ''}>User Duration Desc</option>
        </select></p>
        <p>Slices Resolution: <select name="slicesResolution">
          <option value="0" ${slicesResolution == 0 ? 'selected' : ''}>0</option>
          <option value="1" ${slicesResolution == 1 ? 'selected' : ''}>1</option>
          <option value="3" ${slicesResolution == 3 ? 'selected' : ''}>3</option>
          <option value="5" ${slicesResolution == 5 ? 'selected' : ''}>5</option>
          <option value="10" ${slicesResolution == 10 ? 'selected' : ''}>10</option>
          <option value="15" ${slicesResolution == 15 ? 'selected' : ''}>15</option>
          <option value="20" ${slicesResolution == 20 ? 'selected' : ''}>20</option>
          <option value="25" ${slicesResolution == 25 ? 'selected' : ''}>25</option>
        </select></p>
        <p>Filter (RegExp): <input type="text" name="filter" value="$filter"></p>
        <p id="status"></p>
      </form>
      <div id="timeline"></div>
    </body>
  </html>
  ''';
  } on UnimplementedError catch (_) {
    return _enablePerformanceTracking;
  } on UnsupportedError catch (_) {
    return _enablePerformanceTracking;
  }
}

final _enablePerformanceTracking = '''
<html>
  <body>
    <p>
      Performance information not available, you must pass the
      `--track-performance` command line arg to enable performance tracking.
    </p>
  <body>
</html>
''';

/// [shelf.Middleware] that logs all requests, inspired by [shelf.logRequests].
shelf.Handler _logRequests(shelf.Handler innerHandler) {
  return (shelf.Request request) {
    var startTime = DateTime.now();
    var watch = Stopwatch()..start();

    return Future.sync(() => innerHandler(request)).then((response) {
      var logFn = response.statusCode >= 500 ? _logger.warning : _logger.info;
      var msg = _getMessage(startTime, response.statusCode,
          request.requestedUri, request.method, watch.elapsed);
      logFn(msg);
      return response;
    }, onError: (dynamic error, StackTrace stackTrace) {
      if (error is shelf.HijackException) throw error;
      var msg = _getMessage(
          startTime, 500, request.requestedUri, request.method, watch.elapsed);
      _logger.severe('$msg\r\n$error\r\n$stackTrace', true);
      throw error;
    });
  };
}

String _getMessage(DateTime requestTime, int statusCode, Uri requestedUri,
    String method, Duration elapsedTime) {
  return '${requestTime.toIso8601String()} '
      '${humanReadable(elapsedTime)} '
      '$method [$statusCode] '
      '${requestedUri.path}${_formatQuery(requestedUri.query)}\r\n';
}

String _formatQuery(String query) {
  return query == '' ? '' : '?$query';
}
