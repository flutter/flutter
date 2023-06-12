// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvailableDeclarationsTest);
    defineReflectiveTests(ChangeFileTest);
    defineReflectiveTests(DartdocInfoTest);
    defineReflectiveTests(DeclarationTest);
    defineReflectiveTests(ExportTest);
    defineReflectiveTests(GetLibrariesTest);
  });
}

class AbstractContextTest with ResourceProviderMixin {
  final byteStore = MemoryByteStore();

  late AnalysisContextCollection analysisContextCollection;

  late AnalysisContext testAnalysisContext;

  /// The file system specific `/home/test/analysis_options.yaml` path.
  String get analysisOptionsPath =>
      convertPath('/home/test/analysis_options.yaml');

  Folder get sdkRoot => newFolder('/sdk');

  /// Create all analysis contexts in `/home`.
  void createAnalysisContexts() {
    createAnalysisContexts0('/home', '/home/test');
  }

  void createAnalysisContexts0(String rootPath, String testPath) {
    analysisContextCollection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath(rootPath)],
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );

    var testPath_ = convertPath(testPath);
    testAnalysisContext = getContext(testPath_);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({List<String>? experiments}) {
    var buffer = StringBuffer();
    if (experiments != null) {
      buffer.writeln('analyzer:');
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }
    newFile(analysisOptionsPath, buffer.toString());

    createAnalysisContexts();
  }

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext getContext(String path) {
    path = convertPath(path);
    return analysisContextCollection.contextFor(path);
  }

  setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    newFolder('/home/test');
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
    );

    createAnalysisContexts();
  }

  void writePackageConfig(
    String directoryPath,
    PackageConfigFileBuilder config,
  ) {
    newPackageConfigJsonFile(
      directoryPath,
      config.toContent(
        toUriStr: toUriStr,
      ),
    );
    createAnalysisContexts();
  }

  void writeTestPackageConfig(PackageConfigFileBuilder config) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: '/home/test',
    );

    writePackageConfig('/home/test', config);
  }
}

@reflectiveTest
class AvailableDeclarationsTest extends _Base {
  test_changesStream_noDuplicates() async {
    newFile('/home/aaa/lib/a.dart', 'class A {}');

    newPubspecYamlFile('/home/bbb', r'''
dependencies:
  aaa: any
''');
    writePackageConfig(
      '/home/bbb',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: '/home/aaa'),
    );
    newFile('/home/bbb/lib/b.dart', 'class B {}');

    newPubspecYamlFile('/home/ccc', r'''
dependencies:
  aaa: any
''');
    writePackageConfig(
      '/home/ccc',
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: '/home/aaa'),
    );
    newFile('/home/ccc/lib/c.dart', 'class C {}');

    createAnalysisContexts();

    var bPath = convertPath('/home/bbb');
    var cPath = convertPath('/home/ccc');

    var bAnalysisContext = analysisContextCollection.contextFor(bPath);
    var cAnalysisContext = analysisContextCollection.contextFor(cPath);

    tracker.addContext(bAnalysisContext);
    tracker.addContext(cAnalysisContext);
    await _doAllTrackerWork();

    var uniquePathSet = <String>{};
    for (var change in changes) {
      for (var library in change.changed) {
        if (!uniquePathSet.add(library.path)) {
          fail('Not unique path: ${library.path}');
        }
      }
    }
  }

  test_discardContexts() async {
    newFile('/home/test/lib/test.dart', r'''
class A {}
''');

    // No libraries initially.
    expect(uriToLibrary, isEmpty);

    // Add the context, and discard everything immediately.
    tracker.addContext(testAnalysisContext);
    tracker.discardContexts();

    // There is no context.
    expect(tracker.getContext(testAnalysisContext), isNull);

    // There is no work to do.
    expect(tracker.hasWork, isFalse);
    await _doAllTrackerWork();

    // So, there are no new libraries.
    expect(uriToLibrary, isEmpty);
  }

  test_getContext() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    var addContext = tracker.addContext(testAnalysisContext);
    expect(tracker.getContext(testAnalysisContext), same(addContext));
  }

  test_getLibrary() async {
    newFile('/home/test/lib/test.dart', r'''
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    var id = uriToLibrary['package:test/test.dart']!.id;
    var library = tracker.getLibrary(id)!;
    expect(library.id, id);
    expect(library.uriStr, 'package:test/test.dart');
  }

  test_getLibrary_export_notExisting() async {
    newFile('/home/test/lib/a.dart', r'''
export 'b.dart';
class A {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    var id = uriToLibrary['package:test/a.dart']!.id;
    var library = tracker.getLibrary(id)!;
    expect(library.id, id);
  }

  test_getLibrary_exportViaRecursiveLink() async {
    resourceProvider.newLink(
      convertPath('/home/test/lib/foo'),
      convertPath('/home/test/lib'),
    );

    newFile('/home/test/lib/a.dart', r'''
export 'foo/a.dart';
class A {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    var id = uriToLibrary['package:test/a.dart']!.id;
    var library = tracker.getLibrary(id)!;
    expect(library.id, id);
  }

  test_readByteStore() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
''');
    newFile('/home/test/lib/b.dart', r'''
class B {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart' show A;
part 'b.dart';
class C {}
enum E {v}
''');

    // The byte store is empty, fill it.
    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    // Re-create tracker, will read from byte store.
    _createTracker();
    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.enum_('E', [
        _ExpectedDeclaration.enumConstant('v'),
      ]),
    ]);
  }

  static Future pumpEventQueue([int times = 5000]) {
    if (times == 0) return Future.value();
    return Future.delayed(Duration.zero, () => pumpEventQueue(times - 1));
  }
}

