// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:coverage/coverage.dart' as coverage;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../vmservice.dart';

import 'watcher.dart';

/// A class that's used to collect coverage data during tests.
class CoverageCollector extends TestWatcher {
  CoverageCollector({this.libraryPredicate});

  Map<String, dynamic> _globalHitmap;
  bool Function(String) libraryPredicate;

  @override
  Future<void> handleFinishedTest(ProcessEvent event) async {
    printTrace('test ${event.childIndex}: collecting coverage');
    await collectCoverage(event.process, event.observatoryUri);
  }

  void _addHitmap(Map<String, dynamic> hitmap) {
    if (_globalHitmap == null) {
      _globalHitmap = hitmap;
    } else {
      coverage.mergeHitmaps(hitmap, _globalHitmap);
    }
  }

  /// Collects coverage for an isolate using the given `port`.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  ///
  /// The returned [Future] completes when the coverage is collected.
  Future<void> collectCoverageIsolate(Uri observatoryUri) async {
    assert(observatoryUri != null);
    print('collecting coverage data from $observatoryUri...');
    final Map<String, dynamic> data = await collect(observatoryUri, libraryPredicate);
    if (data == null) {
      throw Exception('Failed to collect coverage.');
    }
    assert(data != null);

    print('($observatoryUri): collected coverage data; merging...');
    _addHitmap(coverage.createHitmap(data['coverage']));
    print('($observatoryUri): done merging coverage data into global coverage map.');
  }

  /// Collects coverage for the given [Process] using the given `port`.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  ///
  /// The returned [Future] completes when the coverage is collected.
  Future<void> collectCoverage(Process process, Uri observatoryUri) async {
    assert(process != null);
    assert(observatoryUri != null);
    final int pid = process.pid;
    printTrace('pid $pid: collecting coverage data from $observatoryUri...');

    Map<String, dynamic> data;
    final Future<void> processComplete = process.exitCode
      .then<void>((int code) {
        throw Exception('Failed to collect coverage, process terminated prematurely with exit code $code.');
      });
    final Future<void> collectionComplete = collect(observatoryUri, libraryPredicate)
      .then<void>((Map<String, dynamic> result) {
        if (result == null)
          throw Exception('Failed to collect coverage.');
        data = result;
      });
    await Future.any<void>(<Future<void>>[ processComplete, collectionComplete ]);
    assert(data != null);

    printTrace('pid $pid ($observatoryUri): collected coverage data; merging...');
    _addHitmap(coverage.createHitmap(data['coverage']));
    printTrace('pid $pid ($observatoryUri): done merging coverage data into global coverage map.');
  }

  /// Returns a future that will complete with the formatted coverage data
  /// (using [formatter]) once all coverage data has been collected.
  ///
  /// This will not start any collection tasks. It us up to the caller of to
  /// call [collectCoverage] for each process first.
  Future<String> finalizeCoverage({
    coverage.Formatter formatter,
    Directory coverageDirectory,
  }) async {
    if (_globalHitmap == null) {
      return null;
    }
    if (formatter == null) {
      final coverage.Resolver resolver = coverage.Resolver(packagesPath: PackageMap.globalPackagesPath);
      final String packagePath = fs.currentDirectory.path;
      final List<String> reportOn = coverageDirectory == null
        ? <String>[fs.path.join(packagePath, 'lib')]
        : <String>[coverageDirectory.path];
      formatter = coverage.LcovFormatter(resolver, reportOn: reportOn, basePath: packagePath);
    }
    final String result = await formatter.format(_globalHitmap);
    _globalHitmap = null;
    return result;
  }

