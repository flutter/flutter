// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/either.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
    defineReflectiveTests(FileSystemState_BlazeWorkspaceTest);
    defineReflectiveTests(FileSystemState_PubPackageTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FileSystemState_BlazeWorkspaceTest extends BlazeWorkspaceResolutionTest {
  void test_getFileForUri_hasGenerated_askGeneratedFirst() async {
    var relPath = 'dart/my/test/a.dart';
    var writablePath = convertPath('$workspaceRootPath/$relPath');
    var generatedPath = convertPath('$workspaceRootPath/blaze-bin/$relPath');

    // This generated file should be used instead of the writable.
    newFile(generatedPath, '');

    var analysisDriver = driverFor(testFile);

    var fsState = analysisDriver.fsState;

    // Prepare URI(s).
    var generatedUri = toUri(generatedPath);
    var writableUri = toUri(writablePath);

    // The file is the generated file.
    var generatedFile = fsState.getFileForUri(generatedUri).t1!;
    expect(generatedFile.uri, writableUri);
    expect(generatedFile.path, generatedPath);

    // The file is cached under the requested URI.
    var writableFile1 = fsState.getFileForUri(writableUri).t1!;
    var writableFile2 = fsState.getFileForUri(writableUri).t1!;
    expect(writableFile1, same(generatedFile));
    expect(writableFile2, same(generatedFile));
  }

  void test_getFileForUri_hasGenerated_askWritableFirst() async {
    var relPath = 'dart/my/test/a.dart';
    var writablePath = convertPath('$workspaceRootPath/$relPath');
    var generatedPath = convertPath('$workspaceRootPath/blaze-bin/$relPath');

    // This generated file should be used instead of the writable.
    newFile(generatedPath, '');

    var analysisDriver = driverFor(testFile);

    var fsState = analysisDriver.fsState;

    // Prepare URI(s).
    var generatedUri = toUri(generatedPath);
    var writableUri = toUri(writablePath);

    // The file is cached under the requested URI.
    var writableFile1 = fsState.getFileForUri(writableUri).t1!;
    var writableFile2 = fsState.getFileForUri(writableUri).t1!;
    expect(writableFile2, same(writableFile1));

    // The file is the generated file.
    var generatedFile = fsState.getFileForUri(generatedUri).t1!;
    expect(generatedFile.uri, writableUri);
    expect(generatedFile.path, generatedPath);
    expect(writableFile2, same(generatedFile));
  }

  void test_getFileForUri_nestedLib_notCanonicalUri() async {
    var outer = getFile('$workspaceRootPath/my/outer/lib/a.dart');
    var outerUri = Uri.parse('package:my.outer/a.dart');

    var inner = getFile('/workspace/my/outer/lib/inner/lib/b.dart');
    var innerUri = Uri.parse('package:my.outer.lib.inner/b.dart');

    var analysisDriver = driverFor(outer);
    var fsState = analysisDriver.fsState;

    // User code might use such relative URI.
    var innerUri2 = outerUri.resolve('inner/lib/b.dart');
    expect(innerUri2, Uri.parse('package:my.outer/inner/lib/b.dart'));

    // However the returned file must use the canonical URI.
    var innerFile = fsState.getFileForUri(innerUri2).t1!;
    expect(innerFile.path, inner.path);
    expect(innerFile.uri, innerUri);
  }
}

@reflectiveTest
class FileSystemState_PubPackageTest extends PubPackageResolutionTest {
  @override
  bool get retainDataForTesting => true;

  FileState fileStateFor(File file) {
    return fsStateFor(file).getFileForPath(file.path);
  }

  FileState fileStateForUri(Uri uri) {
    return fsStateFor(testFile).getFileForUri(uri).t1!;
  }

  FileState fileStateForUriStr(String uriStr) {
    final uri = Uri.parse(uriStr);
    return fileStateForUri(uri);
  }

  FileSystemState fsStateFor(File file) {
    return driverFor(file).fsState;
  }

  test_libraryCycle() {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');
    final c = newFile('$testPackageLibPath/c.dart', '');
    final d = newFile('$testPackageLibPath/d.dart', '');

    fileStateFor(a);
    fileStateFor(b);
    fileStateFor(c);
    fileStateFor(d);

    // No imports, individual library cycles.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_4 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_4 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Import `b.dart` into `a.dart`, two files now.
    newFile(a.path, r'''
import 'b.dart';
''');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_1
          library_4 dart:core synthetic
        cycle_5
          dependencies: cycle_1 dart:core
          libraries: library_9
          apiSignature_4
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_4 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_5
      referencingFiles: file_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Update `b.dart` so that it imports `c.dart` now.
    newFile(b.path, r'''
import 'c.dart';
''');
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_10
          library_4 dart:core synthetic
        cycle_6
          dependencies: cycle_7 dart:core
          libraries: library_9
          apiSignature_5
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_10
        libraryImports
          library_2
          library_4 dart:core synthetic
        cycle_7
          dependencies: cycle_2 dart:core
          libraries: library_10
          apiSignature_6
          users: cycle_6
      referencingFiles: file_0
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
          users: cycle_7
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Update `b.dart` so that it exports `d.dart` instead.
    newFile(b.path, r'''
export 'd.dart';
''');
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_11
          library_4 dart:core synthetic
        cycle_8
          dependencies: cycle_9 dart:core
          libraries: library_9
          apiSignature_7
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_11
        libraryImports
          library_4 dart:core synthetic
        libraryExports
          library_3
        cycle_9
          dependencies: cycle_3 dart:core
          libraries: library_11
          apiSignature_8
          users: cycle_8
      referencingFiles: file_0
      unlinkedKey: k03
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
          users: cycle_9
      referencingFiles: file_1
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Update `a.dart` so that it does not import `b.dart` anymore.
    // Note that `a.dart` has its initial API signature.
    // ...and `b.dart` has no users.
    newFile(a.path, '');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_12
        libraryImports
          library_4 dart:core synthetic
        cycle_10
          dependencies: dart:core
          libraries: library_12
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_11
        libraryImports
          library_4 dart:core synthetic
        libraryExports
          library_3
        cycle_9
          dependencies: cycle_3 dart:core
          libraries: library_11
          apiSignature_8
      unlinkedKey: k03
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
          users: cycle_9
      referencingFiles: file_1
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_libraryCycle_cycle_export() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_1
        cycle_0
          dependencies: dart:core
          libraries: library_0 library_1
          apiSignature_0
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_0
        cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update `a.dart` so that it does not export `b.dart` anymore.
    newFile(a.path, '');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
          users: cycle_3
      referencingFiles: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_7
        cycle_3
          dependencies: cycle_2 dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_libraryCycle_cycle_import() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0 library_1
          apiSignature_0
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_2 dart:core synthetic
        cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update a.dart so that it does not import b.dart anymore.
    newFile(a.path, '');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
          users: cycle_3
      referencingFiles: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_7
          library_2 dart:core synthetic
        cycle_3
          dependencies: cycle_2 dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  /// TODO(scheglov) Implement `asLibrary` testing.
  test_libraryCycle_part() {
//     var a_path = convertPath('/aaa/lib/a.dart');
//     var b_path = convertPath('/aaa/lib/b.dart');
//
//     newFile(a_path, r'''
// part 'b.dart';
// ''');
//     newFile(b_path, r'''
// part of 'a.dart';
// ''');
//
//     var a_file = fileSystemState.getFileForPath(a_path);
//     var b_file = fileSystemState.getFileForPath(b_path);
//     _assertFilesWithoutLibraryCycle([a_file, b_file]);
//
//     // Compute the library cycle for 'a.dart', the library.
//     var a_libraryCycle = a_file.libraryCycle;
//     _assertFilesWithoutLibraryCycle([b_file]);
//
//     // The part 'b.dart' has its own library cycle.
//     // If the user chooses to import a part, it is a compile-time error.
//     // We could handle this in different ways:
//     // 1. Completely ignore an import of a file with a `part of` directive.
//     // 2. Treat such file as a library anyway.
//     // By giving a part its own library cycle we support (2).
//     var b_libraryCycle = b_file.libraryCycle;
//     expect(b_libraryCycle, isNot(same(a_libraryCycle)));
//     _assertFilesWithoutLibraryCycle([]);
  }

  test_newFile_augmentation_augmentationExists_hasImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_2
        augmented: augmentation_1
        library: library_0
        libraryImports
          library_3 dart:core synthetic
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_augmentationExists_hasImport_disconnected() async {
    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    fileStateFor(c);

    // `b.dart` points at `a.dart`, but `a.dart` does not import it.
    // So, we can resolve the file, but decline to consider it augmented.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_2
        augmented: augmentation_1
        libraryImports
          library_3 dart:core synthetic
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_augmentationExists_noImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    fileStateFor(c);

    // `c.dart` points at `b.dart`, but `b.dart` does not import it.
    // So, we can resolve the file, but decline to consider it augmented.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_3 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_2
        uriFile: file_1
        libraryImports
          library_3 dart:core synthetic
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_cycle1_augmentSelf() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'b.dart';
import augment 'b.dart';
''');

    fileStateFor(a);

    // There is a cycle of augmentations from `b.dart` to itself.
    // This does not lead to a library, so it is absent.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: augmentation_1
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
      referencingFiles: file_0 file_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_cycle2() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
import augment 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_2
      referencingFiles: file_0 file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_2
        augmented: augmentation_1
        library: library_0
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          notAugmentation file_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_invalidRelativeUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'da:';
''');

    fileStateFor(a);

    // The URI is invalid, so there is no way to discover the target.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: augmentationUnknown_0
        uri: da:
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_libraryExists_hasImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_libraryExists_noImport() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    fileStateFor(b);

    // We can find `a.dart` using the URI.
    // But it does not import the augmentation `b.dart`, so we find the
    // file that corresponds to the URI, but refuse to consider it augmented.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_2 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `a.dart` does not change anything.
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_2 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_targetNotExists() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    fileStateFor(b);

    // We can find `a.dart` from `b.dart` using the URI.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_2 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);

    // We use the URI from `library augment` to find the augmentation target.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Reading `b.dart` does not update the augmentation.
    final bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `b.dart` does not update the augmentation.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude from `a.dart`, the URI still points at `a.dart`.
    // But `c.dart` is not a valid augmentation anymore.
    newFile(a.path, '');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_2 dart:core synthetic
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude from `b.dart`, still point at `a.dart`, still not valid.
    newFile(b.path, '');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_2 dart:core synthetic
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_3
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_2 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `b.dart`, still point at `a.dart`, still not valid.
    newFile(b.path, r'''
import augment 'c.dart';
''');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_2 dart:core synthetic
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_11
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_6
          dependencies: dart:core
          libraries: library_11
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `a.dart`, restore to `a.dart` as the target.
    newFile(a.path, r'''
import augment 'c.dart';
''');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_12
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_11
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_6
          dependencies: dart:core
          libraries: library_11
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_12
        library: library_12
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_doesNotExist() {
    final a = getFile('$testPackageLibPath/a.dart');

    final file = fileStateFor(a);
    expect(file.path, a.path);
    expect(file.uri, Uri.parse('package:test/a.dart'));
    expect(file.content, '');
    expect(file.exists, isFalse);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_hasLibraryDirective_hasPartOfDirective() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library L;
part of L;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: L
        libraryImports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_augmentations_emptyUri() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        augmentationImports
          notAugmentation file_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_augmentations_imports() {
    newFile('$testPackageLibPath/a.dart', '');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'c.dart';
import 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import augment 'b.dart';
''');

    fileStateFor(c);

    // `a.dart` is imported by the augmentation `b.dart`, so it becomes a
    // dependency for the library `c.dart` cycle.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_2
        library: library_2
        libraryImports
          library_0
          library_3 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_library_augmentations_imports2() {
    newFile('$testPackageLibPath/a.dart', '');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'c.dart';
import 'a.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'd.dart';
import augment 'b.dart';
''');

    final d = newFile('$testPackageLibPath/d.dart', r'''
import augment 'c.dart';
''');

    fileStateFor(d);

    // `a.dart` is transitively imported by augmentations into `d.dart`, so it
    // becomes a dependency for the library `d.dart` cycle.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_4 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: augmentation_2
        library: library_3
        libraryImports
          library_0
          library_4 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_2
        augmented: library_3
        library: library_3
        libraryImports
          library_4 dart:core synthetic
        augmentationImports
          augmentation_1
      referencingFiles: file_3
      unlinkedKey: k02
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        augmentationImports
          augmentation_2
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_3
          apiSignature_1
      unlinkedKey: k03
libraryCycles
elementFactory
''');
  }

  test_newFile_library_augmentations_noRelativeUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment ':net';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        augmentationImports
          uriStr: :net
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_augmentations_noRelativeUriStr() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        augmentationImports
          noUriStr
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_augmentations_noSource() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        augmentationImports
          uri: foo:bar
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_dartCore() async {
    final core = fsStateFor(testFile).getFileForUri(
      Uri.parse('dart:core'),
    );

    final coreKind = core.t1!.kind as LibraryFileKind;
    for (final import in coreKind.libraryImports) {
      if (import.isSyntheticDartCore) {
        fail('dart:core should not import itself');
      }
    }
  }

  test_newFile_library_exports_augmentation() async {
    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
export 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_3 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        libraryExports
          notLibrary file_1
        cycle_1
          dependencies: dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_dart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export 'dart:async';
export 'dart:math';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          library_3 dart:async
          library_5 dart:math
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_emptyUri() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_inSummary_library() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': 'class F {}',
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    final a = newFile('$testPackageLibPath/a.dart', r'''
export 'dart:async';
export 'package:foo/foo.dart';
export 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary dart:core synthetic
        libraryExports
          inSummary dart:async
          inSummary package:foo/foo.dart
          library_1
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_exports_inSummary_part() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': "part 'foo2.dart';",
        'lib/foo2.dart': "part of 'foo.dart';",
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    final a = newFile('$testPackageLibPath/a.dart', r'''
export 'package:foo/foo2.dart';
export 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary dart:core synthetic
        libraryExports
          inSummary package:foo/foo2.dart notLibrary
          library_1
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_exports_noRelativeUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export ':net';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          uriStr: :net
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_noRelativeUriStr() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          noUriStr
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_noSource() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          uri: foo:bar
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_package() async {
    final c = newFile('$testPackageLibPath/c.dart', r'''
export 'a.dart';
export 'package:test/b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        libraryExports
          library_0
          library_1
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        name: my.lib
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          notLibrary file_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_augmentation() async {
    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        uriFile: file_0
        libraryImports
          library_3 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          notLibrary file_1
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_emptyUri() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_0
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_dart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'dart:math';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:async
          library_5 dart:math
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_dart_explicitDartCore() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:core';
import 'dart:math';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core
          library_5 dart:math
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_inSummary_library() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': 'class F {}',
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:foo/foo.dart';
import 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary dart:async
          inSummary package:foo/foo.dart
          library_1
          inSummary dart:core synthetic
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_imports_library_inSummary_part() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': "part 'foo2.dart';",
        'lib/foo2.dart': "part of 'foo.dart';",
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:foo/foo2.dart';
import 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary package:foo/foo2.dart notLibrary
          library_1
          inSummary dart:core synthetic
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_imports_library_package() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
import 'package:test/b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_0
          library_1
          library_3 dart:core synthetic
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_package_twice() async {
    newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
import 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_0
          library_2 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_noRelativeUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import ':net';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          uriStr: :net
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_noRelativeUriStr() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          noUriStr
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_noSource() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          uri: foo:bar
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        name: my.lib
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          notLibrary file_0
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_includePart_withoutPartOf() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
// no part of
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing the library does not change this.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_emptyUri() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        parts
          notPart file_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_invalidUri_cannotParse() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'da:';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        parts
          uri: da:
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_invalidUri_interpolation() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        parts
          noUri
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_ofUri_two() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'c.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'c.dart';
class B {}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
part 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_0
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_2
          apiSignature_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Update `a.dart`, updates the library.
    newFile(a.path, r'''
part of 'c.dart';
class A2 {}
''');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_8
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_8
          partOfUriKnown_1
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Update `b.dart`, updates the library.
    newFile(b.path, r'''
part of 'c.dart';
class B2 {}
''');
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_8
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_9
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k04
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_8
          partOfUriKnown_9
        cycle_3
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_libraryDirective() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my
        libraryImports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_noDirectives() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName() async {
    final a = newFile('$testPackageLibPath/nested/a.dart', r'''
library my.lib;
part '../b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
''');

    fileStateFor(b);

    // We don't know the library initially.
    // Even though the library file exists, we have not seen it yet.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfName_0
        name: my.lib
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Read the library file.
    fileStateFor(a);

    // Now the part knows its library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/nested/a.dart
    uri: package:test/nested/a.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_differentName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of other.lib;
''');

    fileStateFor(b);

    // We don't know the library initially.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        name: other.lib
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Read the library file.
    fileStateFor(a);

    // We still don't know the library, because the part wants `other.lib`,
    // but `a.dart` that includes `b.dart` has the name `my.lib`.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        name: other.lib
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_discoverSiblingLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
''');

    final bState = fileStateFor(b);

    // The library is discovered by looking at sibling files.
    final bKind = bState.kind as PartOfNameFileKind;
    expect(bKind.library?.file.resource, a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library my.lib;
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    final aState = fileStateFor(a);

    // When reading `a.dart` we also read `c.dart` part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // After reading `b.dart` the part has two libraries to choose from.
    // We still keep `a.dart`, because its path is sorted first.
    final bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_7
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0 library_7
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refresh `b.dart`, the part still uses `a.dart` as the library.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0 library_8
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refresh `a.dart`, the part still uses `a.dart` as the library.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_8 library_9
        library: library_9
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `a.dart`, switch to `b.dart` instead.
    newFile(a.path, '');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_8
        library: library_8
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `b.dart`, no library.
    newFile(b.path, '');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_11
        libraryImports
          library_2 dart:core synthetic
        cycle_6
          dependencies: dart:core
          libraries: library_11
          apiSignature_3
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        name: my.lib
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `b.dart`, use it as the library.
    newFile(b.path, r'''
library my.lib;
part 'c.dart';
''');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_12
        library: library_12
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `a.dart`, switch to `a.dart`.
    newFile(a.path, r'''
library my.lib;
part 'c.dart';
''');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_13
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_8
          dependencies: dart:core
          libraries: library_13
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_12 library_13
        library: library_13
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_doesNotExist() async {
    final a = getFile('$testPackageLibPath/a.dart');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);

    // The URI in `part of URI` tells us which library to use.
    // However it does not exist, so it does not include the file, so the
    // part file will not be analyzed during the library analysis.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Create `a.dart` that includes the part file.
    newFile(a.path, r'''
part 'b.dart';
''');

    // The library file has already been read because of `part of uri`.
    // So, we explicitly refresh it.
    final aState = fileStateFor(a);
    aState.refresh();

    // Now the part file knows its library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_7
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing the part file does not break the kind.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_8
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_8
        library: library_7
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_exists_hasPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);

    // We have not read the library file explicitly yet.
    // But it was read because of the `part of` directive.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing the part file does not break the kind.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_7
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_exists_noPart() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(a);
    fileStateFor(b);

    // The URI in `part of URI` tells us which library to use.
    // However `a.dart` does not include `b.dart` as a part, so `b.dart` will
    // not be analyzed during the library analysis.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_invalid() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'da:';
''');

    fileStateFor(b);

    // The URI is invalid, so there is no way to discover the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: da:
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Reading a library that includes this part does not change the fact
    // that the URI in the `part of URI` in `b.dart` cannot be resolved.
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');
    fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: da:
      referencingFiles: file_1
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
''');

    final aState = fileStateFor(a);

    // We set the library while reading `a.dart` file.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Reading `b.dart` does not update the part.
    final bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `b.dart` does not update the part.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `a.dart` does not update the part.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_9
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `a.dart`, the URI in `part of` still resolves
    // to `a.dart`, but it is not the library of the part anymore.
    newFile(a.path, '');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `b.dart`, no changes.
    newFile(b.path, '');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_11
        libraryImports
          library_2 dart:core synthetic
        cycle_6
          dependencies: dart:core
          libraries: library_11
          apiSignature_3
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `b.dart`, no changes.
    newFile(b.path, r'''
part 'c.dart';
''');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `a.dart`, restore `a.dart` as the library of the part.
    newFile(a.path, r'''
part 'c.dart';
''');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_13
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_8
          dependencies: dart:core
          libraries: library_13
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_13
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_renameClass() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import augment 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: augmentation_0
        augmented: library_1
        library: library_1
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(a.path, r'''
library augment 'b.dart';
class A2 {}
''');
    fileStateFor(a).refresh();

    // The augmentation `a.dart` has a different unlinked key, and its
    // refresh invalidated the library cycle `b.dart`, which has a different
    // signature now.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: augmentation_7
        augmented: library_1
        library: library_1
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_7
        cycle_2
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_to_library() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a library.
    newFile(b.path, '');
    fileStateFor(b).refresh();

    // Not an augmentation anymore, but a library.
    // But `a.dart` still uses `b.dart` as an augmentation.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_2
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // ...even if we attempt to refresh.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_4
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_2
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_to_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of my.lib;
''');

    // Not an augmentation anymore, but a part.
    // This part can find the referenced library by name `my.lib`.
    // But the library does not include this part, so no library.
    //
    // But `a.dart` still uses `b.dart` as an augmentation.
    final bState = fileStateFor(b);
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_7
        libraries: library_0
        name: my.lib
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // ...even if we attempt to refresh.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_7
        libraries: library_8
        name: my.lib
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Now include `b.dart` into `a.dart` as a part.
    newFile(a.path, r'''
library my.lib;
part 'b.dart';
''');
    aState.refresh();

    // ...not an augmentation, but a known part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_7
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_2
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_7
        libraries: library_9
        library: library_9
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_to_partOfUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of 'a.dart';
''');

    // Not an augmentation anymore, but a part.
    // But `a.dart` still uses `b.dart` as an augmentation.
    final bState = fileStateFor(b);
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        uriFile: file_0
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // ...even if we attempt to refresh.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        uriFile: file_0
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Now include `b.dart` into `a.dart` as a part.
    newFile(a.path, r'''
part 'b.dart';
''');
    aState.refresh();

    // ...not an augmentation, but a known part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_7
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_2
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        library: library_9
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_importedBy_augmentation() {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'c.dart';
import 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import augment 'b.dart';
''');

    fileStateFor(c);

    // `a.dart` is imported by the augmentation `b.dart`, so it is a dependency
    // of `c.dart`.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_2
        library: library_2
        libraryImports
          library_0
          library_3 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    newFile(a.path, r'''
class A2 {}
''');
    fileStateFor(a).refresh();

    // Updated `a.dart` invalidates the library cycle for `c.dart`, both
    // have now different signatures.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_8
        libraryImports
          library_3 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_2
          users: cycle_4
      referencingFiles: file_1
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_1
        augmented: library_2
        library: library_2
        libraryImports
          library_8
          library_3 dart:core synthetic
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        augmentationImports
          augmentation_1
        cycle_4
          dependencies: cycle_3 dart:core
          libraries: library_2
          apiSignature_3
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_removePart_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my;
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of my;
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library my;
part 'a.dart';
part 'b.dart';
''');

    final cState = fileStateFor(c);

    // Both part files know the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        name: my
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfName_0
          partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_2
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(c.path, r'''
library my;
part 'b.dart';
''');

    // Stop referencing `a.dart` part file.
    cState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_8
        name: my
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_8
        library: library_8
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_8
        name: my
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfName_1
        cycle_2
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_removePart_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'c.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
part 'b.dart';
''');

    final cState = fileStateFor(c);

    // Both part files know the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_0
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_2
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(c.path, r'''
library my;
part 'b.dart';
''');

    // Stop referencing `a.dart` part file.
    cState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_8
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_8
        name: my
        libraryImports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_2
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library b;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          notAugmentation file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: b
        libraryImports
          library_2 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(b.path, r'''
library augment 'a.dart';
''');

    // We will discover the target by URI.
    fileStateFor(b).refresh();
    // TODO(scheglov) The API signature must be different.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        augmentationImports
          augmentation_7
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_7
        augmented: library_0
        library: library_0
        libraryImports
          library_2 dart:core synthetic
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    // No `part of`, so it is a library.
    final b = newFile('$testPackageLibPath/b.dart', '');

    fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of my.lib;
''');
    fileStateFor(b).refresh();

    // The API signature of `a.dart` is different.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_7
        cycle_3
          dependencies: dart:core
          libraries: library_0
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_7
        libraries: library_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfName_noLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my;
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my
        libraryImports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    newFile(a.path, r'''
part of my;
''');

    aState.refresh();

    // No library that includes it, so it stays unknown.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_6
        name: my
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library b;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: b
        libraryImports
          library_2 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of 'a.dart';
''');
    fileStateFor(b).refresh();

    // The API signature is different now.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_7
        cycle_3
          dependencies: dart:core
          libraries: library_0
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfName_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
class A1 {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library my.lib;
part 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library my.lib;
part 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Get `c.dart`, now there are two libraries to chose from.
    fileStateFor(c);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1 library_7
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_0
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update `a.dart` part.
    newFile(a.path, r'''
part of my.lib;
class A2 {}
''');
    fileStateFor(a).refresh();

    // `a.dart` is still a part.
    // ...but the unlinked signature of `a.dart` is different.
    // API signatures of both `b.dart` and `c.dart` changed.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_8
        libraries: library_1 library_7
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_8
        cycle_3
          dependencies: dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfName_8
        cycle_4
          dependencies: dart:core
          libraries: library_7
          apiSignature_3
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfUri_to_library() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(a);

    // There is `part of` in `b.dart`, so it is a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(b.path, r'''
// no part of
''');
    fileStateFor(b).refresh();

    // There are no directives in `b.dart`, so it is a library.
    // Library `a.dart` still considers `b.dart` its part.
    // The API signature of the library cycle for `a.dart` is different now.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_1
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_2
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfUri_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
class A1 {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
''');

    fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    fileStateFor(c);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_0
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update `a.dart` part.
    newFile(a.path, r'''
part of 'b.dart';
class A2 {}
''');
    fileStateFor(a).refresh();

    // `a.dart` is still a part.
    // ...but the unlinked signature of `a.dart` is different.
    // The API signatures of `b.dart` is changed, because `a.dart` is its part.
    // But `c.dart` still has the previous API signature.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_8
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_8
        cycle_3
          dependencies: dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        parts
          notPart file_0
        cycle_4
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }
}

@reflectiveTest
class FileSystemStateTest with ResourceProviderMixin {
  final ByteStore byteStore = MemoryByteStore();
  final FileContentOverlay contentOverlay = FileContentOverlay();

  final StringBuffer logBuffer = StringBuffer();
  final _GeneratedUriResolverMock generatedUriResolver =
      _GeneratedUriResolverMock();
  late final SourceFactory sourceFactory;
  late final PerformanceLog logger;

  late final FileSystemState fileSystemState;

  void setUp() {
    logger = PerformanceLog(logBuffer);

    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    var sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    var packageMap = <String, List<Folder>>{
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };

    var packages = Packages({
      'aaa': Package(
        name: 'aaa',
        rootFolder: newFolder('/packages/aaa'),
        libFolder: newFolder('/packages/aaa/lib'),
        languageVersion: null,
      ),
      'bbb': Package(
        name: 'bbb',
        rootFolder: newFolder('/packages/bbb'),
        libFolder: newFolder('/packages/bbb/lib'),
        languageVersion: null,
      ),
    });

    var workspace = BasicWorkspace.find(
      resourceProvider,
      packages,
      convertPath('/test'),
    );

    sourceFactory = SourceFactory([
      DartUriResolver(sdk),
      generatedUriResolver,
      PackageMapUriResolver(resourceProvider, packageMap),
      ResourceUriResolver(resourceProvider)
    ]);

    var featureSetProvider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
      packages: Packages.empty,
      packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
      nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
    );
    fileSystemState = FileSystemState(
      logger,
      byteStore,
      resourceProvider,
      'contextName',
      sourceFactory,
      workspace,
      DeclaredVariables(),
      Uint32List(0),
      Uint32List(0),
      featureSetProvider,
      fileContentStrategy: StoredFileContentStrategy(
        FileContentCache.ephemeral(resourceProvider),
      ),
      prefetchFiles: null,
      isGenerated: (_) => false,
      testData: null,
      unlinkedUnitStore: UnlinkedUnitStoreImpl(),
    );
  }

  test_definedClassMemberNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
class B {
  g() {}
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedClassMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_definedClassMemberNames_enum() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
enum E1 {
  v1;
  int field1, field2;
  const E1();
  const E1.namedConstructor();
  void method() {}
  get getter => 0;
  set setter(_) {}
}

enum E2 {
  v2;
  get getter2 => 0;
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(
      file.definedClassMemberNames,
      unorderedEquals([
        'v1',
        'field1',
        'field2',
        'method',
        'getter',
        'setter',
        'v2',
        'getter2',
      ]),
    );
  }

  test_definedTopLevelNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class A {}
class B = Object with A;
typedef C();
D() {}
get E => null;
set F(_) {}
var G, H;
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedTopLevelNames,
        unorderedEquals(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']));
  }

  test_getFileForPath_samePath() {
    String path = convertPath('/aaa/lib/a.dart');
    FileState file1 = fileSystemState.getFileForPath(path);
    FileState file2 = fileSystemState.getFileForPath(path);
    expect(file2, same(file1));
  }

  test_getFileForUri_invalidUri() {
    var uri = Uri.parse('package:x');
    fileSystemState.getFileForUri(uri).map(
      (file) {
        expect(file, isNull);
      },
      (_) {
        fail('Expected null.');
      },
    );
  }

  test_getFilesSubtypingName_class() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, r'''
class A {}
class B extends A {}
''');
    newFile(b, r'''
class A {}
class D implements A {}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile, bFile]),
    );

    // Change b.dart so that it does not subtype A.
    newFile(b, r'''
class C {}
class D implements C {}
''');
    bFile.refresh();
    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile]),
    );
    expect(
      fileSystemState.getFilesSubtypingName('C'),
      unorderedEquals([bFile]),
    );
  }

  test_getFilesSubtypingName_enum_implements() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, r'''
class A {}
enum E1 implements A {
  v
}
''');
    newFile(b, r'''
class A {}
enum E2 implements A {
  v
}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile, bFile]),
    );

    // Change b.dart so that it does not subtype A.
    newFile(b, r'''
class C {}
enum E2 implements C {
  v
}
''');
    bFile.refresh();
    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile]),
    );
    expect(
      fileSystemState.getFilesSubtypingName('C'),
      unorderedEquals([bFile]),
    );
  }

  test_getFilesSubtypingName_enum_with() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, r'''
mixin M {}
enum E1 with M {
  v
}
''');
    newFile(b, r'''
mixin M {}
enum E2 with M {
  v
}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('M'),
      unorderedEquals([aFile, bFile]),
    );
  }

  test_hasUri() {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = convertPath('/aaa/lib/foo.dart');
    String generatedPath = convertPath('/generated/aaa/lib/foo.dart');

    Source generatedSource = _SourceMock(generatedPath, uri);

    generatedUriResolver.resolveAbsoluteFunction = (uri) => generatedSource;

    expect(fileSystemState.hasUri(templatePath), isFalse);
    expect(fileSystemState.hasUri(generatedPath), isTrue);
  }

  test_referencedNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
A foo(B p) {
  foo(null);
  C c = new C(p);
  return c;
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C']));
  }

  test_refresh_differentApiSignature() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class A {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedTopLevelNames, contains('A'));
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    newFile(path, r'''
class B {}
''');
    final changeKind = file.refresh();
    expect(changeKind, FileStateRefreshResult.apiChanged);

    expect(file.definedTopLevelNames, contains('B'));
    expect(file.apiSignature, isNot(signature));
  }

  test_refresh_sameApiSignature() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class C {
  foo() {
    print(111);
  }
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    newFile(path, r'''
class C {
  foo() {
    print(222);
  }
}
''');
    final changeKind = file.refresh();
    expect(changeKind, FileStateRefreshResult.contentChanged);

    expect(file.apiSignature, signature);
  }

  test_store_zeroLengthUnlinked() {
    String path = convertPath('/test.dart');
    newFile(path, 'class A {}');

    // Get the file, prepare unlinked.
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.unlinked2, isNotNull);

    // Make the unlinked unit in the byte store zero-length, damaged.
    byteStore.putGet(file.test.unlinkedKey, Uint8List(0));

    // Refresh should not fail, zero bytes in the store are ignored.
    file.refresh();
    expect(file.unlinked2, isNotNull);
  }

  test_subtypedNames() {
    String path = convertPath('/test.dart');
    newFile(path, r'''
class X extends A {}
class Y extends A with B {}
class Z implements C, D {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C', 'D']));
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

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

extension _Either2Extension<T1, T2> on Either2<T1, T2> {
  T1 get t1 {
    late T1 result;
    map(
      (t1) => result = t1,
      (_) => throw 'Expected T1',
    );
    return result;
  }
}