@reflectiveTest
class ChangeFileTest extends _Base {
  disabled_test_updated_library_parted() async {
    // TODO(scheglov) Figure out why this fails on Windows.
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, r'''
class A {}
''');
    newFile(b, r'''
part 'a.dart';
class B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(a, r'''
class A2 {}
''');
    tracker.changeFile(a);
    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('A2', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_added_exported() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');
    var d = convertPath('/home/test/lib/d.dart');

    newFile(a, r'''
export 'b.dart';
class A {}
''');
    newFile(b, r'''
export 'c.dart';
class B {}
''');
    newFile(d, r'''
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:test/c.dart');
    _assertHasLibrary('package:test/d.dart', declarations: [
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(c, r'''
class C {}
''');
    tracker.changeFile(c);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/d.dart', declarations: [
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_added_library() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, r'''
class A {}
''');
    var declarationsContext = tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:test/b.dart');

    newFile(b, r'''
class B {}
''');
    tracker.changeFile(b);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    var librariesObject = declarationsContext.getLibraries(
      '/home/test/lib/test.dart',
    );
    expect(
      librariesObject.context.map((library) => library.uriStr).toSet(),
      containsAll(['package:test/a.dart', 'package:test/b.dart']),
    );
  }

  test_added_part() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    newFile(a, r'''
part 'b.dart';
class A {}
''');
    newFile(c, r'''
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:test/b.dart');
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(b, r'''
part of 'a.dart';
class B {}
''');
    tracker.changeFile(b);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:test/b.dart');
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_added_part_withoutLibrary() async {
    var b = convertPath('/home/test/lib/b.dart');

    newFile(b, r'''
part of 'a.dart';
''');
    tracker.changeFile(b);
    await _doAllTrackerWork();

    _assertHasNoLibrary('package:test/a.dart');
    _assertHasNoLibrary('package:test/b.dart');
  }

  test_chooseContext_inAnalysisRoot() async {
    var homePath = convertPath('/home');
    var testPath = convertPath('/home/test');
    var filePath = convertPath('/home/test/lib/test.dart');

    var homeContext = analysisContextCollection.contextFor(homePath);
    var testContext = analysisContextCollection.contextFor(testPath);

    tracker.addContext(homeContext);
    tracker.addContext(testContext);
    await _doAllTrackerWork();

    newFile(filePath, 'class A {}');
    uriToLibrary.clear();
    tracker.changeFile(filePath);
    await _doAllTrackerWork();

    _assertDeclaration(
      _getDeclaration(
        _getLibrary('package:test/test.dart').declarations,
        'A',
      ),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::A'],
    );

    newFile(filePath, 'class B {}');
    uriToLibrary.clear();
    tracker.changeFile(filePath);
    await _doAllTrackerWork();

    _assertDeclaration(
      _getDeclaration(
        _getLibrary('package:test/test.dart').declarations,
        'B',
      ),
      'B',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::B'],
    );
  }

  test_chooseContext_inPackage() async {
    var homePath = convertPath('/home');
    var testPath = convertPath('/home/test');
    var filePath = convertPath('/packages/aaa/lib/a.dart');

    newPubspecYamlFile('/home/test', r'''
name: test
dependencies:
  aaa: any
''');
    writeTestPackageConfig(
      PackageConfigFileBuilder()..add(name: 'aaa', rootPath: '/packages/aaa'),
    );

    var homeContext = analysisContextCollection.contextFor(homePath);
    var testContext = analysisContextCollection.contextFor(testPath);

    tracker.addContext(homeContext);
    tracker.addContext(testContext);
    await _doAllTrackerWork();

    newFile(filePath, 'class A {}');
    uriToLibrary.clear();
    tracker.changeFile(filePath);
    await _doAllTrackerWork();

    _assertDeclaration(
      _getDeclaration(
        _getLibrary('package:aaa/a.dart').declarations,
        'A',
      ),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:aaa/a.dart::A'],
    );

    newFile(filePath, 'class B {}');
    uriToLibrary.clear();
    tracker.changeFile(filePath);
    await _doAllTrackerWork();

    _assertDeclaration(
      _getDeclaration(
        _getLibrary('package:aaa/a.dart').declarations,
        'B',
      ),
      'B',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:aaa/a.dart::B'],
    );
  }

  test_chooseContext_inSdk() async {
    var filePath = convertPath('/sdk/lib/math/math.dart');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    newFile(filePath, 'class A {}');
    uriToLibrary.clear();
    tracker.changeFile(filePath);
    await _doAllTrackerWork();

    _assertDeclaration(
      _getDeclaration(
        _getLibrary('dart:math').declarations,
        'A',
      ),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'dart:math::A'],
    );

    newFile(filePath, 'class B {}');
    uriToLibrary.clear();
    tracker.changeFile(filePath);
    await _doAllTrackerWork();

    _assertDeclaration(
      _getDeclaration(
        _getLibrary('dart:math').declarations,
        'B',
      ),
      'B',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'dart:math::B'],
    );
  }

  test_deleted_exported() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');
    var d = convertPath('/home/test/lib/d.dart');

    newFile(a, r'''
export 'b.dart';
class A {}
''');
    newFile(b, r'''
export 'c.dart';
class B {}
''');
    newFile(c, r'''
class C {}
''');
    newFile(d, r'''
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/d.dart', declarations: [
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    deleteFile(c);
    tracker.changeFile(c);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:test/c.dart');
    _assertHasLibrary('package:test/d.dart', declarations: [
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_deleted_library() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, '');
    newFile(b, '');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart');
    _assertHasLibrary('package:test/b.dart');

    deleteFile(a);
    tracker.changeFile(a);
    await _doAllTrackerWork();

    _assertHasNoLibrary('package:test/a.dart');
    _assertHasLibrary('package:test/b.dart');
  }

  test_deleted_library_ofPart() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, r'''
part 'b.dart';
''');
    newFile(b, r'''
part of 'a.dart';
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart');
    _assertHasNoLibrary('package:test/b.dart');

    deleteFile(a);
    tracker.changeFile(a);
    await _doAllTrackerWork();

    _assertHasNoLibrary('package:test/a.dart');
    _assertHasNoLibrary('package:test/b.dart');
  }

  test_deleted_part() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    newFile(a, r'''
part 'b.dart';
class A {}
''');
    newFile(b, r'''
part of 'a.dart';
class B {}
''');
    newFile(c, r'''
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    deleteFile(b);
    tracker.changeFile(b);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_deleted_part_withoutLibrary() async {
    var b = convertPath('/home/test/lib/b.dart');

    newFile(b, r'''
part of 'a.dart';
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');
    _assertHasNoLibrary('package:test/b.dart');
  }

  test_updated_exported() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');
    var d = convertPath('/home/test/lib/d.dart');

    newFile(a, r'''
export 'b.dart';
class A {}
''');
    newFile(b, r'''
export 'c.dart';
class B {}
''');
    newFile(c, r'''
class C {}
''');
    newFile(d, r'''
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/d.dart', declarations: [
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(c, r'''
class C2 {}
''');
    tracker.changeFile(c);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/d.dart', declarations: [
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  /// https://github.com/dart-lang/sdk/issues/47804
  test_updated_exported2() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    newFile(a, r'''
class A {}
''');
    newFile(b, r'''
class B {}
''');
    newFile(c, r'''
export 'a.dart';
export 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    changes.clear();

    newFile(a, r'''
class A2 {}
''');
    newFile(b, r'''
class B2 {}
''');
    tracker.changeFile(a);
    tracker.changeFile(b);
    await _doAllTrackerWork();

    // In general it is OK to get duplicate libraries.
    // But here we notified about both `a.dart` and `b.dart` changes before
    // performing any work. So, there is no reason do handle `c.dart` twice.
    var uniquePathSet = <String>{};
    for (var change in changes) {
      for (var library in change.changed) {
        if (!uniquePathSet.add(library.path)) {
          fail('Not unique path: ${library.path}');
        }
      }
    }

    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('A2', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B2', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_updated_library() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, r'''
class A {}
''');
    newFile(b, r'''
class B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(a, r'''
class A2 {}
''');
    tracker.changeFile(a);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  /// https://github.com/dart-lang/sdk/issues/44353
  test_updated_library_hasPart() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, r'''
part 'b.dart';
class A {}
''');
    newFile(b, r'''
part of 'a.dart';
class B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    var library = _getLibrary('package:test/a.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/a.dart::A'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/a.dart::B'],
    );

    newFile(a, r'''
part 'b.dart';
class A2 {}
''');
    tracker.changeFile(a);
    await _doAllTrackerWork();

    // We should not get duplicate relevance tags, specifically in the part.
    library = _getLibrary('package:test/a.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A2'),
      'A2',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/a.dart::A2'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/a.dart::B'],
    );
  }

  test_updated_library_to_part() async {
    var a = convertPath('/home/test/lib/a.dart');

    newFile(a, r'''
class A {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(a, r'''
part of nothing;
class A {}
''');
    tracker.changeFile(a);
    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');

    newFile(a, r'''
class A2 {}
''');
    tracker.changeFile(a);
    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_updated_part() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    newFile(a, r'''
part 'b.dart';
class A {}
''');
    newFile(b, r'''
part of 'a.dart';
class B {}
''');
    newFile(c, r'''
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(b, r'''
part of 'a.dart';
class B2 {}
''');
    tracker.changeFile(b);
    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_updated_part_exported() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    newFile(a, r'''
part of unknown;
class A {}
''');
    newFile(b, r'''
export 'a.dart';
class B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    newFile(a, r'''
part of unknown;
class A2 {}
''');
    tracker.changeFile(a);
    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');
    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_updated_part_withoutLibrary() async {
    var b = convertPath('/home/test/lib/b.dart');

    newFile(b, r'''
part of 'a.dart';
class B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');
    _assertHasNoLibrary('package:test/b.dart');

    newFile(b, r'''
part of 'a.dart';
class B2 {}
''');
    tracker.changeFile(b);

    await _doAllTrackerWork();
    _assertHasNoLibrary('package:test/a.dart');
    _assertHasNoLibrary('package:test/b.dart');
  }
}

@reflectiveTest
class DartdocInfoTest extends _Base {
  test_samePackage() async {
    File file = newFile('/home/aaa/lib/definition.dart', '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
class A {}
''');

    createAnalysisContexts();

    var context = analysisContextCollection.contextFor(file.path);

    tracker.addContext(context);
    await _doAllTrackerWork();

    var declarationsContext = tracker.getContext(context)!;
    var result = declarationsContext.dartdocDirectiveInfo.processDartdoc('''
/// Before macro.
/// {@macro foo}
/// After macro.''');
    expect(result.full, '''
Before macro.
Body of the template.
After macro.''');
  }
}

@reflectiveTest
class DeclarationTest extends _Base {
  test_CLASS() async {
    newFile('/home/test/lib/test.dart', r'''
class A {}

abstract class B {}

@deprecated
class C {}

/// aaa
///
/// bbb bbb
/// ccc ccc
class D {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::A'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.CLASS,
      isAbstract: true,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::B'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.CLASS,
      isDeprecated: true,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::C'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'D'),
      'D',
      DeclarationKind.CLASS,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb\nccc ccc',
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::D'],
    );
  }

  test_class_FIELD() async {
    newFile('/home/test/lib/test.dart', r'''
class C {
  static int f1 = 0;

  static final int f2 = 0;

  static const int f3 = 0;

  int f4 = 0;

  final int f5 = 0;

  @deprecated
  int f6 = 0;

  @deprecated
  final int f7 = 0;

  /// aaa
  ///
  /// bbb bbb
  int f8 = 0;
}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    var classDeclaration = _getDeclaration(library.declarations, 'C');

    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f1'),
      'f1',
      DeclarationKind.FIELD,
      isStatic: true,
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f2'),
      'f2',
      DeclarationKind.FIELD,
      isFinal: true,
      isStatic: true,
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f3'),
      'f3',
      DeclarationKind.FIELD,
      isConst: true,
      isStatic: true,
      relevanceTags: [
        'ElementKind.FIELD',
        'ElementKind.FIELD+const',
        'dart:core::int',
      ],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f4'),
      'f4',
      DeclarationKind.FIELD,
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f5'),
      'f5',
      DeclarationKind.FIELD,
      isFinal: true,
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f6'),
      'f6',
      DeclarationKind.FIELD,
      isDeprecated: true,
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f7'),
      'f7',
      DeclarationKind.FIELD,
      isDeprecated: true,
      isFinal: true,
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'f8'),
      'f8',
      DeclarationKind.FIELD,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: ['ElementKind.FIELD', 'dart:core::int'],
      returnType: 'int',
    );
  }

  test_class_GETTER() async {
    newFile('/home/test/lib/test.dart', r'''
class C {
  static int get g1 => 0;

  int get g2 => 0;

  @deprecated
  int get g3 => 0;

  /// aaa
  ///
  /// bbb bbb
  int get g4 => 0;
}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    var classDeclaration = _getDeclaration(library.declarations, 'C');

    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'g1'),
      'g1',
      DeclarationKind.GETTER,
      isStatic: true,
      relevanceTags: ['ElementKind.FIELD'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'g2'),
      'g2',
      DeclarationKind.GETTER,
      relevanceTags: ['ElementKind.FIELD'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'g3'),
      'g3',
      DeclarationKind.GETTER,
      isDeprecated: true,
      relevanceTags: ['ElementKind.FIELD'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'g4'),
      'g4',
      DeclarationKind.GETTER,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: ['ElementKind.FIELD'],
      returnType: 'int',
    );
  }

  test_class_METHOD() async {
    newFile('/home/test/lib/test.dart', r'''
class C {
  static void m1() {}

  void m2() {}

  void m3(int a) {}

  @deprecated
  void m4() {}

  /// aaa
  ///
  /// bbb bbb
  void m5() {}
}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    var classDeclaration = _getDeclaration(library.declarations, 'C');

    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'm1'),
      'm1',
      DeclarationKind.METHOD,
      isStatic: true,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.METHOD'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'm2'),
      'm2',
      DeclarationKind.METHOD,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.METHOD'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'm3'),
      'm3',
      DeclarationKind.METHOD,
      defaultArgumentListString: 'a',
      defaultArgumentListTextRanges: [0, 1],
      parameters: '(int a)',
      parameterNames: ['a'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.METHOD'],
      requiredParameterCount: 1,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'm4'),
      'm4',
      DeclarationKind.METHOD,
      isDeprecated: true,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.METHOD'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'm5'),
      'm5',
      DeclarationKind.METHOD,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.METHOD'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
  }

  test_class_SETTER() async {
    newFile('/home/test/lib/test.dart', r'''
class C {
  static set s1(int value) {}

  set s2(int value) {}

  @deprecated
  set s3(int value) {}

  /// aaa
  ///
  /// bbb bbb
  set s4(int value) {}
}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    var classDeclaration = _getDeclaration(library.declarations, 'C');

    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 's1'),
      's1',
      DeclarationKind.SETTER,
      isStatic: true,
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FIELD'],
      requiredParameterCount: 1,
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 's2'),
      's2',
      DeclarationKind.SETTER,
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FIELD'],
      requiredParameterCount: 1,
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 's3'),
      's3',
      DeclarationKind.SETTER,
      isDeprecated: true,
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FIELD'],
      requiredParameterCount: 1,
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 's4'),
      's4',
      DeclarationKind.SETTER,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FIELD'],
      requiredParameterCount: 1,
    );
  }

  test_CLASS_TYPE_ALIAS() async {
    newFile('/home/test/lib/test.dart', r'''
mixin M {}

class A = Object with M;

@deprecated
class B = Object with M;

/// aaa
///
/// bbb bbb
class C = Object with M;
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.CLASS_TYPE_ALIAS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::A'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.CLASS_TYPE_ALIAS,
      isDeprecated: true,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::B'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.CLASS_TYPE_ALIAS,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::C'],
    );
  }

  test_CONSTRUCTOR() async {
    newFile('/home/test/lib/test.dart', r'''
class C {
  int f1;
  int f2;

  C() {}

  C.a() {}

  @deprecated
  C.b() {}

  /// aaa
  ///
  /// bbb bbb
  C.c() {}

  C.d(Map<String, int> p1, int p2, {double p3}) {}

  C.e(this.f1, this.f2) {}
}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    var classDeclaration = _getDeclaration(library.declarations, 'C');

    _assertDeclaration(
      _getDeclaration(classDeclaration.children, ''),
      '',
      DeclarationKind.CONSTRUCTOR,
      parameterNames: [],
      parameters: '()',
      parameterTypes: [],
      relevanceTags: ['ElementKind.CONSTRUCTOR', 'package:test/test.dart::C'],
      requiredParameterCount: 0,
      returnType: 'C',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'a'),
      'a',
      DeclarationKind.CONSTRUCTOR,
      parameterNames: [],
      parameters: '()',
      parameterTypes: [],
      relevanceTags: ['ElementKind.CONSTRUCTOR', 'package:test/test.dart::C'],
      requiredParameterCount: 0,
      returnType: 'C',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'b'),
      'b',
      DeclarationKind.CONSTRUCTOR,
      isDeprecated: true,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.CONSTRUCTOR', 'package:test/test.dart::C'],
      requiredParameterCount: 0,
      returnType: 'C',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'c'),
      'c',
      DeclarationKind.CONSTRUCTOR,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.CONSTRUCTOR', 'package:test/test.dart::C'],
      requiredParameterCount: 0,
      returnType: 'C',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'd'),
      'd',
      DeclarationKind.CONSTRUCTOR,
      defaultArgumentListString: 'p1, p2',
      defaultArgumentListTextRanges: [0, 2, 4, 2],
      parameters: '(Map<String, int> p1, int p2, {double p3})',
      parameterNames: ['p1', 'p2', 'p3'],
      parameterTypes: ['Map<String, int>', 'int', 'double'],
      relevanceTags: ['ElementKind.CONSTRUCTOR', 'package:test/test.dart::C'],
      requiredParameterCount: 2,
      returnType: 'C',
    );
    _assertDeclaration(
      _getDeclaration(classDeclaration.children, 'e'),
      'e',
      DeclarationKind.CONSTRUCTOR,
      defaultArgumentListString: 'f1, f2',
      defaultArgumentListTextRanges: [0, 2, 4, 2],
      parameters: '(this.f1, this.f2)',
      parameterNames: ['f1', 'f2'],
      parameterTypes: ['', ''],
      relevanceTags: ['ElementKind.CONSTRUCTOR', 'package:test/test.dart::C'],
      requiredParameterCount: 2,
      returnType: 'C',
    );
  }

  test_ENUM() async {
    newFile('/home/test/lib/test.dart', r'''
enum A {v}

@deprecated
enum B {v}

/// aaa
///
/// bbb bbb
enum C {v}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.ENUM,
      relevanceTags: ['ElementKind.ENUM', 'package:test/test.dart::A'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.ENUM,
      isDeprecated: true,
      relevanceTags: ['ElementKind.ENUM', 'package:test/test.dart::B'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.ENUM,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: ['ElementKind.ENUM', 'package:test/test.dart::C'],
    );
  }

  test_ENUM_CONSTANT() async {
    newFile('/home/test/lib/test.dart', r'''
enum MyEnum {
  a,

  @deprecated
  b,

  /// aaa
  ///
  /// bbb bbb
  c
}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    var enumDeclaration = _getDeclaration(library.declarations, 'MyEnum');

    _assertDeclaration(
      _getDeclaration(enumDeclaration.children, 'a'),
      'a',
      DeclarationKind.ENUM_CONSTANT,
      relevanceTags: [
        'ElementKind.ENUM_CONSTANT',
        'ElementKind.ENUM_CONSTANT+const',
        'package:test/test.dart::MyEnum'
      ],
    );
    _assertDeclaration(
      _getDeclaration(enumDeclaration.children, 'b'),
      'b',
      DeclarationKind.ENUM_CONSTANT,
      isDeprecated: true,
      relevanceTags: [
        'ElementKind.ENUM_CONSTANT',
        'ElementKind.ENUM_CONSTANT+const',
        'package:test/test.dart::MyEnum'
      ],
    );
    _assertDeclaration(
      _getDeclaration(enumDeclaration.children, 'c'),
      'c',
      DeclarationKind.ENUM_CONSTANT,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: [
        'ElementKind.ENUM_CONSTANT',
        'ElementKind.ENUM_CONSTANT+const',
        'package:test/test.dart::MyEnum'
      ],
    );
  }

  test_EXTENSION() async {
    createAnalysisOptionsFile(experiments: [EnableString.extension_methods]);
    newFile('/home/test/lib/test.dart', r'''
extension A on String {}

extension on String {}

@deprecated
extension B on String {}

/// aaa
///
/// bbb bbb
/// ccc ccc
extension C on String {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.EXTENSION,
      relevanceTags: ['ElementKind.EXTENSION'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.EXTENSION,
      isDeprecated: true,
      relevanceTags: ['ElementKind.EXTENSION'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.EXTENSION,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb\nccc ccc',
      relevanceTags: ['ElementKind.EXTENSION'],
    );
  }

  test_FUNCTION() async {
    newFile('/home/test/lib/test.dart', r'''
void a() {}

@deprecated
void b() {}

/// aaa
///
/// bbb bbb
void c() {}

List<String> d(Map<String, int> p1, int p2, {double p3}) {}

void e<T extends num, U>() {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'a'),
      'a',
      DeclarationKind.FUNCTION,
      parameterNames: [],
      parameters: '()',
      parameterTypes: [],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'b'),
      'b',
      DeclarationKind.FUNCTION,
      isDeprecated: true,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'c'),
      'c',
      DeclarationKind.FUNCTION,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'd'),
      'd',
      DeclarationKind.FUNCTION,
      defaultArgumentListString: 'p1, p2',
      defaultArgumentListTextRanges: [0, 2, 4, 2],
      parameters: '(Map<String, int> p1, int p2, {double p3})',
      parameterNames: ['p1', 'p2', 'p3'],
      parameterTypes: ['Map<String, int>', 'int', 'double'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 2,
      returnType: 'List<String>',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'e'),
      'e',
      DeclarationKind.FUNCTION,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 0,
      returnType: 'void',
      typeParameters: '<T extends num, U>',
    );
  }

  test_FUNCTION_defaultArgumentList() async {
    newFile('/home/test/lib/test.dart', r'''
void a() {}

void b(int a, double bb, String ccc) {}

void c(int a, [double b, String c]) {}

void d(int a, {int b, @required int c, @required int d, int e}) {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'a'),
      'a',
      DeclarationKind.FUNCTION,
      parameterNames: [],
      parameters: '()',
      parameterTypes: [],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'b'),
      'b',
      DeclarationKind.FUNCTION,
      defaultArgumentListString: 'a, bb, ccc',
      defaultArgumentListTextRanges: [0, 1, 3, 2, 7, 3],
      parameters: '(int a, double bb, String ccc)',
      parameterNames: ['a', 'bb', 'ccc'],
      parameterTypes: ['int', 'double', 'String'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 3,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'c'),
      'c',
      DeclarationKind.FUNCTION,
      defaultArgumentListString: 'a',
      defaultArgumentListTextRanges: [0, 1],
      parameters: '(int a, [double b, String c])',
      parameterNames: ['a', 'b', 'c'],
      parameterTypes: ['int', 'double', 'String'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 1,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'd'),
      'd',
      DeclarationKind.FUNCTION,
      defaultArgumentListString: 'a, c: c, d: d',
      defaultArgumentListTextRanges: [0, 1, 6, 1, 12, 1],
      parameters: '(int a, {int b, @required int c, @required int d, int e})',
      parameterNames: ['a', 'b', 'c', 'd', 'e'],
      parameterTypes: ['int', 'int', 'int', 'int', 'int'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 1,
      returnType: 'void',
    );
  }

  test_FUNCTION_TYPE_ALIAS() async {
    newFile('/home/test/lib/test.dart', r'''
typedef A = void Function();

@deprecated
typedef B = void Function();

/// aaa
///
/// bbb bbb
typedef C = void Function();

typedef D = int Function(int p1, [double p2, String p3]);

typedef E = void Function(int, double, {String p3});

typedef F = void Function<T extends num, U>();
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::A'
      ],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      isDeprecated: true,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::B'
      ],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::C'
      ],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'D'),
      'D',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '(int p1, [double p2, String p3])',
      parameterNames: ['p1', 'p2', 'p3'],
      parameterTypes: ['int', 'double', 'String'],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::D'
      ],
      requiredParameterCount: 1,
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'E'),
      'E',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '(int, double, {String p3})',
      parameterNames: ['', '', 'p3'],
      parameterTypes: ['int', 'double', 'String'],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::E'
      ],
      requiredParameterCount: 2,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'F'),
      'F',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      requiredParameterCount: 0,
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::F'
      ],
      returnType: 'void',
      typeParameters: '<T extends num, U>',
    );
  }

  test_FUNCTION_TYPE_ALIAS_noFunction() async {
    newFile('/home/test/lib/test.dart', r'''
typedef A = ;
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertNoDeclaration(library, 'A');
  }

  test_FUNCTION_TYPE_ALIAS_old() async {
    newFile('/home/test/lib/test.dart', r'''
typedef void A();

@deprecated
typedef void B();

/// aaa
///
/// bbb bbb
typedef void C();

typedef int D(int p1, [double p2, String p3]);

typedef void E(int p1, double p2, {String p3});

typedef void F<T extends num, U>();
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::A'
      ],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      isDeprecated: true,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::B'
      ],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::C'
      ],
      requiredParameterCount: 0,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'D'),
      'D',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '(int p1, [double p2, String p3])',
      parameterNames: ['p1', 'p2', 'p3'],
      parameterTypes: ['int', 'double', 'String'],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::D'
      ],
      requiredParameterCount: 1,
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'E'),
      'E',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '(int p1, double p2, {String p3})',
      parameterNames: ['p1', 'p2', 'p3'],
      parameterTypes: ['int', 'double', 'String'],
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::E'
      ],
      requiredParameterCount: 2,
      returnType: 'void',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'F'),
      'F',
      DeclarationKind.FUNCTION_TYPE_ALIAS,
      parameters: '()',
      parameterNames: [],
      parameterTypes: [],
      requiredParameterCount: 0,
      relevanceTags: [
        'ElementKind.FUNCTION_TYPE_ALIAS',
        'package:test/test.dart::F'
      ],
      returnType: 'void',
      typeParameters: '<T extends num, U>',
    );
  }

  test_GETTER() async {
    newFile('/home/test/lib/test.dart', r'''
int get a => 0;

@deprecated
int get b => 0;

/// aaa
///
/// bbb bbb
int get c => 0;
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'a'),
      'a',
      DeclarationKind.GETTER,
      relevanceTags: ['ElementKind.FUNCTION'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'b'),
      'b',
      DeclarationKind.GETTER,
      isDeprecated: true,
      relevanceTags: ['ElementKind.FUNCTION'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'c'),
      'c',
      DeclarationKind.GETTER,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: ['ElementKind.FUNCTION'],
      returnType: 'int',
    );
  }

  test_library_isDeprecated() async {
    newFile('/home/test/lib/a.dart', '');
    newFile('/home/test/lib/b.dart', r'''
@deprecated
library my.lib;
''');
    newFile('/home/test/lib/c.dart', r'''
@Deprecated('description')
library my.lib;
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    expect(uriToLibrary['package:test/a.dart']!.isDeprecated, isFalse);
    expect(uriToLibrary['package:test/b.dart']!.isDeprecated, isTrue);
    expect(uriToLibrary['package:test/c.dart']!.isDeprecated, isTrue);
  }

  test_library_partDirective_empty() async {
    newFile('/home/test/lib/test.dart', r'''
part ' ';

class A {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::A'],
    );
  }

  test_library_partDirective_incomplete() async {
    newFile('/home/test/lib/test.dart', r'''
part

class A {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.CLASS,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::A'],
    );
  }

  test_library_parts() async {
    newFile('/home/test/lib/a.dart', r'''
part of 'test.dart';
class A {}
''');
    newFile('/home/test/lib/b.dart', r'''
part of 'test.dart';
class B {}
''');
    newFile('/home/test/lib/test.dart', r'''
part 'a.dart';
part 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_library_publicOnly() async {
    newFile('/home/test/lib/a.dart', r'''
part of 'test.dart';
class A {}
class _A {}
''');
    newFile('/home/test/lib/test.dart', r'''
part 'a.dart';
class B {}
class _B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_library_publicOnly_enum() async {
    newFile('/home/test/lib/a.dart', r'''
part of 'test.dart';
enum A {a, _a}
enum _A {a, _a}
''');
    newFile('/home/test/lib/test.dart', r'''
part 'a.dart';
enum B {b, _b}
enum _B {b, _b}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.enum_('A', [
        _ExpectedDeclaration.enumConstant('a'),
      ]),
      _ExpectedDeclaration.enum_('B', [
        _ExpectedDeclaration.enumConstant('b'),
      ]),
    ]);
  }

  test_location() async {
    var code = r'''
class A {}

class B {}
''';
    var testPath = newFile('/home/test/lib/test.dart', code).path;

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.CLASS,
      locationOffset: code.indexOf('A {}'),
      locationPath: testPath,
      locationStartColumn: 7,
      locationStartLine: 1,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::A'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.CLASS,
      locationOffset: code.indexOf('B {}'),
      locationPath: testPath,
      locationStartColumn: 7,
      locationStartLine: 3,
      relevanceTags: ['ElementKind.CLASS', 'package:test/test.dart::B'],
    );
  }

  test_MIXIN() async {
    newFile('/home/test/lib/test.dart', r'''
mixin A {}

@deprecated
mixin B {}

/// aaa
///
/// bbb bbb
/// ccc ccc
mixin C {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.MIXIN,
      relevanceTags: ['ElementKind.MIXIN', 'package:test/test.dart::A'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.MIXIN,
      isDeprecated: true,
      relevanceTags: ['ElementKind.MIXIN', 'package:test/test.dart::B'],
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.MIXIN,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb\nccc ccc',
      relevanceTags: ['ElementKind.MIXIN', 'package:test/test.dart::C'],
    );
  }

  test_SETTER() async {
    newFile('/home/test/lib/test.dart', r'''
set a(int value) {}

@deprecated
set b(int value) {}

/// aaa
///
/// bbb bbb
set c(int value) {}
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'a'),
      'a',
      DeclarationKind.SETTER,
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 1,
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'b'),
      'b',
      DeclarationKind.SETTER,
      isDeprecated: true,
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 1,
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'c'),
      'c',
      DeclarationKind.SETTER,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: '(int value)',
      parameterNames: ['value'],
      parameterTypes: ['int'],
      relevanceTags: ['ElementKind.FUNCTION'],
      requiredParameterCount: 1,
    );
  }

  test_TYPE_ALIAS() async {
    newFile('/home/test/lib/test.dart', r'''
typedef A = double;

@deprecated
typedef B = double;

/// aaa
///
/// bbb bbb
typedef C = double;
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'A'),
      'A',
      DeclarationKind.TYPE_ALIAS,
      parameters: null,
      parameterNames: null,
      parameterTypes: null,
      relevanceTags: ['ElementKind.TYPE_ALIAS', 'package:test/test.dart::A'],
      requiredParameterCount: null,
      returnType: null,
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'B'),
      'B',
      DeclarationKind.TYPE_ALIAS,
      isDeprecated: true,
      parameters: null,
      parameterNames: null,
      parameterTypes: null,
      relevanceTags: ['ElementKind.TYPE_ALIAS', 'package:test/test.dart::B'],
      requiredParameterCount: null,
      returnType: null,
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'C'),
      'C',
      DeclarationKind.TYPE_ALIAS,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      parameters: null,
      parameterNames: null,
      parameterTypes: null,
      relevanceTags: ['ElementKind.TYPE_ALIAS', 'package:test/test.dart::C'],
      requiredParameterCount: null,
      returnType: null,
    );
  }

  test_VARIABLE() async {
    newFile('/home/test/lib/test.dart', r'''
int a;

@deprecated
int b;

/// aaa
///
/// bbb bbb
int c;

const d = 0;

final double e = 2.7;
''');

    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var library = _getLibrary('package:test/test.dart');
    _assertDeclaration(
      _getDeclaration(library.declarations, 'a'),
      'a',
      DeclarationKind.VARIABLE,
      relevanceTags: ['ElementKind.TOP_LEVEL_VARIABLE'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'b'),
      'b',
      DeclarationKind.VARIABLE,
      isDeprecated: true,
      relevanceTags: ['ElementKind.TOP_LEVEL_VARIABLE'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'c'),
      'c',
      DeclarationKind.VARIABLE,
      docSummary: 'aaa',
      docComplete: 'aaa\n\nbbb bbb',
      relevanceTags: ['ElementKind.TOP_LEVEL_VARIABLE'],
      returnType: 'int',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'd'),
      'd',
      DeclarationKind.VARIABLE,
      isConst: true,
      relevanceTags: [
        'ElementKind.TOP_LEVEL_VARIABLE',
        'ElementKind.TOP_LEVEL_VARIABLE+const',
        'dart:core::int',
      ],
      returnType: '',
    );
    _assertDeclaration(
      _getDeclaration(library.declarations, 'e'),
      'e',
      DeclarationKind.VARIABLE,
      isFinal: true,
      relevanceTags: ['ElementKind.TOP_LEVEL_VARIABLE', 'dart:core::double'],
      returnType: 'double',
    );
  }
}

@reflectiveTest
class ExportTest extends _Base {
  test_classTypeAlias() async {
    newFile('/home/test/lib/test.dart', r'''
mixin M {}
class A = Object with M;
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.mixin('M'),
      _ExpectedDeclaration.classTypeAlias('A'),
    ]);
  }

  test_combinators_hide() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
class B {}
class C {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart' hide B;
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_combinators_show() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
class B {}
class C {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart' show B;
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('D', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_combinators_show_enum() async {
    newFile('/home/test/lib/a.dart', r'''
enum E1 {a}
enum E2 {b}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart' show E1;
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.enum_('E1', [
        _ExpectedDeclaration.enumConstant('a'),
      ]),
    ]);
  }

  test_cycle() async {
    newFile('/home/test/lib/a.dart', r'''
export 'b.dart';
class A {}
''');
    newFile('/home/test/lib/b.dart', r'''
export 'a.dart';
class B {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_enum() async {
    newFile('/home/test/lib/test.dart', r'''
enum E1 {a, b}
enum E2 {a, b}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.enum_('E1', [
        _ExpectedDeclaration.enumConstant('a'),
        _ExpectedDeclaration.enumConstant('b'),
      ]),
      _ExpectedDeclaration.enum_('E2', [
        _ExpectedDeclaration.enumConstant('a'),
        _ExpectedDeclaration.enumConstant('b'),
      ]),
    ]);
  }

  test_function() async {
    newFile('/home/test/lib/test.dart', r'''
int foo() => 0;
int bar() => 0;
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.function('foo'),
      _ExpectedDeclaration.function('bar'),
    ]);
  }

  test_functionTypeAlias() async {
    newFile('/home/test/lib/test.dart', r'''
typedef F = int Function();
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.functionTypeAlias('F'),
    ]);
  }

  test_missing() async {
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_sequence() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
''');
    newFile('/home/test/lib/b.dart', r'''
export 'a.dart';
class B {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    _assertHasLibrary('package:test/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    _assertHasLibrary('package:test/b.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_shadowedByLocal() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart';

mixin B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.mixin('B'),
    ]);
  }

  test_simple() async {
    newFile('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    newFile('/home/test/lib/test.dart', r'''
export 'a.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
  }

  test_variable() async {
    newFile('/home/test/lib/test.dart', r'''
int foo = 0;
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertHasLibrary('package:test/test.dart', declarations: [
      _ExpectedDeclaration.variable('foo'),
    ]);
  }
}

@reflectiveTest
class GetLibrariesTest extends _Base {
  test_excludeSelf() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    newFile(a, '');
    newFile(b, '');
    newFile(c, '');

    var context = tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var aList = _uriListOfContextLibraries(context, a);
    expect(
      aList,
      unorderedEquals([
        'package:test/b.dart',
        'package:test/c.dart',
      ]),
    );

    var bList = _uriListOfContextLibraries(context, b);
    expect(
      bList,
      unorderedEquals([
        'package:test/a.dart',
        'package:test/c.dart',
      ]),
    );
  }

  test_excludeSelf_part() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    newFile(a, r'''
part 'b.dart';
''');
    newFile(b, r'''
part of 'a.dart';
''');
    newFile(c, '');

    var context = tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var aList = _uriListOfContextLibraries(context, a);
    expect(aList, unorderedEquals(['package:test/c.dart']));

    var bList = _uriListOfContextLibraries(context, b);
    expect(bList, unorderedEquals(['package:test/c.dart']));

    var cList = _uriListOfContextLibraries(context, c);
    expect(cList, unorderedEquals(['package:test/a.dart']));
  }

  test_pub() async {
    newFile('/home/aaa/lib/a.dart', 'class A {}');
    newFile('/home/aaa/lib/src/a2.dart', 'class A2 {}');

    newFile('/home/bbb/lib/b.dart', 'class B {}');
    newFile('/home/bbb/lib/src/b2.dart', 'class B2 {}');

    newFile('/home/ccc/lib/c.dart', 'class C {}');
    newFile('/home/ccc/lib/src/c2.dart', 'class C2 {}');

    newPubspecYamlFile('/home/test', r'''
name: test
dependencies:
  aaa: any
dev_dependencies:
  bbb: any
''');
    newFile('/home/test/lib/t.dart', 'class T {}');
    newFile('/home/test/lib/src/t2.dart', 'class T2 {}');
    newFile('/home/test/bin/t3.dart', 'class T3 {}');
    newFile('/home/test/test/t4.dart', 'class T4 {}');

    newPubspecYamlFile('/home/test/samples/basic', r'''
name: test
dependencies:
  ccc: any
  test: any
''');
    newFile('/home/test/samples/basic/lib/s.dart', 'class S {}');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '/home/aaa')
        ..add(name: 'bbb', rootPath: '/home/bbb')
        ..add(name: 'ccc', rootPath: '/home/ccc')
        ..add(name: 'basic', rootPath: '/home/test/samples/basic'),
    );

    var context = tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    _assertHasLibrary('package:aaa/a.dart', declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:aaa/src/a2.dart');

    _assertHasLibrary('package:bbb/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:bbb/src/b2.dart');

    _assertHasLibrary('package:ccc/c.dart', declarations: [
      _ExpectedDeclaration.class_('C', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:ccc/src/c2.dart');

    _assertHasLibrary('package:test/t.dart', declarations: [
      _ExpectedDeclaration.class_('T', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/src/t2.dart', declarations: [
      _ExpectedDeclaration.class_('T2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    _assertHasLibrary('package:basic/s.dart', declarations: [
      _ExpectedDeclaration.class_('S', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    {
      var path = convertPath('/home/test/lib/_.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.sdk,
        uriList: ['dart:core', 'dart:async'],
      );
      _assertHasLibraries(
        libraries.dependencies,
        uriList: ['package:aaa/a.dart'],
        only: true,
      );
      // Note, no `bin/` or `test/` libraries.
      // Note, has `lib/src` library.
      _assertHasLibraries(
        libraries.context,
        uriList: [
          'package:test/t.dart',
          'package:test/src/t2.dart',
        ],
        only: true,
      );
    }

    {
      var path = convertPath('/home/test/bin/_.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.sdk,
        uriList: ['dart:core', 'dart:async'],
      );
      _assertHasLibraries(
        libraries.dependencies,
        uriList: [
          'package:aaa/a.dart',
          'package:bbb/b.dart',
        ],
        only: true,
      );
      // Note, no `test/` libraries.
      _assertHasLibraries(
        libraries.context,
        uriList: [
          'package:test/t.dart',
          'package:test/src/t2.dart',
          toUriStr('/home/test/bin/t3.dart'),
        ],
        only: true,
      );
    }

    {
      var path = convertPath('/home/test/test/_.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.sdk,
        uriList: ['dart:core', 'dart:async'],
      );
      _assertHasLibraries(
        libraries.dependencies,
        uriList: [
          'package:aaa/a.dart',
          'package:bbb/b.dart',
        ],
        only: true,
      );
      // Note, no `bin/` libraries.
      _assertHasLibraries(
        libraries.context,
        uriList: [
          'package:test/t.dart',
          'package:test/src/t2.dart',
          toUriStr('/home/test/test/t4.dart'),
        ],
        only: true,
      );
    }

    {
      var path = convertPath('/home/test/samples/basic/lib/_.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.sdk,
        uriList: ['dart:core', 'dart:async'],
      );
      _assertHasLibraries(
        libraries.dependencies,
        uriList: [
          'package:ccc/c.dart',
          'package:test/t.dart',
        ],
        only: true,
      );
      // Note, no `package:test` libraries.
      _assertHasLibraries(
        libraries.context,
        uriList: [
          'package:basic/s.dart',
        ],
        only: true,
      );
    }
  }

  test_sdk_excludesPrivate() async {
    newFile('/home/test/lib/test.dart', '');

    var context = tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    var path = convertPath('/home/test/lib/_.dart');
    var libraries = context.getLibraries(path);
    expect(
      libraries.sdk.where((library) => library.uriStr.startsWith('dart:_')),
      isEmpty,
    );
  }

  test_setDependencies() async {
    newFile('/home/aaa/lib/a.dart', r'''
export 'src/a2.dart' show A2;
class A1 {}
''');
    newFile('/home/aaa/lib/src/a2.dart', r'''
class A2 {}
class A3 {}
''');
    newFile('/home/bbb/lib/b.dart', r'''
class B {}
''');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '/home/aaa')
        ..add(name: 'bbb', rootPath: '/home/bbb'),
    );

    newFile('/home/test/lib/t.dart', 'class T {}');
    newFile('/home/test/lib/src/t2.dart', 'class T2 {}');
    newFile('/home/test/test/t3.dart', 'class T3 {}');

    var context = tracker.addContext(testAnalysisContext);
    context.setDependencies({
      convertPath('/home/test'): [
        convertPath('/home/aaa/lib'),
        convertPath('/home/bbb/lib'),
      ],
      convertPath('/home/test/lib'): [convertPath('/home/aaa/lib')],
    });

    await _doAllTrackerWork();

    _assertHasLibrary('package:aaa/a.dart', declarations: [
      _ExpectedDeclaration.class_('A1', [
        _ExpectedDeclaration.constructor(''),
      ]),
      _ExpectedDeclaration.class_('A2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary('package:aaa/src/a2.dart');
    _assertHasLibrary('package:bbb/b.dart', declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/t.dart', declarations: [
      _ExpectedDeclaration.class_('T', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary('package:test/src/t2.dart', declarations: [
      _ExpectedDeclaration.class_('T2', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary(
      toUriStr('/home/test/test/t3.dart'),
      declarations: [
        _ExpectedDeclaration.class_('T3', [
          _ExpectedDeclaration.constructor(''),
        ]),
      ],
    );

    // `lib/` is configured to see `package:aaa`.
    {
      var path = convertPath('/home/test/lib/_.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.dependencies,
        uriList: ['package:aaa/a.dart'],
        only: true,
      );
      // Not in a package, so all context files are visible.
      _assertHasLibraries(
        libraries.context,
        uriList: [
          'package:test/t.dart',
          'package:test/src/t2.dart',
          toUriStr('/home/test/test/t3.dart'),
        ],
        only: true,
      );
    }

    // `test/` is configured to see `package:aaa` and `package:bbb`.
    {
      var path = convertPath('/home/test/bin/_.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.dependencies,
        uriList: [
          'package:aaa/a.dart',
          'package:bbb/b.dart',
        ],
        only: true,
      );
      // Not in a package, so all context files are visible.
      _assertHasLibraries(
        libraries.context,
        uriList: [
          'package:test/t.dart',
          'package:test/src/t2.dart',
          toUriStr('/home/test/test/t3.dart'),
        ],
        only: true,
      );
    }
  }

  test_setDependencies_twice() async {
    newFile('/home/aaa/lib/a.dart', r'''
class A {}
''');
    newFile('/home/bbb/lib/b.dart', r'''
class B {}
''');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '/home/aaa')
        ..add(name: 'bbb', rootPath: '/home/bbb'),
    );

    newFile('/home/test/lib/test.dart', r'''
class C {}
''');

    var context = tracker.addContext(testAnalysisContext);

    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

    context.setDependencies({
      convertPath('/home/test'): [convertPath('/home/aaa/lib')],
    });
    await _doAllTrackerWork();

    _assertHasLibrary(aUri, declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasNoLibrary(bUri);

    // The package can see package:aaa, but not package:bbb
    {
      var path = convertPath('/home/test/lib/a.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.dependencies,
        uriList: ['package:aaa/a.dart'],
        only: true,
      );
    }

    context.setDependencies({
      convertPath('/home/test'): [convertPath('/home/bbb/lib')],
    });
    await _doAllTrackerWork();

    _assertHasLibrary(aUri, declarations: [
      _ExpectedDeclaration.class_('A', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);
    _assertHasLibrary(bUri, declarations: [
      _ExpectedDeclaration.class_('B', [
        _ExpectedDeclaration.constructor(''),
      ]),
    ]);

    // The package can see package:bbb, but not package:aaa
    {
      var path = convertPath('/home/test/lib/a.dart');
      var libraries = context.getLibraries(path);
      _assertHasLibraries(
        libraries.dependencies,
        uriList: ['package:bbb/b.dart'],
        only: true,
      );
    }
  }

  test_simple_dependenciesFromKnownFiles() async {
    var a = convertPath('/home/test/bin/a.dart');
    var b = convertPath('/home/test/bin/b.dart');
    var c = convertPath('/home/test/bin/c.dart');

    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');
    testAnalysisContext.currentSession.getFile(a);
    testAnalysisContext.currentSession.getFile(b);
    testAnalysisContext.currentSession.getFile(c);

    var context = tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();
    tracker.pullKnownFiles();

    var libraries = context.getLibraries(b);
    _assertHasLibraries(
      libraries.sdk,
      uriList: ['dart:core', 'dart:async'],
    );
    _assertHasLibraries(
      libraries.dependencies,
      uriList: [],
      only: true,
    );
    _assertHasLibraries(
      libraries.context,
      uriList: [
        toUriStr(a),
        toUriStr(c),
      ],
      only: true,
    );
  }

  static void _assertHasLibraries(List<Library> libraries,
      {required List<String> uriList, bool only = false}) {
    var actualUriList = libraries.map((lib) => lib.uriStr).toList();
    if (only) {
      expect(actualUriList, unorderedEquals(uriList));
    } else {
      expect(actualUriList, containsAll(uriList));
    }
  }

  static List<String> _uriListOfContextLibraries(
    DeclarationsContext context,
    String path,
  ) {
    return context.getLibraries(path).context.map((l) => l.uriStr).toList();
  }
}

class _Base extends AbstractContextTest {
  late DeclarationsTracker tracker;

  final List<LibraryChange> changes = [];

  final Map<int, Library> idToLibrary = {};
  final Map<String, Library> uriToLibrary = {};

  @override
  setUp() {
    super.setUp();
    _createTracker();
  }

  void _assertDeclaration(
    Declaration declaration,
    String name,
    DeclarationKind kind, {
    String? defaultArgumentListString,
    List<int>? defaultArgumentListTextRanges,
    String? docComplete,
    String? docSummary,
    bool isAbstract = false,
    bool isConst = false,
    bool isDeprecated = false,
    bool isFinal = false,
    bool isStatic = false,
    int? locationOffset,
    String? locationPath,
    int? locationStartColumn,
    int? locationStartLine,
    String? parameters,
    List<String>? parameterNames,
    List<String>? parameterTypes,
    List<String>? relevanceTags,
    int? requiredParameterCount,
    String? returnType,
    String? typeParameters,
  }) {
    expect(declaration.defaultArgumentListString, defaultArgumentListString);
    expect(
      declaration.defaultArgumentListTextRanges,
      defaultArgumentListTextRanges,
    );
    expect(declaration.docComplete, docComplete);
    expect(declaration.docSummary, docSummary);
    expect(declaration.name, name);
    expect(declaration.kind, kind);
    expect(declaration.isAbstract, isAbstract);
    expect(declaration.isConst, isConst);
    expect(declaration.isDeprecated, isDeprecated);
    expect(declaration.isFinal, isFinal);
    expect(declaration.isStatic, isStatic);
    expect(declaration.parameters, parameters);
    expect(declaration.parameterNames, parameterNames);
    expect(declaration.parameterTypes, parameterTypes);
    expect(declaration.relevanceTags, relevanceTags);
    expect(declaration.requiredParameterCount, requiredParameterCount);
    expect(declaration.returnType, returnType);
    expect(declaration.typeParameters, typeParameters);
    if (locationOffset != null) {
      expect(declaration.locationOffset, locationOffset);
      expect(declaration.locationPath, locationPath);
      expect(declaration.locationStartColumn, locationStartColumn);
      expect(declaration.locationStartLine, locationStartLine);
    }
  }

  void _assertHasDeclaration(
      List<Declaration> declarations, _ExpectedDeclaration expected) {
    var matching = declarations.where((d) {
      return d.name == expected.name && d.kind == expected.kind;
    }).toList();
    if (matching.length != 1) {
      fail('Expected $expected in\n${declarations.join('\n')}');
    }

    var actual = matching.single;
    expect(actual.children, hasLength(expected.children.length));
    for (var expectedChild in expected.children) {
      _assertHasDeclaration(actual.children, expectedChild);
    }
  }

  /// Assert that the current state has the library with the given [uri].
  ///
  /// If [declarations] provided, also checks that the library has exactly
  /// these declarations.
  void _assertHasLibrary(String uri,
      {List<_ExpectedDeclaration>? declarations}) {
    var library = uriToLibrary[uri]!;
    if (declarations != null) {
      expect(library.declarations, hasLength(declarations.length));
      for (var expected in declarations) {
        _assertHasDeclaration(library.declarations, expected);
      }
    }
  }

  void _assertHasNoLibrary(String uri) {
    expect(uriToLibrary, isNot(contains(uri)));
  }

  void _assertNoDeclaration(Library library, String name) {
    expect(
      library.declarations.where((declaration) => declaration.name == name),
      isEmpty,
    );
  }

  void _createTracker() {
    uriToLibrary.clear();

    tracker = DeclarationsTracker(byteStore, resourceProvider);
    tracker.changes.listen((change) {
      changes.add(change);
      for (var library in change.changed) {
        expect(library.declarations, isNotNull);
        idToLibrary[library.id] = library;
        uriToLibrary[library.uriStr] = library;
      }
      idToLibrary.removeWhere((uriStr, library) {
        return change.removed.contains(library.id);
      });
      uriToLibrary.removeWhere((uriStr, library) {
        return change.removed.contains(library.id);
      });
    });
  }

  Future<void> _doAllTrackerWork() async {
    while (tracker.hasWork) {
      tracker.doWork();
    }
    await pumpEventQueue();
  }

  Declaration _getDeclaration(List<Declaration> declarations, String name) {
    return declarations.singleWhere((declaration) => declaration.name == name);
  }

  Library _getLibrary(String uriStr) {
    return uriToLibrary[uriStr]!;
  }
}

class _ExpectedDeclaration {
  final DeclarationKind kind;
  final String name;
  final List<_ExpectedDeclaration> children;

  _ExpectedDeclaration(this.kind, this.name, {this.children = const []});

  _ExpectedDeclaration.class_(String name, List<_ExpectedDeclaration> children)
      : this(DeclarationKind.CLASS, name, children: children);

  _ExpectedDeclaration.classTypeAlias(String name)
      : this(DeclarationKind.CLASS_TYPE_ALIAS, name);

  _ExpectedDeclaration.constructor(String name)
      : this(DeclarationKind.CONSTRUCTOR, name);

  _ExpectedDeclaration.enum_(String name, List<_ExpectedDeclaration> children)
      : this(DeclarationKind.ENUM, name, children: children);

  _ExpectedDeclaration.enumConstant(String name)
      : this(DeclarationKind.ENUM_CONSTANT, name);

  _ExpectedDeclaration.function(String name)
      : this(DeclarationKind.FUNCTION, name);

  _ExpectedDeclaration.functionTypeAlias(String name)
      : this(DeclarationKind.FUNCTION_TYPE_ALIAS, name);

  _ExpectedDeclaration.mixin(String name) : this(DeclarationKind.MIXIN, name);

  _ExpectedDeclaration.variable(String name)
      : this(DeclarationKind.VARIABLE, name);

  @override
  String toString() {
    return '($kind, $name)';
  }
}