  Future<bool> collectCoverageData(String coveragePath, { bool mergeCoverageData = false, Directory coverageDirectory }) async {
    final Status status = logger.startProgress('Collecting coverage information...', timeout: timeoutConfiguration.fastOperation);
    final String coverageData = await finalizeCoverage(
      coverageDirectory: coverageDirectory,
    );
    status.stop();
    printTrace('coverage information collection complete');
    if (coverageData == null)
      return false;

    final File coverageFile = fs.file(coveragePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(coverageData, flush: true);
    printTrace('wrote coverage data to $coveragePath (size=${coverageData.length})');

    const String baseCoverageData = 'coverage/lcov.base.info';
    if (mergeCoverageData) {
      if (!fs.isFileSync(baseCoverageData)) {
        printError('Missing "$baseCoverageData". Unable to merge coverage data.');
        return false;
      }

      if (os.which('lcov') == null) {
        String installMessage = 'Please install lcov.';
        if (platform.isLinux)
          installMessage = 'Consider running "sudo apt-get install lcov".';
        else if (platform.isMacOS)
          installMessage = 'Consider running "brew install lcov".';
        printError('Missing "lcov" tool. Unable to merge coverage data.\n$installMessage');
        return false;
      }

      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_test_coverage.');
      try {
        final File sourceFile = coverageFile.copySync(fs.path.join(tempDir.path, 'lcov.source.info'));
        final RunResult result = processUtils.runSync(<String>[
          'lcov',
          '--add-tracefile', baseCoverageData,
          '--add-tracefile', sourceFile.path,
          '--output-file', coverageFile.path,
        ]);
        if (result.exitCode != 0)
          return false;
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    }
    return true;
  }
}

Future<VMService> _defaultConnect(Uri serviceUri) {
  return VMService.connect(
      serviceUri, compression: CompressionOptions.compressionOff);
}

Future<Map<String, dynamic>> collect(Uri serviceUri, bool Function(String) libraryPredicate, {
  bool waitPaused = false,
  String debugName,
  Future<VMService> Function(Uri) connector = _defaultConnect,
}) async {
  final VMService vmService = await connector(serviceUri);
  await vmService.getVM();
  return _getAllCoverage(vmService, libraryPredicate);
}

Future<Map<String, dynamic>> _getAllCoverage(VMService service, bool Function(String) libraryPredicate) async {
  await service.getVM();
  final List<Map<String, dynamic>> coverage = <Map<String, dynamic>>[];
  for (Isolate isolateRef in service.vm.isolates) {
    await isolateRef.load();
    final Map<String, dynamic> scriptList = await isolateRef.invokeRpcRaw('getScripts', params: <String, dynamic>{'isolateId': isolateRef.id});
    final List<Future<void>> futures = <Future<void>>[];

    final Map<String, Map<String, dynamic>> scripts = <String, Map<String, dynamic>>{};
    final Map<String, Map<String, dynamic>> sourceReports = <String, Map<String, dynamic>>{};
    // For each ScriptRef loaded into the VM, load the corresponding Script and
    // SourceReport object.

    // We may receive such objects as
    // {type: Sentinel, kind: Collected, valueAsString: <collected>}
    // that need to be skipped.
    if (scriptList['scripts'] == null) {
      continue;
    }
    for (Map<String, dynamic> script in scriptList['scripts']) {
      if (!libraryPredicate(script['uri'])) {
        continue;
      }
      final String scriptId = script['id'];
      futures.add(
        isolateRef.invokeRpcRaw('getSourceReport', params: <String, dynamic>{
          'forceCompile': true,
          'scriptId': scriptId,
          'isolateId': isolateRef.id,
          'reports': <String>['Coverage'],
        })
        .then((Map<String, dynamic> report) {
          sourceReports[scriptId] = report;
        })
      );
      futures.add(
        isolateRef.invokeRpcRaw('getObject', params: <String, dynamic>{
          'isolateId': isolateRef.id,
          'objectId': scriptId,
        })
        .then((Map<String, dynamic> script) {
          scripts[scriptId] = script;
        })
      );
    }
    await Future.wait(futures);
    _buildCoverageMap(scripts, sourceReports, coverage);
  }
  return <String, dynamic>{'type': 'CodeCoverage', 'coverage': coverage};
}

// Build a hitmap of Uri -> Line -> Hit Count for each script object.
void _buildCoverageMap(
  Map<String, Map<String, dynamic>> scripts,
  Map<String, Map<String, dynamic>> sourceReports,
  List<Map<String, dynamic>> coverage,
) {
  final Map<String, Map<int, int>> hitMaps = <String, Map<int, int>>{};
  for (String scriptId in scripts.keys) {
    final Map<String, dynamic> sourceReport = sourceReports[scriptId];
    for (Map<String, dynamic> range in sourceReport['ranges']) {
      final Map<String, dynamic> coverage = range['coverage'];
      // Coverage reports may sometimes be null for a Script.
      if (coverage == null) {
        continue;
      }
      final Map<String, dynamic> scriptRef = sourceReport['scripts'][range['scriptIndex']];
      final String uri = scriptRef['uri'];

      hitMaps[uri] ??= <int, int>{};
      final Map<int, int> hitMap = hitMaps[uri];
      final List<dynamic> hits = coverage['hits'];
      final List<dynamic> misses = coverage['misses'];
      final List<dynamic> tokenPositions = scripts[scriptRef['id']]['tokenPosTable'];
      // The token positions can be null if the script has no coverable lines.
      if (tokenPositions == null) {
        continue;
      }
      if (hits != null) {
        for (int hit in hits) {
          final int line = _lineAndColumn(hit, tokenPositions)[0];
          final int current = hitMap[line] ?? 0;
          hitMap[line] = current + 1;
        }
      }
      if (misses != null) {
        for (int miss in misses) {
          final int line = _lineAndColumn(miss, tokenPositions)[0];
          hitMap[line] ??= 0;
        }
      }
    }
  }
  hitMaps.forEach((String uri, Map<int, int> hitMap) {
    coverage.add(_toScriptCoverageJson(uri, hitMap));
  });
}

// Binary search the token position table for the line and column which
// corresponds to each token position.
// The format of this table is described in https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#script
List<int> _lineAndColumn(int position, List<dynamic> tokenPositions) {
  int min = 0;
  int max = tokenPositions.length;
  while (min < max) {
    final int mid = min + ((max - min) >> 1);
    final List<dynamic> row = tokenPositions[mid];
    if (row[1] > position) {
      max = mid;
    } else {
      for (int i = 1; i < row.length; i += 2) {
        if (row[i] == position) {
          return <int>[row.first, row[i + 1]];
        }
      }
      min = mid + 1;
    }
  }
  throw StateError('Unreachable');
}

// Returns a JSON hit map backward-compatible with pre-1.16.0 SDKs.
Map<String, dynamic> _toScriptCoverageJson(String scriptUri, Map<int, int> hitMap) {
  final Map<String, dynamic> json = <String, dynamic>{};
  final List<int> hits = <int>[];
  hitMap.forEach((int line, int hitCount) {
    hits.add(line);
    hits.add(hitCount);
  });
  json['source'] = scriptUri;
  json['script'] = <String, dynamic>{
    'type': '@Script',
    'fixedId': true,
    'id': 'libraries/1/scripts/${Uri.encodeComponent(scriptUri)}',
    'uri': scriptUri,
    '_kind': 'library',
  };
  json['hits'] = hits;
  return json;
}
