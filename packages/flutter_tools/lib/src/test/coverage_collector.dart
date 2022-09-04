// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.



import 'package:coverage/coverage.dart' as coverage;
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../globals.dart' as globals;
import '../vmservice.dart';

import 'test_device.dart';
import 'watcher.dart';

/// A class that collects code coverage data during test runs.
class CoverageCollector extends TestWatcher {
  CoverageCollector({this.libraryNames, this.verbose = true, required this.packagesPath});

  /// True when log messages should be emitted.
  final bool verbose;

  /// The path to the package_config.json of the package for which code
  /// coverage is computed.
  final String packagesPath;

  /// Map of file path to coverage hit map for that file.
  Map<String, coverage.HitMap>? _globalHitmap;

  /// The names of the libraries to gather coverage for. If null, all libraries
  /// will be accepted.
  Set<String>? libraryNames;

  @override
  Future<void> handleFinishedTest(TestDevice testDevice) async {
    _logMessage('Starting coverage collection');
    await collectCoverage(testDevice);
  }

  void _logMessage(String line, { bool error = false }) {
    if (!verbose) {
      return;
    }
    if (error) {
      globals.printError(line);
    } else {
      globals.printTrace(line);
    }
  }

  void _addHitmap(Map<String, coverage.HitMap> hitmap) {
    if (_globalHitmap == null) {
      _globalHitmap = hitmap;
    } else {
      _globalHitmap!.merge(hitmap);
    }
  }

  /// The directory of the package for which coverage is being collected.
  String get packageDirectory {
    // The coverage package expects the directory of the package itself, and
    // uses that to locate the package_info.json file, which it treats as a
    // private implementation detail. In general, the package_info.json file is
    // located in `.dart_tool/package_info.json` relative to the package
    // directory, so we return the grandparent directory of that file.
    //
    // This may not be a safe assumption in non-standard environments, such as
    // when building under build systems such as Bazel. In those cases, this
    // getter should be overridden.
    return globals.fs.directory(globals.fs.file(packagesPath).dirname).dirname;
  }

  /// Collects coverage for an isolate using the given `port`.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  ///
  /// The returned [Future] completes when the coverage is collected.
  Future<void> collectCoverageIsolate(Uri observatoryUri) async {
    assert(observatoryUri != null);
    _logMessage('collecting coverage data from $observatoryUri...');
    final Map<String, dynamic> data = await collect(observatoryUri, libraryNames);
    if (data == null) {
      throw Exception('Failed to collect coverage.');
    }
    assert(data != null);

    _logMessage('($observatoryUri): collected coverage data; merging...');
    _addHitmap(await coverage.HitMap.parseJson(
      data['coverage'] as List<Map<String, dynamic>>,
      packagePath: packageDirectory,
      checkIgnoredLines: true,
    ));
    _logMessage('($observatoryUri): done merging coverage data into global coverage map.');
  }

  /// Collects coverage for the given [Process] using the given `port`.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  ///
  /// The returned [Future] completes when the coverage is collected.
  Future<void> collectCoverage(TestDevice testDevice) async {
    assert(testDevice != null);

    Map<String, dynamic>? data;

    final Future<void> processComplete = testDevice.finished.catchError(
      (Object error) => throw Exception(
          'Failed to collect coverage, test device terminated prematurely with '
          'error: ${(error as TestDeviceException).message}.'),
      test: (Object error) => error is TestDeviceException,
    );

    final Future<void> collectionComplete = testDevice.observatoryUri
      .then((Uri? observatoryUri) {
        _logMessage('collecting coverage data from $testDevice at $observatoryUri...');
        return collect(observatoryUri, libraryNames)
          .then<void>((Map<String, dynamic> result) {
            if (result == null) {
              throw Exception('Failed to collect coverage.');
            }
            _logMessage('Collected coverage data.');
            data = result;
          });
      });

    await Future.any<void>(<Future<void>>[ processComplete, collectionComplete ]);
    assert(data != null);

    _logMessage('Merging coverage data...');
    _addHitmap(await coverage.HitMap.parseJson(
      data!['coverage'] as List<Map<String, dynamic>>,
      packagePath: packageDirectory,
      checkIgnoredLines: true,
    ));
    _logMessage('Done merging coverage data into global coverage map.');
  }

