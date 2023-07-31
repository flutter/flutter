// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

class BaseAnalysisDriverTest with ResourceProviderMixin {
  late final DartSdk sdk;
  final ByteStore byteStore = MemoryByteStore();

  final StringBuffer logBuffer = StringBuffer();
  late final PerformanceLog logger;

  final _GeneratedUriResolverMock generatedUriResolver =
      _GeneratedUriResolverMock();
  late final AnalysisDriverScheduler scheduler;
  late final AnalysisDriver driver;
  final List<AnalysisStatus> allStatuses = <AnalysisStatus>[];
  final DriverTestAnalysisResults allResults = DriverTestAnalysisResults();
  final List<ExceptionResult> allExceptions = <ExceptionResult>[];

  late final String testProject;
  late final String testFile;
  late final String testCode;

  void addTestFile(String content, {bool priority = false}) {
    testCode = content;
    newFile(testFile, content);
    driver.addFile(testFile);
    if (priority) {
      driver.priorityFiles = [testFile];
    }
  }

  AnalysisDriver createAnalysisDriver(
      {Map<String, List<Folder>>? packageMap,
      SummaryDataStore? externalSummaries}) {
    packageMap ??= <String, List<Folder>>{
      'test': [getFolder('$testProject/lib')],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };
    return AnalysisDriver(
      scheduler: scheduler,
      logger: logger,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      sourceFactory: SourceFactory([
        DartUriResolver(sdk),
        generatedUriResolver,
        PackageMapUriResolver(resourceProvider, packageMap),
        ResourceUriResolver(resourceProvider)
      ]),
      analysisOptions: createAnalysisOptions(),
      packages: Packages({
        'test': Package(
          name: 'test',
          rootFolder: getFolder(testProject),
          libFolder: getFolder('$testProject/lib'),
          languageVersion: Version.parse('2.9.0'),
        ),
        'aaa': Package(
          name: 'aaa',
          rootFolder: getFolder('/aaa'),
          libFolder: getFolder('/aaa/lib'),
          languageVersion: Version.parse('2.9.0'),
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: getFolder('/bbb'),
          libFolder: getFolder('/bbb/lib'),
          languageVersion: Version.parse('2.9.0'),
        ),
      }),
      enableIndex: true,
      externalSummaries: externalSummaries,
      testView: AnalysisDriverTestView(),
    );
  }

  AnalysisOptionsImpl createAnalysisOptions() => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.latestLanguageVersion();

  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    if (offset < 0) {
      fail("Did not find '$search' in\n$testCode");
    }
    return offset;
  }

  int getLeadingIdentifierLength(String search) {
    int length = 0;
    while (length < search.length) {
      int c = search.codeUnitAt(length);
      if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
        length++;
        continue;
      }
      break;
    }
    return length;
  }

  void setUp() {
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    testProject = convertPath('/test');
    testFile = convertPath('/test/lib/test.dart');
    logger = PerformanceLog(logBuffer);
    scheduler = AnalysisDriverScheduler(logger);
    driver = createAnalysisDriver();
    scheduler.start();
    scheduler.status.listen(allStatuses.add);
    driver.results.listen((result) {
      allResults.add(result);
    });
    driver.exceptions.listen(allExceptions.add);
  }

  void tearDown() {}
}

class DriverTestAnalysisResults {
  final List<Object> _results = [];

  Object get first => _results.first;

  bool get isEmpty => _results.isEmpty;

  int get length => _results.length;

  List<String> get pathList => _withErrors.map((e) => e.path).toList();

  Set<String> get pathSet => _withErrors.map((e) => e.path).toSet();

  Object get single => _results.single;

  Iterable<AnalysisResultWithErrors> get _withErrors {
    return _results.whereType<AnalysisResultWithErrors>();
  }

  void add(Object result) {
    _results.add(result);
  }

  void clear() {
    _results.clear();
  }

  List<Object> toList() => _results.toList();

  Iterable<T> whereType<T>() => _results.whereType<T>();

  AnalysisResultWithErrors withPath(String path) {
    return _withErrors.singleWhere((result) => result.path == path);
  }
}

class _GeneratedUriResolverMock extends UriResolver {
  Source? Function(Uri)? resolveAbsoluteFunction;

  Uri? Function(String)? pathToUriFunction;

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  Uri? pathToUri(String path) {
    return pathToUriFunction?.call(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (resolveAbsoluteFunction != null) {
      return resolveAbsoluteFunction!(uri);
    }
    return null;
  }
}
