// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'annotated_code_helper.dart';
import 'id.dart';
import 'id_generation.dart';
import '../util/colors.dart' as colors;

const String cfeMarker = 'cfe';
const String cfeWithNnbdMarker = '$cfeMarker:nnbd';
const String dart2jsMarker = 'dart2js';
const String analyzerMarker = 'analyzer';

/// Markers used in annotated tests shared by CFE, analyzer and dart2js.
const List<String> sharedMarkers = [
  cfeMarker,
  dart2jsMarker,
  analyzerMarker,
];

/// Markers used in annotated tests shared by CFE and analyzer.
const List<String> cfeAnalyzerMarkers = [
  cfeMarker,
  analyzerMarker,
];

/// Markers used in annotated tests shared by CFE, analyzer and dart2js.
const List<String> sharedMarkersWithNnbd = [
  cfeMarker,
  cfeWithNnbdMarker,
  dart2jsMarker,
  analyzerMarker,
];

/// Markers used in annotated tests used by CFE in both with and without nnbd.
const List<String> cfeMarkersWithNnbd = [
  cfeMarker,
  cfeWithNnbdMarker,
];

/// `true` if ANSI colors are supported by stdout.
bool useColors = stdout.supportsAnsiEscapes;

/// Colorize a message [text], if ANSI colors are supported.
String colorizeMessage(String text) {
  if (useColors) {
    return '${colors.YELLOW_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize a matching annotation [text], if ANSI colors are supported.
String colorizeMatch(String text) {
  if (useColors) {
    return '${colors.BLUE_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize a single annotation [text], if ANSI colors are supported.
String colorizeSingle(String text) {
  if (useColors) {
    return '${colors.GREEN_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize the actual annotation [text], if ANSI colors are supported.
String colorizeActual(String text) {
  if (useColors) {
    return '${colors.RED_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize an expected annotation [text], if ANSI colors are supported.
String colorizeExpected(String text) {
  if (useColors) {
    return '${colors.GREEN_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize delimiter [text], if ANSI colors are supported.
String colorizeDelimiter(String text) {
  if (useColors) {
    return '${colors.YELLOW_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize diffs [expected] and [actual] and [delimiter], if ANSI colors are
/// supported.
String colorizeDiff(String expected, String delimiter, String actual) {
  return '${colorizeExpected(expected)}'
      '${colorizeDelimiter(delimiter)}${colorizeActual(actual)}';
}

/// Colorize annotation delimiters [start] and [end] surrounding [text], if
/// ANSI colors are supported.
String colorizeAnnotation(String start, String text, String end) {
  return '${colorizeDelimiter(start)}$text${colorizeDelimiter(end)}';
}

/// Creates an annotation that shows the difference between [expected] and
/// [actual].
Annotation? createAnnotationsDiff(Annotation? expected, Annotation? actual) {
  if (identical(expected, actual)) return null;
  if (expected != null && actual != null) {
    return new Annotation(
        expected.index,
        expected.lineNo,
        expected.columnNo,
        expected.offset,
        expected.prefix,
        '${colorizeExpected(expected.text)}'
        '${colorizeDelimiter(' | ')}'
        '${colorizeActual(actual.text)}',
        expected.suffix);
  } else if (expected != null) {
    return new Annotation(
        expected.index,
        expected.lineNo,
        expected.columnNo,
        expected.offset,
        expected.prefix,
        '${colorizeExpected(expected.text)}'
        '${colorizeDelimiter(' | ')}'
        '${colorizeActual('---')}',
        expected.suffix);
  } else if (actual != null) {
    return new Annotation(
        actual.index,
        actual.lineNo,
        actual.columnNo,
        actual.offset,
        actual.prefix,
        '${colorizeExpected('---')}'
        '${colorizeDelimiter(' | ')}'
        '${colorizeActual(actual.text)}',
        actual.suffix);
  } else {
    return null;
  }
}

/// Encapsulates the member data computed for each source file of interest.
/// It's a glorified wrapper around a map of maps, but written this way to
/// provide a little more information about what it's doing. [DataType] refers
/// to the type this map is holding -- it is either [IdValue] or [ActualData].
class MemberAnnotations<DataType> {
  /// For each Uri, we create a map associating an element id with its
  /// corresponding annotations.
  final Map<Uri, Map<Id, DataType>> _computedDataForEachFile =
      new Map<Uri, Map<Id, DataType>>();

  /// Member or class annotations that don't refer to any of the user files.
  final Map<Id, DataType> globalData = <Id, DataType>{};

  void operator []=(Uri file, Map<Id, DataType> computedData) {
    _computedDataForEachFile[file] = computedData;
  }

  void forEach(void f(Uri file, Map<Id, DataType> computedData)) {
    _computedDataForEachFile.forEach(f);
  }

  Map<Id, DataType>? operator [](Uri file) {
    if (!_computedDataForEachFile.containsKey(file)) {
      _computedDataForEachFile[file] = <Id, DataType>{};
    }
    return _computedDataForEachFile[file];
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('MemberAnnotations(');
    String comma = '';
    if (_computedDataForEachFile.isNotEmpty &&
        (_computedDataForEachFile.length > 1 ||
            _computedDataForEachFile.values.single.isNotEmpty)) {
      sb.write('data:{');
      _computedDataForEachFile.forEach((Uri uri, Map<Id, DataType> data) {
        sb.write(comma);
        sb.write('$uri:');
        sb.write(data);
        comma = ',';
      });
      sb.write('}');
    }
    if (globalData.isNotEmpty) {
      sb.write(comma);
      sb.write('global:');
      sb.write(globalData);
    }
    sb.write(')');
    return sb.toString();
  }
}

/// Compute a [MemberAnnotations] object from [code] for each marker in [maps]
/// specifying the expected annotations.
///
/// If an annotation starts with a marker, it is only expected for the
/// corresponding test configuration. Otherwise it is expected for all
/// configurations.
// TODO(johnniwinther): Support an empty marker set.
void computeExpectedMap(Uri sourceUri, String filename, AnnotatedCode code,
    Map<String, MemberAnnotations<IdValue>> maps,
    {required void onFailure(String message),
    bool preserveWhitespaceInAnnotations: false,
    bool preserveInfixWhitespaceInAnnotations: false}) {
  List<String> mapKeys = maps.keys.toList();
  Map<String, AnnotatedCode> split = splitByPrefixes(code, mapKeys);

  split.forEach((String marker, AnnotatedCode code) {
    MemberAnnotations<IdValue> fileAnnotations = maps[marker]!;
    // ignore: unnecessary_null_comparison
    assert(fileAnnotations != null, "No annotations for $marker in $maps");
    Map<Id, IdValue> expectedValues = fileAnnotations[sourceUri]!;
    for (Annotation annotation in code.annotations) {
      String text = annotation.text;
      IdValue idValue = IdValue.decode(sourceUri, annotation, text,
          preserveWhitespaceInAnnotations: preserveWhitespaceInAnnotations,
          preserveInfixWhitespace: preserveInfixWhitespaceInAnnotations);
      if (idValue.id.isGlobal) {
        if (fileAnnotations.globalData.containsKey(idValue.id)) {
          onFailure("Error in test '$filename': "
              "Duplicate annotations for ${idValue.id} in $marker: "
              "${idValue} and ${fileAnnotations.globalData[idValue.id]}.");
        }
        fileAnnotations.globalData[idValue.id] = idValue;
      } else {
        if (expectedValues.containsKey(idValue.id)) {
          onFailure("Error in test '$filename': "
              "Duplicate annotations for ${idValue.id} in $marker: "
              "${idValue} and ${expectedValues[idValue.id]}.");
        }
        expectedValues[idValue.id] = idValue;
      }
    }
  });
}

/// Creates a [TestData] object for the annotated test in [testFile].
///
/// If [testFile] is a file, use that directly. If it's a directory include
/// everything in that directory.
///
/// If [testLibDirectory] is not `null`, files in [testLibDirectory] with the
/// [testFile] name as a prefix are included.
TestData computeTestData(FileSystemEntity testFile,
    {required Iterable<String> supportedMarkers,
    required Uri createTestUri(Uri uri, String fileName),
    required void onFailure(String message),
    bool preserveWhitespaceInAnnotations: false,
    bool preserveInfixWhitespaceInAnnotations: false}) {
  Uri? entryPoint;

  String testName;
  File? mainTestFile;
  Uri testFileUri = testFile.uri;
  Map<String, File>? additionalFiles;
  if (testFile is File) {
    testName = testFileUri.pathSegments.last;
    mainTestFile = testFile;
    entryPoint = createTestUri(mainTestFile.uri, 'main.dart');
  } else if (testFile is Directory) {
    testName = testFileUri.pathSegments[testFileUri.pathSegments.length - 2];
    additionalFiles = new Map<String, File>();
    for (FileSystemEntity entry in testFile
        .listSync(recursive: true)
        .where((entity) => !entity.path.endsWith('~'))) {
      if (entry is! File) continue;
      if (entry.uri.pathSegments.last == "main.dart") {
        mainTestFile = entry;
        entryPoint = createTestUri(mainTestFile.uri, 'main.dart');
      } else {
        additionalFiles[entry.uri.path.substring(testFile.uri.path.length)] =
            entry;
      }
    }
    assert(
        mainTestFile != null, "No 'main.dart' test file found for $testFile.");
  } else {
    throw new UnimplementedError();
  }

  String annotatedCode = new File.fromUri(mainTestFile!.uri).readAsStringSync();
  Map<Uri, AnnotatedCode> code = {
    entryPoint!:
        new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd)
  };
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {};
  for (String testMarker in supportedMarkers) {
    expectedMaps[testMarker] = new MemberAnnotations<IdValue>();
  }
  computeExpectedMap(entryPoint, testFile.uri.pathSegments.last,
      code[entryPoint]!, expectedMaps,
      onFailure: onFailure,
      preserveWhitespaceInAnnotations: preserveWhitespaceInAnnotations,
      preserveInfixWhitespaceInAnnotations:
          preserveInfixWhitespaceInAnnotations);
  Map<String, String> memorySourceFiles = {
    entryPoint.path: code[entryPoint]!.sourceCode
  };

  if (additionalFiles != null) {
    for (MapEntry<String, File> additionalFileData in additionalFiles.entries) {
      String libFileName = additionalFileData.key;
      File libEntity = additionalFileData.value;
      Uri libFileUri = createTestUri(libEntity.uri, libFileName);
      String libCode = libEntity.readAsStringSync();
      AnnotatedCode annotatedLibCode =
          new AnnotatedCode.fromText(libCode, commentStart, commentEnd);
      memorySourceFiles[libFileUri.path] = annotatedLibCode.sourceCode;
      code[libFileUri] = annotatedLibCode;
      computeExpectedMap(
          libFileUri, libFileName, annotatedLibCode, expectedMaps,
          onFailure: onFailure,
          preserveWhitespaceInAnnotations: preserveWhitespaceInAnnotations,
          preserveInfixWhitespaceInAnnotations:
              preserveInfixWhitespaceInAnnotations);
    }
  }

  return new TestData(
      testName, testFileUri, entryPoint, memorySourceFiles, code, expectedMaps);
}

/// Data for an annotated test.
class TestData {
  final String name;
  final Uri testFileUri;
  final Uri entryPoint;
  final Map<String, String> memorySourceFiles;
  final Map<Uri, AnnotatedCode> code;
  final Map<String, MemberAnnotations<IdValue>> expectedMaps;

  TestData(this.name, this.testFileUri, this.entryPoint, this.memorySourceFiles,
      this.code, this.expectedMaps);
}

/// The results for running a test on a single configuration.
class TestResult<T> {
  /// `true` if the [compiledData]  didn't match the expected annotations.
  final bool hasMismatches;

  /// `true` if the test couldn't be run due to errors in the test setup.
  final bool isErroneous;

  /// The data interpreter used to verify the [compiledData].
  final DataInterpreter<T>? interpreter;

  /// The actual data computed for the test.
  final CompiledData<T>? compiledData;

  TestResult(this.interpreter, this.compiledData, this.hasMismatches)
      : isErroneous = false;

  TestResult.erroneous()
      : isErroneous = true,
        hasMismatches = false,
        interpreter = null,
        compiledData = null;

  bool get hasFailures => hasMismatches || isErroneous;
}

/// The actual result computed for an annotated test.
abstract class CompiledData<T> {
  final Uri mainUri;

  /// For each Uri, a map associating an element id with the instrumentation
  /// data we've collected for it.
  final Map<Uri, Map<Id, ActualData<T>>> actualMaps;

  /// Collected instrumentation data that doesn't refer to any of the user
  /// files.  (E.g. information the test has collected about files in
  /// `dart:core`).
  final Map<Id, ActualData<T>> globalData;

  CompiledData(this.mainUri, this.actualMaps, this.globalData);

  Map<int, List<String>> computeAnnotations(Uri uri) {
    Map<Id, ActualData<T>> actualMap = actualMaps[uri]!;
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMap.forEach((Id id, ActualData<T> data) {
      String value1 = '${data.value}';
      annotations
          .putIfAbsent(data.offset, () => [])
          .add(colorizeActual(value1));
    });
    return annotations;
  }

  Map<int, List<String>> computeDiffAnnotationsAgainst(
      Map<Id, ActualData<T>> thisMap, Map<Id, ActualData<T>> otherMap, Uri uri,
      {bool includeMatches: false}) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData<T> thisData) {
      ActualData<T>? otherData = otherMap[id];
      String thisValue = '${thisData.value}';
      if (thisData.value != otherData?.value) {
        String otherValue = '${otherData?.value ?? '---'}';
        annotations
            .putIfAbsent(thisData.offset, () => [])
            .add(colorizeDiff(thisValue, ' | ', otherValue));
      } else if (includeMatches) {
        annotations
            .putIfAbsent(thisData.offset, () => [])
            .add(colorizeMatch(thisValue));
      }
    });
    otherMap.forEach((Id id, ActualData<T> otherData) {
      if (!thisMap.containsKey(id)) {
        String thisValue = '---';
        String otherValue = '${otherData.value}';
        annotations
            .putIfAbsent(otherData.offset, () => [])
            .add(colorizeDiff(thisValue, ' | ', otherValue));
      }
    });
    return annotations;
  }

  int getOffsetFromId(Id id, Uri uri);

  void reportError(Uri uri, int offset, String message, {bool succinct: false});
}

/// Interface used for interpreting annotations.
abstract class DataInterpreter<T> {
  /// Returns `null` if [actualData] satisfies the [expectedData] annotation.
  /// Otherwise, a message is returned contain the information about the
  /// problems found.
  String? isAsExpected(T actualData, String? expectedData);

  /// Returns `true` if [actualData] corresponds to empty data.
  bool isEmpty(T actualData);

  /// Returns a textual representation of [actualData].
  ///
  /// If [indentation] is provided a multiline pretty printing can be returned
  /// using [indentation] for additional lines.
  String getText(T actualData, [String? indentation]);
}

/// Default data interpreter for string data.
class StringDataInterpreter implements DataInterpreter<String> {
  const StringDataInterpreter();

  @override
  String? isAsExpected(String actualData, String? expectedData) {
    expectedData ??= '';
    if (actualData != expectedData) {
      return "Expected $expectedData, found $actualData";
    }
    return null;
  }

  @override
  bool isEmpty(String actualData) {
    return actualData == '';
  }

  @override
  String getText(String actualData, [String? indentation]) {
    return actualData;
  }
}

String withAnnotations(String sourceCode, Map<int, List<String>> annotations) {
  StringBuffer sb = new StringBuffer();
  int end = 0;
  for (int offset in annotations.keys.toList()..sort()) {
    if (offset >= sourceCode.length) {
      sb.write('...');
      return sb.toString();
    }
    if (offset > end) {
      sb.write(sourceCode.substring(end, offset));
    }
    for (String annotation in annotations[offset]!) {
      sb.write(colorizeAnnotation('/*', annotation, '*/'));
    }
    end = offset;
  }
  if (end < sourceCode.length) {
    sb.write(sourceCode.substring(end));
  }
  return sb.toString();
}

/// Checks [compiledData] against the expected data in [expectedMaps] derived
/// from [code].
Future<TestResult<T>> checkCode<T>(
    String modeName,
    Uri mainFileUri,
    Map<Uri, AnnotatedCode> code,
    MemberAnnotations<IdValue> expectedMaps,
    CompiledData<T> compiledData,
    DataInterpreter<T> dataInterpreter,
    {bool filterActualData(IdValue? expected, ActualData<T> actualData)?,
    bool fatalErrors: true,
    bool succinct: false,
    required void onFailure(String message)}) async {
  bool hasFailure = false;
  Set<Uri> neededDiffs = new Set<Uri>();

  void checkActualMap(Map<Id, ActualData<T>> actualMap,
      Map<Id, IdValue>? expectedMap, Uri uri) {
    expectedMap ??= {};
    bool hasLocalFailure = false;
    actualMap.forEach((Id id, ActualData<T> actualData) {
      T actual = actualData.value;
      String actualText = dataInterpreter.getText(actual);

      if (!expectedMap!.containsKey(id)) {
        if (!dataInterpreter.isEmpty(actual)) {
          String actualValueText = IdValue.idToString(id, actualText);
          compiledData.reportError(
              actualData.uri,
              actualData.offset,
              succinct
                  ? 'EXTRA $modeName DATA for ${id.descriptor}'
                  : 'EXTRA $modeName DATA for ${id.descriptor}:\n '
                      'object   : ${actualData.objectText}\n '
                      'actual   : ${colorizeActual(actualValueText)}\n '
                      'Data was expected for these ids: ${expectedMap.keys}',
              succinct: succinct);
          if (filterActualData == null || filterActualData(null, actualData)) {
            hasLocalFailure = true;
          }
        }
      } else {
        IdValue expected = expectedMap[id]!;
        String? unexpectedMessage =
            dataInterpreter.isAsExpected(actual, expected.value);
        if (unexpectedMessage != null) {
          String actualValueText = IdValue.idToString(id, actualText);
          compiledData.reportError(
              actualData.uri,
              actualData.offset,
              succinct
                  ? 'UNEXPECTED $modeName DATA for ${id.descriptor}'
                  : 'UNEXPECTED $modeName DATA for ${id.descriptor}:\n '
                      'detail  : ${colorizeMessage(unexpectedMessage)}\n '
                      'object  : ${actualData.objectText}\n '
                      'expected: ${colorizeExpected('$expected')}\n '
                      'actual  : ${colorizeActual(actualValueText)}',
              succinct: succinct);
          if (filterActualData == null ||
              filterActualData(expected, actualData)) {
            hasLocalFailure = true;
          }
        }
      }
    });
    if (hasLocalFailure) {
      hasFailure = true;
      neededDiffs.add(uri);
    }
  }

  compiledData.actualMaps.forEach((Uri uri, Map<Id, ActualData<T>> actualMap) {
    checkActualMap(actualMap, expectedMaps[uri], uri);
  });
  checkActualMap(compiledData.globalData, expectedMaps.globalData,
      Uri.parse("global:data"));

  Set<Id> missingIds = new Set<Id>();
  void checkMissing(
      Map<Id, IdValue>? expectedMap, Map<Id, ActualData<T>>? actualMap,
      [Uri? uri]) {
    actualMap ??= {};
    expectedMap?.forEach((Id id, IdValue expected) {
      if (!actualMap!.containsKey(id)) {
        missingIds.add(id);
        String message = 'MISSING $modeName DATA for ${id.descriptor}: '
            'Expected ${colorizeExpected('$expected')}';
        if (uri != null) {
          compiledData.reportError(
              uri, compiledData.getOffsetFromId(id, uri), message,
              succinct: succinct);
        } else {
          print(message);
        }
      }
    });
    if (missingIds.isNotEmpty && uri != null) {
      neededDiffs.add(uri);
    }
  }

  expectedMaps.forEach((Uri uri, Map<Id, IdValue> expectedMap) {
    checkMissing(expectedMap, compiledData.actualMaps[uri], uri);
  });
  checkMissing(expectedMaps.globalData, compiledData.globalData);
  if (!succinct) {
    if (neededDiffs.isNotEmpty) {
      Map<Uri, List<Annotation>> annotations = computeAnnotationsPerUri(
          code,
          {'dummyMarker': expectedMaps},
          compiledData.mainUri,
          {'dummyMarker': compiledData.actualMaps},
          dataInterpreter,
          createDiff: createAnnotationsDiff);
      for (Uri uri in neededDiffs) {
        print('--annotations diff [${uri.pathSegments.last}]-------------');
        AnnotatedCode? annotatedCode = code[uri];
        print(new AnnotatedCode(annotatedCode?.annotatedCode ?? "",
                annotatedCode?.sourceCode ?? "", annotations[uri] ?? const [])
            .toText());
        print('----------------------------------------------------------');
      }
    }
  }
  if (missingIds.isNotEmpty) {
    print("MISSING ids: ${missingIds}.");
    hasFailure = true;
  }
  if (hasFailure && fatalErrors) {
    onFailure('Errors found.');
  }
  return new TestResult<T>(dataInterpreter, compiledData, hasFailure);
}

typedef Future<Map<String, TestResult<T>>> RunTestFunction<T>(TestData testData,
    {required bool testAfterFailures,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    Map<String, List<String>>? skipMap,
    required Uri nullUri});

/// Compute the file: URI of the file located at `path`, where `path` is
/// relative to the root of the SDK repository.
///
/// We find the root of the SDK repository by looking for the parent of the
/// directory named `pkg`.
Uri _fileUriFromSdkRoot(String path) {
  Uri uri = Platform.script;
  List<String> pathSegments = uri.pathSegments;
  return uri.replace(pathSegments: [
    ...pathSegments.sublist(0, pathSegments.lastIndexOf('pkg')),
    ...path.split('/')
  ]);
}

class MarkerOptions {
  final Map<String, Uri> markers;

  MarkerOptions.internal(this.markers);

  factory MarkerOptions.fromDataDir(Directory dataDir,
      {bool shouldFindScript: true}) {
    File file = new File.fromUri(dataDir.uri.resolve('marker.options'));
    File script = new File.fromUri(Platform.script);
    if (!file.existsSync()) {
      throw new ArgumentError("Marker option file '$file' doesn't exist.");
    }

    Map<String, Uri> markers = {};
    String text = file.readAsStringSync();
    bool isScriptFound = false;
    for (String line in text.split('\n')) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      int eqPos = line.indexOf('=');
      if (eqPos == -1) {
        throw new ArgumentError(
            "Unsupported marker option '$line' in ${file.uri}");
      }
      String marker = line.substring(0, eqPos);
      String tester = line.substring(eqPos + 1);
      File testerFile = new File.fromUri(_fileUriFromSdkRoot(tester));
      if (!testerFile.existsSync()) {
        throw new ArgumentError(
            "Tester '$tester' does not exist for marker '$marker' in "
            "${file.uri}");
      }
      if (markers.containsKey(marker)) {
        throw new ArgumentError("Duplicate marker '$marker' in ${file.uri}");
      }
      markers[marker] = testerFile.uri;
      if (testerFile.absolute.uri == script.absolute.uri) {
        isScriptFound = true;
      }
    }
    if (shouldFindScript && !isScriptFound) {
      throw new ArgumentError(
          "Script '${script.uri}' not found in ${file.uri}");
    }
    return new MarkerOptions.internal(markers);
  }

  Iterable<String> get supportedMarkers => markers.keys;

  Future<void> runAll(List<String> args) async {
    Set<Uri> testers = markers.values.toSet();
    bool allOk = true;
    for (Uri tester in testers) {
      print('================================================================');
      print('Running tester: $tester ${args.join(' ')}');
      print('================================================================');
      Process process = await Process.start(
          Platform.resolvedExecutable, [tester.toString(), ...args],
          mode: ProcessStartMode.inheritStdio);
      if (await process.exitCode != 0) {
        allOk = false;
      }
    }
    if (!allOk) {
      throw "Error(s) occurred.";
    }
  }
}

String getTestName(FileSystemEntity entity) {
  if (entity is Directory) {
    return entity.uri.pathSegments[entity.uri.pathSegments.length - 2];
  } else {
    return entity.uri.pathSegments.last;
  }
}

/// Check code for all tests in [dataDir] using [runTest].
Future<void> runTests<T>(Directory dataDir,
    {List<String> args: const <String>[],
    int shards: 1,
    int shardIndex: 0,
    void onTest(Uri uri)?,
    required Uri createUriForFileName(String fileName),
    required void onFailure(String message),
    required RunTestFunction<T> runTest,
    List<String>? skipList,
    Map<String, List<String>>? skipMap,
    bool preserveWhitespaceInAnnotations: false,
    bool preserveInfixWhitespaceInAnnotations: false}) async {
  MarkerOptions markerOptions =
      new MarkerOptions.fromDataDir(dataDir, shouldFindScript: shards == 1);
  // TODO(johnniwinther): Support --show to show actual data for an input.
  args = args.toList();
  bool runAll = args.remove('--run-all');
  if (runAll) {
    await markerOptions.runAll(args);
    return;
  }
  bool verbose = args.remove('-v');
  bool succinct = args.remove('-s');
  bool shouldContinue = args.remove('-c');
  bool testAfterFailures = args.remove('-a');
  bool printCode = args.remove('-p');
  bool continued = false;
  bool hasFailures = false;
  bool generateAnnotations = args.remove('-g');
  bool forceUpdate = args.remove('-f');

  String relativeDir = dataDir.uri.path.replaceAll(Uri.base.path, '');
  print('Data dir: ${relativeDir}');
  List<FileSystemEntity> entities = dataDir
      .listSync()
      .where((entity) =>
          !entity.path.endsWith('~') && !entity.path.endsWith('marker.options'))
      .toList();
  if (shards > 1) {
    entities.sort((a, b) => getTestName(a).compareTo(getTestName(b)));
    int start = entities.length * shardIndex ~/ shards;
    int end = entities.length * (shardIndex + 1) ~/ shards;
    entities = entities.sublist(start, end);
  }
  int testCount = 0;
  for (FileSystemEntity entity in entities) {
    String name = getTestName(entity);
    if (args.isNotEmpty && !args.contains(name) && !continued) continue;
    if (shouldContinue) continued = true;
    testCount++;

    if (skipList != null && skipList.contains(name) && !args.contains(name)) {
      print('Skip: ${name}');
      continue;
    }
    if (onTest != null) {
      onTest(entity.uri);
    }
    print('----------------------------------------------------------------');

    Map<Uri, Uri> testToFileUri = {};

    Uri createTestUri(Uri fileUri, String fileName) {
      Uri testUri = createUriForFileName(fileName);
      testToFileUri[testUri] = fileUri;
      return testUri;
    }

    TestData testData = computeTestData(entity,
        supportedMarkers: markerOptions.supportedMarkers,
        createTestUri: createTestUri,
        onFailure: onFailure,
        preserveWhitespaceInAnnotations: preserveWhitespaceInAnnotations,
        preserveInfixWhitespaceInAnnotations:
            preserveInfixWhitespaceInAnnotations);
    print('Test: ${testData.testFileUri}');

    Map<String, TestResult<T>> results = await runTest(testData,
        testAfterFailures: testAfterFailures || generateAnnotations,
        verbose: verbose,
        succinct: succinct,
        printCode: printCode,
        skipMap: skipMap,
        nullUri: createTestUri(entity.uri.resolve("null"), "null"));

    bool hasMismatches = false;
    bool hasErrors = false;
    results.forEach((String marker, TestResult<T> result) {
      if (result.hasMismatches) {
        hasMismatches = true;
      } else if (result.isErroneous) {
        hasErrors = true;
      }
    });
    if (hasErrors) {
      // Cannot generate annotations for erroneous tests.
      hasFailures = true;
    } else if (hasMismatches || (forceUpdate && generateAnnotations)) {
      if (generateAnnotations) {
        DataInterpreter? dataInterpreter;
        Map<String, Map<Uri, Map<Id, ActualData<T>>>> actualData = {};
        results.forEach((String marker, TestResult<T> result) {
          dataInterpreter ??= result.interpreter;
          Map<Uri, Map<Id, ActualData<T>>> actualDataPerUri =
              actualData[marker] = {};

          void addActualData(Uri uri, Map<Id, ActualData<T>> actualData) {
            // ignore: unnecessary_null_comparison
            assert(uri != null && testData.code.containsKey(uri) ||
                actualData.isEmpty);
            // ignore: unnecessary_null_comparison
            if (uri == null || actualData.isEmpty) {
              // TODO(johnniwinther): Avoid collecting data without
              //  invalid uris.
              return;
            }
            Map<Id, ActualData<T>> actualDataPerId =
                actualDataPerUri[uri] ??= {};
            actualDataPerId.addAll(actualData);
          }

          result.compiledData!.actualMaps.forEach(addActualData);
          addActualData(
              result.compiledData!.mainUri, result.compiledData!.globalData);
        });

        Map<Uri, List<Annotation>> annotations = computeAnnotationsPerUri(
            testData.code,
            testData.expectedMaps,
            testData.entryPoint,
            actualData,
            dataInterpreter!,
            forceUpdate: forceUpdate);
        annotations.forEach((Uri uri, List<Annotation> annotations) {
          // ignore: unnecessary_null_comparison
          assert(uri != null, "Annotations without uri: $annotations");
          AnnotatedCode? code = testData.code[uri];
          assert(code != null,
              "No annotated code for $uri with annotations: $annotations");
          AnnotatedCode generated = new AnnotatedCode(
              code?.annotatedCode ?? "", code?.sourceCode ?? "", annotations);
          Uri fileUri = testToFileUri[uri]!;
          new File.fromUri(fileUri).writeAsStringSync(generated.toText());
          print('Generated annotations for ${fileUri}');
        });
      } else {
        hasFailures = true;
      }
    }
  }
  if (hasFailures) {
    onFailure('Errors found.');
  }
  if (testCount == 0) {
    onFailure("No files were tested.");
  }
}

/// Returns `true` if [testName] is marked as skipped in [skipMap] for
/// the given [configMarker].
bool skipForConfig(
    String testName, String configMarker, Map<String, List<String>>? skipMap) {
  if (skipMap != null) {
    List<String>? skipList = skipMap[configMarker];
    if (skipList != null && skipList.contains(testName)) {
      print("Skip: ${testName} for config '${configMarker}'");
      return true;
    }
    skipList = skipMap[null];
    if (skipList != null && skipList.contains(testName)) {
      print("Skip: ${testName} for config '${configMarker}'");
      return true;
    }
  }
  return false;
}

/// Updates all id tests in [relativeTestPaths].
///
/// This assumes that the current working directory is the repository root.
Future<void> updateAllTests(List<String> relativeTestPaths) async {
  for (String testPath in relativeTestPaths) {
    List<String> arguments = [];
    if (Platform.packageConfig != null) {
      arguments.add('--packages=${Platform.packageConfig}');
    }
    arguments.addAll([
      testPath,
      '-g',
      '--run-all',
    ]);
    print('Running: ${Platform.resolvedExecutable} ${arguments.join(' ')}');
    Process process = await Process.start(
        Platform.resolvedExecutable, arguments,
        mode: ProcessStartMode.inheritStdio);
    await process.exitCode;
  }
}
