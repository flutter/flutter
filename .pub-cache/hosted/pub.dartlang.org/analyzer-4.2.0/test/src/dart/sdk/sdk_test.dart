// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../embedder_tests.dart';
import '../../../resource_utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmbedderSdkTest);
    defineReflectiveTests(FolderBasedDartSdkTest);
    defineReflectiveTests(SdkLibrariesReaderTest);
  });
}

@reflectiveTest
class EmbedderSdkTest extends EmbedderRelatedTest {
  void test_allowedExperimentsJson() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    EmbedderSdk sdk = EmbedderSdk(
      resourceProvider,
      locator.embedderYamls,
      languageVersion: Version.parse('2.10.0'),
    );

    expect(sdk.allowedExperimentsJson, isNull);

    pathTranslator.newFile(
      '$foxLib/_internal/allowed_experiments.json',
      'foo bar',
    );
    expect(sdk.allowedExperimentsJson, 'foo bar');
  }

  void test_creation() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    EmbedderSdk sdk = EmbedderSdk(
      resourceProvider,
      locator.embedderYamls,
      languageVersion: Version.parse('2.10.0'),
    );

    expect(sdk.urlMappings, hasLength(5));
  }

  void test_fromFileUri() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    EmbedderSdk sdk = EmbedderSdk(
      resourceProvider,
      locator.embedderYamls,
      languageVersion: Version.parse('2.10.0'),
    );

    expectSource(String posixPath, String dartUri) {
      Uri uri = Uri.parse(posixToOSFileUri(posixPath));
      var source = sdk.fromFileUri(uri)!;
      expect(source, isNotNull, reason: posixPath);
      expect(source.uri.toString(), dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    expectSource('$foxLib/slippy.dart', 'dart:fox');
    expectSource('$foxLib/deep/directory/file.dart', 'dart:deep');
    expectSource('$foxLib/deep/directory/part.dart', 'dart:deep/part.dart');
  }

  void test_getSdkLibrary() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    EmbedderSdk sdk = EmbedderSdk(
      resourceProvider,
      locator.embedderYamls,
      languageVersion: Version.parse('2.10.0'),
    );

    var lib = sdk.getSdkLibrary('dart:fox')!;
    expect(lib, isNotNull);
    expect(lib.path, posixToOSPath('$foxLib/slippy.dart'));
    expect(lib.shortName, 'dart:fox');
  }

  void test_mapDartUri() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    EmbedderSdk sdk = EmbedderSdk(
      resourceProvider,
      locator.embedderYamls,
      languageVersion: Version.parse('2.10.0'),
    );

    void expectSource(String dartUri, String posixPath) {
      var source = sdk.mapDartUri(dartUri)!;
      expect(source, isNotNull, reason: posixPath);
      expect(source.uri.toString(), dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    expectSource('dart:core', '$foxLib/core/core.dart');
    expectSource('dart:fox', '$foxLib/slippy.dart');
    expectSource('dart:deep', '$foxLib/deep/directory/file.dart');
    expectSource('dart:deep/part.dart', '$foxLib/deep/directory/part.dart');
  }
}

@reflectiveTest
class FolderBasedDartSdkTest with ResourceProviderMixin {
  void test_creation() {
    FolderBasedDartSdk sdk = _createDartSdk();
    expect(sdk, isNotNull);
  }

  void test_fromFile_invalid() {
    FolderBasedDartSdk sdk = _createDartSdk();
    expect(sdk.fromFileUri(getFile("/not/in/the/sdk.dart").toUri()), isNull);
  }

  void test_fromFile_library() {
    FolderBasedDartSdk sdk = _createDartSdk();
    var source = sdk.fromFileUri(sdk.libraryDirectory
        .getChildAssumingFolder("core")
        .getChildAssumingFile("core.dart")
        .toUri())!;
    expect(source, isNotNull);
    expect(source.uri.toString(), "dart:core");
  }

