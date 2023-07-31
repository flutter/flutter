// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextLocatorImplTest);
  });
}

@reflectiveTest
class ContextLocatorImplTest with ResourceProviderMixin {
  late final ContextLocatorImpl contextLocator;

  ContextRoot findRoot(List<ContextRoot> roots, Resource rootFolder) {
    for (ContextRoot root in roots) {
      if (root.root == rootFolder) {
        return root;
      }
    }
    StringBuffer buffer = StringBuffer();
    buffer.write('Could not find "');
    buffer.write(rootFolder.path);
    buffer.write('" in');
    for (ContextRoot root in roots) {
      buffer.writeln();
      buffer.write('  ');
      buffer.write(root.root);
    }
    fail(buffer.toString());
  }

  void setUp() {
    contextLocator = ContextLocatorImpl(resourceProvider: resourceProvider);
  }

  void test_locateRoots_excludedByOptions_directoryWithParenthesis() {
    var rootPath = convertPath('/home/test (copy)');
    var rootFolder = newFolder(rootPath);
    var optionsFile = newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - "**/*.g.dart"
''');
    var packagesFile = newPackageConfigJsonFile(rootPath, '');
    var fooFile = newFile('$rootPath/lib/foo.dart', '');
    newFile('$rootPath/lib/bar.g.dart', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [rootFolder.path, fooFile.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, rootFolder);
    expect(
      root.includedPaths,
      unorderedEquals([rootFolder.path]),
    );
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertAnalyzedFiles2(root, [optionsFile, fooFile]);
  }

  void test_locateRoots_link_file_toOutOfRoot() {
    Folder rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newFile('/home/b.dart', '');
    resourceProvider.newLink(
      convertPath('/home/test/lib/c.dart'),
      convertPath('/home/b.dart'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/home/test/lib/a.dart',
      '/home/test/lib/c.dart',
    ]);
  }

  void test_locateRoots_link_file_toSiblingInRoot() {
    Folder rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart', '');
    resourceProvider.newLink(
      convertPath('/test/lib/b.dart'),
      convertPath('/test/lib/a.dart'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/test/lib/a.dart',
      '/test/lib/b.dart',
    ]);
  }

  void test_locateRoots_link_folder_notExistingTarget() {
    var rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart', '');
    newFolder('/test/lib/foo');
    resourceProvider.newLink(
      convertPath('/test/lib/foo'),
      convertPath('/test/lib/bar'),
    );

    var roots = contextLocator.locateRoots(
      includedPaths: [rootFolder.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/test/lib/a.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/lib/a.dart',
      '/test/lib/foo/b.dart',
    ]);
  }

  void test_locateRoots_link_folder_toParentInRoot() {
    Folder rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart', '');
    resourceProvider.newLink(
      convertPath('/test/lib/foo'),
      convertPath('/test/lib'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, ['/test/lib/a.dart']);

    _assertAnalyzed(root, [
      '/test/lib/a.dart',
      '/test/lib/foo/b.dart',
    ]);
  }

  void test_locateRoots_link_folder_toParentOfRoot() {
    Folder rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newFile('/home/b.dart', '');
    newFile('/home/other/c.dart', '');
    resourceProvider.newLink(
      convertPath('/home/test/lib/foo'),
      convertPath('/home'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    // The set of analyzed files includes everything in `/home`,
    // but does not repeat `/home/test/lib/a.dart` and does not cycle.
    _assertAnalyzedFiles(root, [
      '/home/test/lib/a.dart',
      '/home/test/lib/foo/b.dart',
      '/home/test/lib/foo/other/c.dart',
    ]);
  }

  void test_locateRoots_link_folder_toSiblingInRoot() {
    Folder rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart', '');
    newFile('/test/lib/foo/b.dart', '');
    resourceProvider.newLink(
      convertPath('/test/lib/bar'),
      convertPath('/test/lib/foo'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/test/lib/a.dart',
      '/test/lib/foo/b.dart',
      '/test/lib/bar/b.dart',
    ]);
  }

  void test_locateRoots_multiple_dirAndNestedDir_excludedByOptions() {
    var rootPath = convertPath('/home/test');
    var rootFolder = newFolder(rootPath);
    var optionsFile = newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - examples/**
''');
    var packagesFile = newPackageConfigJsonFile(rootPath, '');
    var includedFolder = newFolder('$rootPath/examples/included');
    newFolder('$rootPath/examples/not_included'); // not used

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [rootFolder.path, includedFolder.path]);
    expect(roots, hasLength(1));

    var outerRoot = findRoot(roots, rootFolder);
    expect(
      outerRoot.includedPaths,
      unorderedEquals([rootFolder.path, includedFolder.path]),
    );
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, optionsFile);
    expect(outerRoot.packagesFile, packagesFile);
  }

  void test_locateRoots_multiple_dirAndNestedDir_innerConfigurationFiles() {
    var outerRootFolder = newFolder('/outer');
    var innerOptionsFile =
        newAnalysisOptionsYamlFile('/outer/examples/inner', '');
    var innerPackagesFile =
        newPackageConfigJsonFile('/outer/examples/inner', '');
    var innerRootFolder = newFolder('/outer/examples/inner');

    var roots = contextLocator.locateRoots(
      includedPaths: [outerRootFolder.path, innerRootFolder.path],
    );
    expect(roots, hasLength(2));

    var outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, isNull);
    expect(outerRoot.packagesFile, isNull);

    var innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndNestedDir_noConfigurationFiles() {
    Folder outerRootFolder = newFolder('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path, innerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, isNull);
    expect(outerRoot.packagesFile, isNull);
  }

  void test_locateRoots_multiple_dirAndNestedDir_outerConfigurationFiles() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path, innerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void
      test_locateRoots_multiple_dirAndNestedDir_outerIsBlaze_innerConfigurationFiles() {
    var outerRootFolder = newFolder('/outer');
    newFile('$outerRootFolder/${file_paths.blazeWorkspaceMarker}', '');
    newBlazeBuildFile('$outerRootFolder', '');
    var innerRootFolder = newFolder('/outer/examples/inner');
    var innerOptionsFile = newAnalysisOptionsYamlFile('$innerRootFolder', '');
    var innerPackagesFile = newPackageConfigJsonFile('$innerRootFolder', '');
    newPubspecYamlFile('$innerRootFolder', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [outerRootFolder.path, innerRootFolder.path],
    );
    expect(roots, hasLength(2));

    var outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, isNull);
    expect(outerRoot.packagesFile, isNull);

    var innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.workspace.root, equals(innerRootFolder.path));
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndNestedFile_excludedByOptions() {
    var rootPath = convertPath('/home/test');
    var rootFolder = newFolder(rootPath);
    var optionsFile = newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - lib/f*.dart
''');
    var packagesFile = newPackageConfigJsonFile(rootPath, '');
    var fooFile = newFile('$rootPath/lib/foo.dart', '');
    newFile('$rootPath/lib/far.dart', ''); // not used
    var barFile = newFile('$rootPath/lib/bar.dart', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [rootFolder.path, fooFile.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, rootFolder);
    expect(
      root.includedPaths,
      unorderedEquals([rootFolder.path, fooFile.path]),
    );
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertAnalyzedFiles2(root, [optionsFile, fooFile, barFile]);
  }

  void test_locateRoots_multiple_dirAndNestedFile_noConfigurationFiles() {
    Folder outerRootFolder = newFolder('/test/outer');
    File testFile = newFile('/test/outer/examples/inner/test.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [outerRootFolder.path, testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, isNull);
    expect(outerRoot.packagesFile, isNull);
  }

  void test_locateRoots_multiple_dirAndNestedFile_outerConfigurationFiles() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    File testFile = newFile('/test/outer/examples/inner/test.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [outerRootFolder.path, testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingDir_bothConfigurationFiles() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File outer1OptionsFile = newAnalysisOptionsYamlFile('/test/outer1', '');
    File outer1PackagesFile = newPackageConfigJsonFile('/test/outer1', '');

    Folder outer2RootFolder = newFolder('/test/outer2');
    File outer2OptionsFile = newAnalysisOptionsYamlFile('/test/outer2', '');
    File outer2PackagesFile = newPackageConfigJsonFile('/test/outer2', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outer1RootFolder.path, outer2RootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, outer1OptionsFile);
    expect(outer1Root.packagesFile, outer1PackagesFile);

    ContextRoot outer2Root = findRoot(roots, outer2RootFolder);
    expect(outer2Root.includedPaths, unorderedEquals([outer2RootFolder.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, outer2OptionsFile);
    expect(outer2Root.packagesFile, outer2PackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingDir_noConfigurationFiles() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    Folder outer2RootFolder = newFolder('/test/outer2');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outer1RootFolder.path, outer2RootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, isNull);
    expect(outer1Root.packagesFile, isNull);

    ContextRoot outer2Root = findRoot(roots, outer2RootFolder);
    expect(outer2Root.includedPaths, unorderedEquals([outer2RootFolder.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, isNull);
    expect(outer2Root.packagesFile, isNull);
  }

  void test_locateRoots_multiple_dirAndSiblingFile() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File outer1OptionsFile = newAnalysisOptionsYamlFile('/test/outer1', '');
    File outer1PackagesFile = newPackageConfigJsonFile('/test/outer1', '');

    File outer2OptionsFile = newAnalysisOptionsYamlFile('/test/outer2', '');
    File outer2PackagesFile = newPackageConfigJsonFile('/test/outer2', '');
    File testFile = newFile('/test/outer2/test.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [outer1RootFolder.path, testFile.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, outer1OptionsFile);
    expect(outer1Root.packagesFile, outer1PackagesFile);

    ContextRoot outer2Root = findRoot(roots, testFile.parent);
    expect(outer2Root.includedPaths, unorderedEquals([testFile.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, outer2OptionsFile);
    expect(outer2Root.packagesFile, outer2PackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingFile_noConfigurationFiles() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File testFile = newFile('/test/outer2/test.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [outer1RootFolder.path, testFile.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, isNull);
    expect(outer1Root.packagesFile, isNull);

    ContextRoot outer2Root = findRoot(roots, getFolder('/'));
    expect(outer2Root.includedPaths, unorderedEquals([testFile.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, isNull);
    expect(outer2Root.packagesFile, isNull);
  }

  void test_locateRoots_multiple_dirs_blaze_differentWorkspaces() {
    var workspacePath1 = '/home/workspace1';
    var workspacePath2 = '/home/workspace2';
    var pkgPath1 = '$workspacePath1/pkg1';
    var pkgPath2 = '$workspacePath2/pkg2';

    newFile('$workspacePath1/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$workspacePath2/${file_paths.blazeWorkspaceMarker}', '');
    newBlazeBuildFile(pkgPath1, '');
    newBlazeBuildFile(pkgPath2, '');

    var folder1 = newFolder('$pkgPath1/lib/folder1');
    var folder2 = newFolder('$pkgPath2/lib/folder2');
    var file1 = newFile('$pkgPath1/lib/folder1/file1.dart', '');
    var file2 = newFile('$pkgPath2/lib/folder2/file2.dart', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [folder1.path, folder2.path],
    );
    expect(roots, hasLength(2));

    var root1 = findRoot(roots, getFolder(folder1.path));
    expect(root1.includedPaths, unorderedEquals([folder1.path]));
    expect(root1.excludedPaths, isEmpty);
    expect(root1.optionsFile, isNull);
    expect(root1.packagesFile, isNull);
    _assertBlazeWorkspace(root1.workspace, workspacePath1);
    _assertAnalyzedFiles2(root1, [file1]);

    var root2 = findRoot(roots, getFolder(folder2.path));
    expect(root2.includedPaths, unorderedEquals([folder2.path]));
    expect(root2.excludedPaths, isEmpty);
    expect(root2.optionsFile, isNull);
    expect(root2.packagesFile, isNull);
    _assertBlazeWorkspace(root2.workspace, workspacePath2);
    _assertAnalyzedFiles2(root2, [file2]);
  }

  /// Even if a file is excluded by the options, when it is explicitly included
  /// into analysis, it should be analyzed.
  void test_locateRoots_multiple_fileAndSiblingFile_excludedByOptions() {
    File optionsFile = newAnalysisOptionsYamlFile('/home/test', r'''
analyzer:
  exclude:
    - lib/test2.dart
''');
    File packagesFile = newPackageConfigJsonFile('/home/test', '');
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [testFile1.path, testFile2.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/home/test'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  void test_locateRoots_multiple_fileAndSiblingFile_hasOptions() {
    File optionsFile = newAnalysisOptionsYamlFile('/home/test', '');
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [testFile1.path, testFile2.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/home/test'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  void
      test_locateRoots_multiple_fileAndSiblingFile_hasOptions_overrideOptions() {
    newAnalysisOptionsYamlFile('/home/test', ''); // not used
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/home', '');
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
      includedPaths: [testFile1.path, testFile2.path],
      optionsFile: overrideOptionsFile.path,
    );
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, overrideOptionsFile);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  void test_locateRoots_multiple_fileAndSiblingFile_hasOptionsPackages() {
    File optionsFile = newAnalysisOptionsYamlFile('/home/test', '');
    File packagesFile = newPackageConfigJsonFile('/home/test', '');
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [testFile1.path, testFile2.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/home/test'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  void test_locateRoots_multiple_fileAndSiblingFile_hasPackages() {
    File packagesFile = newPackageConfigJsonFile('/home/test', '');
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [testFile1.path, testFile2.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/home/test'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, packagesFile);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  /// When there is a packages file in a containing directory, that would
  /// control analysis of the files, but we provide an override, we ignore
  /// the don't look into containing directories, so the context root can be
  /// just the file system root.
  void
      test_locateRoots_multiple_fileAndSiblingFile_hasPackages_overridePackages() {
    newPackageConfigJsonFile('/home/test', ''); // not used
    File overridePackagesFile = newPackageConfigJsonFile('/home', '');
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
      includedPaths: [testFile1.path, testFile2.path],
      packagesFile: overridePackagesFile.path,
    );
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, overridePackagesFile);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  /// When there are no configuration files, we can use the root of the file
  /// system, because it contains all the files.
  void test_locateRoots_multiple_fileAndSiblingFile_noConfigurationFiles() {
    File testFile1 = newFile('/home/test/lib/test1.dart', '');
    File testFile2 = newFile('/home/test/lib/test2.dart', '');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [testFile1.path, testFile2.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, getFolder('/'));
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);
    _assertBasicWorkspace(root.workspace, root.root.path);

    _assertAnalyzedFiles2(root, [testFile1, testFile2]);
  }

  void test_locateRoots_multiple_files_blaze_differentWorkspaces() {
    var workspacePath1 = '/home/workspace1';
    var workspacePath2 = '/home/workspace2';
    var pkgPath1 = '$workspacePath1/pkg1';
    var pkgPath2 = '$workspacePath2/pkg2';

    newFile('$workspacePath1/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$workspacePath2/${file_paths.blazeWorkspaceMarker}', '');
    newBlazeBuildFile(pkgPath1, '');
    newBlazeBuildFile(pkgPath2, '');

    var file1 = newFile('$pkgPath1/lib/file1.dart', '');
    var file2 = newFile('$pkgPath2/lib/file2.dart', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [file1.path, file2.path],
    );
    expect(roots, hasLength(2));

    var root1 = findRoot(roots, getFolder(workspacePath1));
    expect(root1.includedPaths, unorderedEquals([file1.path]));
    expect(root1.excludedPaths, isEmpty);
    expect(root1.optionsFile, isNull);
    expect(root1.packagesFile, isNull);
    _assertBlazeWorkspace(root1.workspace, workspacePath1);
    _assertAnalyzedFiles2(root1, [file1]);

    var root2 = findRoot(roots, getFolder(workspacePath2));
    expect(root2.includedPaths, unorderedEquals([file2.path]));
    expect(root2.excludedPaths, isEmpty);
    expect(root2.optionsFile, isNull);
    expect(root2.packagesFile, isNull);
    _assertBlazeWorkspace(root2.workspace, workspacePath2);
    _assertAnalyzedFiles2(root2, [file2]);
  }

  void test_locateRoots_multiple_files_blaze_sameWorkspace_differentPackages() {
    var workspacePath = '/home/workspace';
    var fooPath = '$workspacePath/foo';
    var barPath = '$workspacePath/bar';

    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    newBlazeBuildFile(fooPath, '');
    newBlazeBuildFile(barPath, '');

    var fooFile = newFile('$fooPath/lib/foo.dart', '');
    var barFile = newFile('$barPath/lib/bar.dart', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [fooFile.path, barFile.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, getFolder(workspacePath));
    expect(root.includedPaths, unorderedEquals([fooFile.path, barFile.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);
    _assertBlazeWorkspace(root.workspace, workspacePath);
    _assertAnalyzedFiles2(root, [fooFile, barFile]);
  }

  void test_locateRoots_multiple_files_differentWorkspaces_pub() {
    var rootPath = '/home';
    var fooPath = '$rootPath/foo';
    var barPath = '$rootPath/bar';

    newPubspecYamlFile(fooPath, '');
    newPubspecYamlFile(barPath, '');

    var fooFile = newFile('$fooPath/lib/foo.dart', '');
    var barFile = newFile('$barPath/lib/bar.dart', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [fooFile.path, barFile.path],
    );
    expect(roots, hasLength(2));

    var fooRoot = findRoot(roots, getFolder(fooPath));
    expect(fooRoot.includedPaths, unorderedEquals([fooFile.path]));
    expect(fooRoot.excludedPaths, isEmpty);
    expect(fooRoot.optionsFile, isNull);
    expect(fooRoot.packagesFile, isNull);
    _assertPubWorkspace(fooRoot.workspace, fooPath);
    _assertAnalyzedFiles2(fooRoot, [fooFile]);

    var barRoot = findRoot(roots, getFolder(barPath));
    expect(barRoot.includedPaths, unorderedEquals([barFile.path]));
    expect(barRoot.excludedPaths, isEmpty);
    expect(barRoot.optionsFile, isNull);
    expect(barRoot.packagesFile, isNull);
    _assertPubWorkspace(barRoot.workspace, barPath);
    _assertAnalyzedFiles2(barRoot, [barFile]);
  }

  void test_locateRoots_multiple_files_gnWorkspace() {
    var workspaceRootPath = '/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myRoot = newFolder(myRootPath);
    var myBuildGn = newBuildGnFile(myRootPath, '');
    var myFile1 = newFile('$myRootPath/lib/file1.dart', '');
    var myFile2 = newFile('$myRootPath/lib/file2.dart', '');
    newFile('$myRootPath/lib/file3.dart', '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [myFile1.path, myFile2.path],
    );
    expect(roots, hasLength(1));

    var myContextRoot = findRoot(roots, myRoot);
    _assertGnWorkspace(myContextRoot.workspace, workspaceRootPath, myBuildGn);
    _assertAnalyzedFiles2(myContextRoot, [myFile1, myFile2]);
  }

  void test_locateRoots_multiple_files_sameOptions_differentPackages() {
    var fooPackagesFile = newPackageConfigJsonFile('/home/foo', '');
    var barPackagesFile = newPackageConfigJsonFile('/home/bar', '');
    var optionsFile = newAnalysisOptionsYamlFile('/home', '');
    var fooFile = newFile('/home/foo/lib/foo.dart', '');
    var barFile = newFile('/home/bar/lib/bar.dart', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
      includedPaths: [fooFile.path, barFile.path],
    );
    expect(roots, hasLength(2));

    ContextRoot fooRoot = findRoot(roots, getFolder('/home/foo'));
    expect(fooRoot.includedPaths, unorderedEquals([fooFile.path]));
    expect(fooRoot.excludedPaths, isEmpty);
    expect(fooRoot.optionsFile, optionsFile);
    expect(fooRoot.packagesFile, fooPackagesFile);
    _assertAnalyzedFiles2(fooRoot, [fooFile]);

    ContextRoot barRoot = findRoot(roots, getFolder('/home/bar'));
    expect(barRoot.includedPaths, unorderedEquals([barFile.path]));
    expect(barRoot.excludedPaths, isEmpty);
    expect(barRoot.optionsFile, optionsFile);
    expect(barRoot.packagesFile, barPackagesFile);
    _assertAnalyzedFiles2(barRoot, [barFile]);
  }

  void test_locateRoots_multiple_files_samePackages_differentOptions() {
    var packagesFile = newPackageConfigJsonFile('/home', '');
    var fooOptionsFile = newAnalysisOptionsYamlFile('/home/foo', '');
    var barOptionsFile = newAnalysisOptionsYamlFile('/home/bar', '');
    var fooFile = newFile('/home/foo/lib/foo.dart', '');
    var barFile = newFile('/home/bar/lib/bar.dart', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
      includedPaths: [fooFile.path, barFile.path],
    );
    expect(roots, hasLength(2));

    ContextRoot fooRoot = findRoot(roots, getFolder('/home/foo'));
    expect(fooRoot.includedPaths, unorderedEquals([fooFile.path]));
    expect(fooRoot.excludedPaths, isEmpty);
    expect(fooRoot.optionsFile, fooOptionsFile);
    expect(fooRoot.packagesFile, packagesFile);
    _assertAnalyzedFiles2(fooRoot, [fooFile]);

    ContextRoot barRoot = findRoot(roots, getFolder('/home/bar'));
    expect(barRoot.includedPaths, unorderedEquals([barFile.path]));
    expect(barRoot.excludedPaths, isEmpty);
    expect(barRoot.optionsFile, barOptionsFile);
    expect(barRoot.packagesFile, packagesFile);
    _assertAnalyzedFiles2(barRoot, [barFile]);
  }

  void test_locateRoots_nested_excluded_dot() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');

    newFolder('/test/outer/.examples');
    newAnalysisOptionsYamlFile('/test/outer/.examples/inner', '');

    // Only one analysis root, we skipped `.examples` for context roots.
    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_excluded_explicit() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder excludedFolder = newFolder('/test/outer/examples');
    newAnalysisOptionsYamlFile('/test/outer/examples/inner', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        excludedPaths: [excludedFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([excludedFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_multiple() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder inner1RootFolder = newFolder('/test/outer/examples/inner1');
    File inner1OptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner1', '');
    Folder inner2RootFolder = newFolder('/test/outer/examples/inner2');
    File inner2PackagesFile =
        newPackageConfigJsonFile('/test/outer/examples/inner2', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(3));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths,
        unorderedEquals([inner1RootFolder.path, inner2RootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot inner1Root = findRoot(roots, inner1RootFolder);
    expect(inner1Root.includedPaths, unorderedEquals([inner1RootFolder.path]));
    expect(inner1Root.excludedPaths, isEmpty);
    expect(inner1Root.optionsFile, inner1OptionsFile);
    expect(inner1Root.packagesFile, outerPackagesFile);

    ContextRoot inner2Root = findRoot(roots, inner2RootFolder);
    expect(inner2Root.includedPaths, unorderedEquals([inner2RootFolder.path]));
    expect(inner2Root.excludedPaths, isEmpty);
    expect(inner2Root.optionsFile, outerOptionsFile);
    expect(inner2Root.packagesFile, inner2PackagesFile);
  }

  void test_locateRoots_nested_options() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_options_overriddenOptions() {
    Folder outerRootFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    newFolder('/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/test/outer/examples/inner', '');
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/test/override', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        optionsFile: overrideOptionsFile.path);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, overrideOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_options_overriddenPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    newPackageConfigJsonFile('/test/outer', '');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner', '');
    File overridePackagesFile = newPackageConfigJsonFile('/test/override', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        packagesFile: overridePackagesFile.path);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, overridePackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, overridePackagesFile);
  }

  void test_locateRoots_nested_optionsAndPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner', '');
    File innerPackagesFile =
        newPackageConfigJsonFile('/test/outer/examples/inner', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_optionsAndPackages_overriddenBoth() {
    Folder outerRootFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer', '');
    newPackageConfigJsonFile('/test/outer', '');
    newFolder('/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/test/outer/examples/inner', '');
    newPackageConfigJsonFile('/test/outer/examples/inner', '');
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/test/override', '');
    File overridePackagesFile = newPackageConfigJsonFile('/test/override', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        optionsFile: overrideOptionsFile.path,
        packagesFile: overridePackagesFile.path);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, overrideOptionsFile);
    expect(outerRoot.packagesFile, overridePackagesFile);
  }

  void test_locateRoots_nested_packageConfigJson() {
    var outerRootFolder = newFolder('/test/outer');
    var outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    var outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    var innerRootFolder = newFolder('/test/outer/examples/inner');
    var innerPackagesFile =
        newPackageConfigJsonFile('/test/outer/examples/inner', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [outerRootFolder.path],
    );
    expect(roots, hasLength(2));

    var outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    var innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, outerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerPackagesFile =
        newPackageConfigJsonFile('/test/outer/examples/inner', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, outerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages_overriddenOptions() {
    Folder outerRootFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerPackagesFile =
        newPackageConfigJsonFile('/test/outer/examples/inner', '');
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/test/override', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        optionsFile: overrideOptionsFile.path);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, overrideOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, overrideOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages_overriddenPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    newPackageConfigJsonFile('/test/outer', '');
    newFolder('/test/outer/examples/inner');
    newPackageConfigJsonFile('/test/outer/examples/inner', '');
    File overridePackagesFile = newPackageConfigJsonFile('/test/override', '');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        packagesFile: overridePackagesFile.path);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, overridePackagesFile);
  }

  void test_locateRoots_nested_packagesDirectory_included() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer', '');
    File outerPackagesFile = newPackageConfigJsonFile('/test/outer', '');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/packages/inner', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths,
        unorderedEquals([innerOptionsFile.parent.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_options_default_blaze() {
    var workspacePath = '/home/workspace';
    var workspaceFolder = getFolder(workspacePath);
    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    var blazeOptionsFile = newFile(
      '$workspacePath/dart/analysis_options/lib/default.yaml',
      '',
    );

    var rootFolder = getFolder('$workspacePath/test');

    var roots = contextLocator.locateRoots(
      includedPaths: [rootFolder.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, workspaceFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, blazeOptionsFile);
    expect(root.packagesFile, isNull);
  }

  void test_locateRoots_options_default_flutter() {
    var rootFolder = newFolder('/home/test');

    var flutterPath = '/home/packages/flutter';
    var flutterAnalysisOptionsFile = newFile(
      '$flutterPath/lib/analysis_options_user.yaml',
      '',
    );

    var packageConfigFileBuilder = PackageConfigFileBuilder()
      ..add(name: 'flutter', rootPath: flutterPath);
    var packagesFile = newPackageConfigJsonFile(
      rootFolder.path,
      packageConfigFileBuilder.toContent(toUriStr: toUriStr),
    );

    var roots = contextLocator.locateRoots(
      includedPaths: [rootFolder.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, flutterAnalysisOptionsFile);
    expect(root.packagesFile, packagesFile);
  }

  void test_locateRoots_options_hasError() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
analyzer:
  exclude:
    - **.g.dart
analyzer:
''');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    // There is an error in the analysis_options.yaml, so it is ignored.
    _assertAnalyzed(root, [
      '/test/root//lib/a.dart',
      '/test/root//lib/a.g.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_someFiles() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
analyzer:
  exclude:
    - data/**.g.dart
''');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.g.dart',
      '/test/root/data/foo/f.g.dart',
      '/test/root/data/foo/bar/f.g.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.g.dart',
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
      '/test/root/data/foo/bar/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_someFolders() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
analyzer:
  exclude:
    - data/**/foo/**
''');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/aaa/foo/f.dart',
      '/test/root/data/aaa/foo/bar/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
      '/test/root/data/aaa/bar/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
analyzer:
  exclude:
    - data/**
''');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');
    newFolder('/test/root/data');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder_includedOptions() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
include: has_excludes.yaml
''');
    newFile('/test/root/has_excludes.yaml', '''
analyzer:
  exclude:
    - data/**
''');

    File packagesFile = newPackageConfigJsonFile('/test/root', '');
    newFolder('/test/root/data');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder_includedOptionsMerge() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
include: has_excludes.yaml
analyzer:
  exclude:
    - bar/**
''');
    newFile('/test/root/has_excludes.yaml', '''
analyzer:
  exclude:
    - foo/**
''');

    File packagesFile = newPackageConfigJsonFile('/test/root', '');
    newFolder('/test/root/foo');
    newFolder('/test/root/bar');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/foo/f.dart',
      '/test/root/foo/aaa/f.dart',
      '/test/root/bar/f.dart',
      '/test/root/bar/aaa/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
      '/test/root/baz/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder_withItsOptions() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '''
analyzer:
  exclude:
    - data/**
''');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');
    newFolder('/test/root/data');
    newAnalysisOptionsYamlFile('/test/root/data', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
    ]);
  }

  test_locateRoots_single_dir_children_gnWorkspaces_noPubspecYaml() {
    var workspaceRootPath = '/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var dartPath = '$workspaceRootPath/dart';
    var fooRootPath = '$dartPath/foo';
    var fooRoot = newFolder(fooRootPath);
    var fooBuildGn = newBuildGnFile(fooRootPath, '');
    newFile('$dartGenPath/dart/foo/foo_package_config.json', '');

    var barRootPath = '$dartPath/bar';
    var barRoot = newFolder(barRootPath);
    var barBuildGn = newBuildGnFile(barRootPath, '');
    newFile('$dartGenPath/dart/bar/bar_package_config.json', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [
        getFolder(dartPath).path,
      ],
    );
    expect(roots, hasLength(3));

    var fooContextRoot = findRoot(roots, fooRoot);
    _assertGnWorkspace(fooContextRoot.workspace, workspaceRootPath, fooBuildGn);

    var barContextRoot = findRoot(roots, barRoot);
    _assertGnWorkspace(barContextRoot.workspace, workspaceRootPath, barBuildGn);
  }

  void test_locateRoots_single_dir_directOptions_directPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_directOptions_inheritedPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', '');
    File packagesFile = newPackageConfigJsonFile('/test', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_gnWorkspace_hasPubspecYaml() {
    var workspaceRootPath = '/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myRoot = newFolder(myRootPath);
    var myBuildGn = newBuildGnFile(myRootPath, '');
    newFile('$dartGenPath/my/my_package_config.json', '');
    newPubspecYamlFile(myRootPath, '');

    var roots = contextLocator.locateRoots(
      includedPaths: [myRoot.path],
    );
    expect(roots, hasLength(1));

    var package1Root = findRoot(roots, myRoot);
    _assertGnWorkspace(package1Root.workspace, workspaceRootPath, myBuildGn);
  }

  void test_locateRoots_single_dir_gnWorkspace_noPubspecYaml() {
    var workspaceRootPath = '/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myRoot = newFolder(myRootPath);
    var myBuildGn = newBuildGnFile(myRootPath, '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [myRoot.path],
    );
    expect(roots, hasLength(1));

    var package1Root = findRoot(roots, myRoot);
    _assertGnWorkspace(package1Root.workspace, workspaceRootPath, myBuildGn);
  }

  void test_locateRoots_single_dir_inheritedOptions_directPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test', '');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_inheritedOptions_inheritedPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test', '');
    File packagesFile = newPackageConfigJsonFile('/test', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_prefer_packageConfigJson() {
    var rootFolder = newFolder('/test');
    var optionsFile = newAnalysisOptionsYamlFile('/test', '');
    newPackageConfigJsonFile('/test', ''); // the file is not used
    var packageConfigJsonFile = newPackageConfigJsonFile('/test', '');

    var roots = contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    var contentRoot = findRoot(roots, rootFolder);
    expect(contentRoot.includedPaths, unorderedEquals([rootFolder.path]));
    expect(contentRoot.excludedPaths, isEmpty);
    expect(contentRoot.optionsFile, optionsFile);
    expect(contentRoot.packagesFile, packageConfigJsonFile);
  }

  void test_locateRoots_single_file_gnWorkspace() {
    var workspaceRootPath = '/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myRoot = newFolder(myRootPath);
    var myBuildGn = newBuildGnFile(myRootPath, '');
    var myFile = newFile('$myRootPath/lib/a.dart', '');
    newFile('$myRootPath/lib/b.dart', '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [myFile.path],
    );
    expect(roots, hasLength(1));

    var myContextRoot = findRoot(roots, myRoot);
    _assertGnWorkspace(myContextRoot.workspace, workspaceRootPath, myBuildGn);
    _assertAnalyzedFiles2(myContextRoot, [myFile]);
  }

  void test_locateRoots_single_file_inheritedOptions_directPackages() {
    File optionsFile = newAnalysisOptionsYamlFile('/test', '');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');
    File testFile = newFile('/test/root/test.dart', '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, testFile.parent);
    expect(package1Root.includedPaths, unorderedEquals([testFile.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_file_jiriRoot_noBuildGn_noPubspecYaml() {
    var workspaceRootPath = '/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myFile = newFile('$myRootPath/lib/a.dart', '');
    newFile('$myRootPath/lib/b.dart', '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    var roots = contextLocator.locateRoots(
      includedPaths: [myFile.path],
    );
    expect(roots, hasLength(1));

    var root = findRoot(roots, getFolder('/'));
    _assertBasicWorkspace(root.workspace, root.root.path);
    _assertAnalyzedFiles2(root, [myFile]);
  }

  void test_locateRoots_single_file_notExisting() {
    File optionsFile = newAnalysisOptionsYamlFile('/test', '');
    File packagesFile = newPackageConfigJsonFile('/test/root', '');
    File testFile = getFile('/test/root/test.dart');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, testFile.parent);
    expect(package1Root.includedPaths, unorderedEquals([testFile.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void _assertAnalyzed(ContextRoot root, List<String> posixPathList) {
    for (var posixPath in posixPathList) {
      var path = convertPath(posixPath);
      expect(root.isAnalyzed(path), isTrue, reason: path);
    }
  }

  void _assertAnalyzedFiles(ContextRoot root, List<String> posixPathList) {
    var pathList = posixPathList.map(convertPath).toList();

    var analyzedFiles = root.analyzedFiles().toList();
    expect(analyzedFiles, unorderedEquals(pathList));

    for (var path in pathList) {
      expect(root.isAnalyzed(path), isTrue, reason: path);
    }
  }

  void _assertAnalyzedFiles2(ContextRoot root, List<File> files) {
    var pathList = files.map((file) => file.path).toList();
    _assertAnalyzedFiles(root, pathList);
  }

  void _assertBasicWorkspace(Workspace workspace, String posixRoot) {
    workspace as BasicWorkspace;
    var root = convertPath(posixRoot);
    expect(workspace.root, root);
  }

  void _assertBlazeWorkspace(Workspace workspace, String posixRoot) {
    workspace as BlazeWorkspace;
    var root = convertPath(posixRoot);
    expect(workspace.root, root);
  }

  void _assertGnWorkspace(
    Workspace workspace,
    String posixRoot,
    File buildGnFile,
  ) {
    workspace as GnWorkspace;
    var root = convertPath(posixRoot);
    expect(workspace.root, root);
    expect(workspace.buildGnFile, buildGnFile);
  }

  void _assertNotAnalyzed(ContextRoot root, List<String> posixPathList) {
    for (var posixPath in posixPathList) {
      var path = convertPath(posixPath);
      expect(root.isAnalyzed(path), isFalse, reason: path);
    }
  }

  void _assertPubWorkspace(Workspace workspace, String posixRoot) {
    workspace as PubWorkspace;
    var root = convertPath(posixRoot);
    expect(workspace.root, root);
  }
}
