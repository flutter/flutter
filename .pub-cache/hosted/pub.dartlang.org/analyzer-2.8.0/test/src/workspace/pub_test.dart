// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import 'workspace_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubWorkspacePackageTest);
    defineReflectiveTests(PubWorkspaceTest);
  });
}

@reflectiveTest
class PubWorkspacePackageTest extends WorkspacePackageTest {
  setUp() {
    newPubspecYamlFile('/workspace', 'name: project');
    workspace = PubWorkspace.find(
        resourceProvider,
        {
          'p1': [getFolder('/.pubcache/p1/lib')],
          'workspace': [getFolder('/workspace/lib')]
        },
        convertPath('/workspace'))!;
    expect(workspace.isBazel, isFalse);
  }

  void test_contains_differentWorkspace() {
    newFile('/workspace2/project/lib/file.dart');

    var package = findPackage('/workspace/project/lib/code.dart')!;
    expect(
        package.contains(
            TestSource(convertPath('/workspace2/project/lib/file.dart'))),
        isFalse);
  }

  void test_contains_sameWorkspace() {
    newFile('/workspace/project/lib/file2.dart');

    var package = findPackage('/workspace/project/lib/code.dart')!;
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/lib/file2.dart'))),
        isTrue);
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/bin/bin.dart'))),
        isTrue);
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/test/test.dart'))),
        isTrue);
  }

  void test_findPackageFor_includedFile() {
    newFile('/workspace/project/lib/file.dart');

    var package = findPackage('/workspace/project/lib/file.dart')!;
    expect(package.root, convertPath('/workspace'));
    expect(package.workspace, equals(workspace));
  }

  void test_findPackageFor_unrelatedFile() {
    newFile('/workspace/project/lib/file.dart');

    var package = findPackage('/workspace2/project/lib/file.dart');
    expect(package, isNull);
  }

  void test_packagesAvailableTo() {
    var libraryPath = convertPath('/workspace/lib/test.dart');
    var package = findPackage(libraryPath)!;
    var packageMap = package.packagesAvailableTo(libraryPath);
    expect(packageMap.keys, unorderedEquals(['p1', 'workspace']));
  }
}

@reflectiveTest
class PubWorkspaceTest with ResourceProviderMixin {
  void test_find_directory() {
    newPubspecYamlFile('/workspace', 'name: project');
    var workspace =
        PubWorkspace.find(resourceProvider, {}, convertPath('/workspace'))!;
    expect(workspace.isBazel, isFalse);
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_find_fail_notAbsolute() {
    expect(
        () => PubWorkspace.find(
            resourceProvider, {}, convertPath('not_absolute')),
        throwsA(TypeMatcher<ArgumentError>()));
  }

  void test_find_file() {
    newPubspecYamlFile('/workspace', 'name: project');
    var workspace = PubWorkspace.find(
        resourceProvider, {}, convertPath('/workspace/lib/lib1.dart'))!;
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_find_missingPubspec() {
    var workspace = PubWorkspace.find(
        resourceProvider, {}, convertPath('/workspace/lib/lib1.dart'));
    expect(workspace, isNull);
  }

  void test_isConsistentWithFileSystem() {
    newPubspecYamlFile('/workspace', 'name: my');
    var workspace =
        PubWorkspace.find(resourceProvider, {}, convertPath('/workspace'))!;
    expect(workspace.isConsistentWithFileSystem, isTrue);

    newPubspecYamlFile('/workspace', 'name: my2');
    expect(workspace.isConsistentWithFileSystem, isFalse);
  }
}