  /// Returns formatted coverage data once all coverage data has been collected.
  ///
  /// This will not start any collection tasks. It us up to the caller of to
  /// call [collectCoverage] for each process first.
  Future<String?> finalizeCoverage({
    String Function(Map<String, coverage.HitMap> hitmap)? formatter,
    coverage.Resolver? resolver,
    Directory? coverageDirectory,
  }) async {
    if (_globalHitmap == null) {
      return null;
    }
    if (formatter == null) {
      resolver ??= await coverage.Resolver.create(packagesPath: packagesPath);
      final String packagePath = globals.fs.currentDirectory.path;
      final List<String> reportOn = coverageDirectory == null
          ? <String>[globals.fs.path.join(packagePath, 'lib')]
          : <String>[coverageDirectory.path];
      formatter = (Map<String, coverage.HitMap> hitmap) => hitmap
          .formatLcov(resolver!, reportOn: reportOn, basePath: packagePath);
    }
    final String result = formatter(_globalHitmap!);
    _globalHitmap = null;
    return result;
  }

  Future<bool> collectCoverageData(String? coveragePath, { bool mergeCoverageData = false, Directory? coverageDirectory }) async {
    final String? coverageData = await finalizeCoverage(
      coverageDirectory: coverageDirectory,
    );
    _logMessage('coverage information collection complete');
    if (coverageData == null) {
      return false;
    }

    final File coverageFile = globals.fs.file(coveragePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(coverageData, flush: true);
    _logMessage('wrote coverage data to $coveragePath (size=${coverageData.length})');

    const String baseCoverageData = 'coverage/lcov.base.info';
    if (mergeCoverageData) {
      if (!globals.fs.isFileSync(baseCoverageData)) {
        _logMessage('Missing "$baseCoverageData". Unable to merge coverage data.', error: true);
        return false;
      }

      if (globals.os.which('lcov') == null) {
        String installMessage = 'Please install lcov.';
        if (globals.platform.isLinux) {
          installMessage = 'Consider running "sudo apt-get install lcov".';
        } else if (globals.platform.isMacOS) {
          installMessage = 'Consider running "brew install lcov".';
        }
        _logMessage('Missing "lcov" tool. Unable to merge coverage data.\n$installMessage', error: true);
        return false;
      }

      final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_test_coverage.');
      try {
        final File sourceFile = coverageFile.copySync(globals.fs.path.join(tempDir.path, 'lcov.source.info'));
        final RunResult result = globals.processUtils.runSync(<String>[
          'lcov',
          '--add-tracefile', baseCoverageData,
          '--add-tracefile', sourceFile.path,
          '--output-file', coverageFile.path,
        ]);
        if (result.exitCode != 0) {
          return false;
        }
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    }
    return true;
  }

  @override
  Future<void> handleTestCrashed(TestDevice testDevice) async { }

  @override
  Future<void> handleTestTimedOut(TestDevice testDevice) async { }
}

Future<FlutterVmService> _defaultConnect(Uri? serviceUri) {
  return connectToVmService(
      serviceUri!, compression: CompressionOptions.compressionOff, logger: globals.logger,);
}

Future<Map<String, dynamic>> collect(Uri? serviceUri, Set<String>? libraryNames, {
  bool waitPaused = false,
  String? debugName,
  Future<FlutterVmService> Function(Uri?) connector = _defaultConnect,
  @visibleForTesting bool forceSequential = false,
}) async {
  final FlutterVmService vmService = await connector(serviceUri);
  final Map<String, dynamic> result = await _getAllCoverage(vmService.service, libraryNames, forceSequential);
  await vmService.dispose();
  return result;
}

Future<Map<String, dynamic>> _getAllCoverage(
  vm_service.VmService service,
  Set<String>? libraryNames,
  bool forceSequential,
) async {
  final vm_service.Version version = await service.getVersion();
  final bool libraryFilters = (version.major == 3 && version.minor! >= 57) || version.major! > 3;
  final vm_service.VM vm = await service.getVM();
  final List<Map<String, dynamic>> coverage = <Map<String, dynamic>>[];
  bool libraryPredicate(String? libraryName) {
    if (libraryNames == null) {
      return true;
    }
    final Uri uri = Uri.parse(libraryName!);
    if (uri.scheme != 'package') {
      return false;
    }
    final String scope = uri.path.split('/').first;
    return libraryNames.contains(scope);
  }
  for (final vm_service.IsolateRef isolateRef in vm.isolates!) {
    if (isolateRef.isSystemIsolate!) {
      continue;
    }
    if (libraryFilters) {
      final vm_service.SourceReport sourceReport = await service.getSourceReport(
          isolateRef.id!,
          <String>['Coverage'],
          forceCompile: true,
          reportLines: true,
          libraryFilters: libraryNames == null ? null : List<String>.from(
              libraryNames.map((String name) => 'package:$name/')),
        );
      _buildCoverageMap(
          <String, vm_service.Script>{},
          <vm_service.SourceReport>[sourceReport],
          coverage,
        );
    } else {
      vm_service.ScriptList scriptList;
      try {
        scriptList = await service.getScripts(isolateRef.id!);
      } on vm_service.SentinelException {
        continue;
      }

      final List<Future<void>> futures = <Future<void>>[];
      final Map<String, vm_service.Script> scripts = <String, vm_service.Script>{};
      final List<vm_service.SourceReport> sourceReports = <vm_service.SourceReport>[];

      // For each ScriptRef loaded into the VM, load the corresponding Script
      // and SourceReport object.
      for (final vm_service.ScriptRef script in scriptList.scripts!) {
        final String? libraryUri = script.uri;
        if (!libraryPredicate(libraryUri)) {
          continue;
        }
        final String? scriptId = script.id;
        final Future<void> getSourceReport = service.getSourceReport(
          isolateRef.id!,
          <String>['Coverage'],
          scriptId: scriptId,
          forceCompile: true,
          reportLines: true,
        )
        .then((vm_service.SourceReport report) {
          sourceReports.add(report);
        });
        if (forceSequential) {
          await null;
        }
        futures.add(getSourceReport);
      }
      await Future.wait(futures);
      _buildCoverageMap(scripts, sourceReports, coverage);
    }
  }
  return <String, dynamic>{'type': 'CodeCoverage', 'coverage': coverage};
}

// Build a hitmap of Uri -> Line -> Hit Count for each script object.
void _buildCoverageMap(
  Map<String, vm_service.Script> scripts,
  List<vm_service.SourceReport> sourceReports,
  List<Map<String, dynamic>> coverage,
) {
  final Map<String?, Map<int, int>> hitMaps = <String?, Map<int, int>>{};
  for (final vm_service.SourceReport sourceReport  in sourceReports) {
    for (final vm_service.SourceReportRange range in sourceReport.ranges!) {
      final vm_service.SourceReportCoverage? coverage = range.coverage;
      // Coverage reports may sometimes be null for a Script.
      if (coverage == null) {
        continue;
      }
      final vm_service.ScriptRef scriptRef = sourceReport.scripts![range.scriptIndex!];
      final String? uri = scriptRef.uri;

      hitMaps[uri] ??= <int, int>{};
      final Map<int, int>? hitMap = hitMaps[uri];
      final List<int>? hits = coverage.hits;
      final List<int>? misses = coverage.misses;
      if (hits != null) {
        for (final int line in hits) {
          final int current = hitMap![line] ?? 0;
          hitMap[line] = current + 1;
        }
      }
      if (misses != null) {
        for (final int line in misses) {
          hitMap![line] ??= 0;
        }
      }
    }
  }
  hitMaps.forEach((String? uri, Map<int, int> hitMap) {
    coverage.add(_toScriptCoverageJson(uri!, hitMap));
  });
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