  void test_fromFile_library_firstExact() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder dirHtml = sdk.libraryDirectory.getChildAssumingFolder("html");
    Folder dirDartium = dirHtml.getChildAssumingFolder("dart2js");
    File file = dirDartium.getChildAssumingFile("html_dart2js.dart");
    var source = sdk.fromFileUri(file.toUri())!;
    expect(source, isNotNull);
    expect(source.uri.toString(), "dart:html");
  }

  void test_fromFile_library_html_common_dart2js() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder dirHtml = sdk.libraryDirectory.getChildAssumingFolder("html");
    Folder dirCommon = dirHtml.getChildAssumingFolder("html_common");
    File file = dirCommon.getChildAssumingFile("html_common_dart2js.dart");
    var source = sdk.fromFileUri(file.toUri())!;
    expect(source, isNotNull);
    expect(source.uri.toString(), "dart:html_common");
  }

  void test_fromFile_part() {
    FolderBasedDartSdk sdk = _createDartSdk();
    var source = sdk.fromFileUri(sdk.libraryDirectory
        .getChildAssumingFolder("core")
        .getChildAssumingFile("num.dart")
        .toUri())!;
    expect(source, isNotNull);
    expect(source.uri.toString(), "dart:core/num.dart");
  }

  void test_getDirectory() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder directory = sdk.directory;
    expect(directory, isNotNull);
    expect(directory.exists, isTrue);
  }

  void test_getDocDirectory() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder directory = sdk.docDirectory;
    expect(directory, isNotNull);
  }

  void test_getLibraryDirectory() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder directory = sdk.libraryDirectory;
    expect(directory, isNotNull);
    expect(directory.exists, isTrue);
  }

  void test_getSdkVersion() {
    FolderBasedDartSdk sdk = _createDartSdk();
    String version = sdk.sdkVersion;
    expect(version, isNotNull);
    expect(version.isNotEmpty, isTrue);
  }

  /// The "part" format should result in the same source as the non-part format
  /// when the file is the library file.
  void test_mapDartUri_partFormatForLibrary() {
    FolderBasedDartSdk sdk = _createDartSdk();
    var normalSource = sdk.mapDartUri('dart:core')!;
    var partSource = sdk.mapDartUri('dart:core/core.dart')!;
    expect(partSource, normalSource);
  }

  FolderBasedDartSdk _createDartSdk() {
    Folder sdkDirectory = getFolder('/sdk');
    _createFile(sdkDirectory,
        ['lib', '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'],
        content: _librariesFileContent());
    _createFile(sdkDirectory, ['bin', 'dart']);
    _createFile(sdkDirectory, ['bin', 'dart2js']);
    _createFile(sdkDirectory, ['lib', 'async', 'async.dart']);
    _createFile(sdkDirectory, ['lib', 'core', 'core.dart']);
    _createFile(sdkDirectory, ['lib', 'core', 'num.dart']);
    _createFile(
        sdkDirectory, ['lib', 'html', 'html_common', 'html_common.dart']);
    _createFile(sdkDirectory,
        ['lib', 'html', 'html_common', 'html_common_dart2js.dart']);
    _createFile(sdkDirectory, ['lib', 'html', 'dart2js', 'html_dart2js.dart']);
    return FolderBasedDartSdk(resourceProvider, sdkDirectory);
  }

  void _createFile(Folder directory, List<String> segments,
      {String content = ''}) {
    Folder parent = directory;
    int last = segments.length - 1;
    for (int i = 0; i < last; i++) {
      parent = parent.getChildAssumingFolder(segments[i]);
    }
    File file = parent.getChildAssumingFile(segments[last]);
    newFile(file.path, content);
  }

  String _librariesFileContent() => '''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  "async": const LibraryInfo(
      "async/async.dart",
      categories: "Client,Server",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/js_runtime/lib/async_patch.dart"),

  "core": const LibraryInfo(
      "core/core.dart",
      categories: "Client,Server,Embedded",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/js_runtime/lib/core_patch.dart"),

  "html": const LibraryInfo(
      "html/dart2js/html_dart2js.dart",
      categories: "Client",
      maturity: Maturity.WEB_STABLE),

  "html_common": const LibraryInfo(
      "html/html_common/html_common.dart",
      categories: "Client",
      maturity: Maturity.WEB_STABLE,
      dart2jsPath: "html/html_common/html_common_dart2js.dart",
      documented: false,
      implementation: true),
};
''';
}

@reflectiveTest
class SdkLibrariesReaderTest with ResourceProviderMixin {
  void test_readFrom_empty() {
    LibraryMap libraryMap =
        SdkLibrariesReader().readFromFile(getFile("/libs.dart"), "");
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 0);
  }

  void test_readFrom_normal() {
    LibraryMap libraryMap =
        SdkLibrariesReader().readFromFile(getFile("/libs.dart"), r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    categories: 'Client',
    documented: true,
    platforms: VM_PLATFORM),

  'second' : const LibraryInfo(
    'second/second.dart',
    categories: 'Server',
    documented: false,
    implementation: true,
    platforms: 0),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 2);
    var first = libraryMap.getLibrary("dart:first")!;
    expect(first, isNotNull);
    expect(first.category, "Client");
    expect(first.path, "first/first.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
    var second = libraryMap.getLibrary("dart:second")!;
    expect(second, isNotNull);
    expect(second.category, "Server");
    expect(second.path, "second/second.dart");
    expect(second.shortName, "dart:second");
    expect(second.isDart2JsLibrary, false);
    expect(second.isDocumented, false);
    expect(second.isImplementation, true);
    expect(second.isVmLibrary, false);
  }
}
