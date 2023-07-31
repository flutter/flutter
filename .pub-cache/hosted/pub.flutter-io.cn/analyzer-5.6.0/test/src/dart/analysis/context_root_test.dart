// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextRootTest);
  });
}

@reflectiveTest
class ContextRootTest with ResourceProviderMixin {
  late final String rootPath;
  late final Folder rootFolder;
  late Workspace workspace;
  late ContextRootImpl contextRoot;

  void setUp() {
    rootPath = convertPath('/test/root');
    rootFolder = newFolder(rootPath);
    workspace = BasicWorkspace.find(resourceProvider, Packages.empty, rootPath);
    contextRoot = ContextRootImpl(resourceProvider, rootFolder, workspace);
    contextRoot.included.add(rootFolder);
  }

  test_analyzedFiles() {
    String optionsPath = convertPath('/test/root/analysis_options.yaml');
    String readmePath = convertPath('/test/root/README.md');
    String aPath = convertPath('/test/root/lib/a.dart');
    String bPath = convertPath('/test/root/lib/src/b.dart');
    String excludePath = convertPath('/test/root/exclude');
    String cPath = convertPath('/test/root/exclude/c.dart');

    newFile(optionsPath, '');
    newFile(readmePath, '');
    newFile(aPath, '');
    newFile(bPath, '');
    newFile(cPath, '');
    contextRoot.excluded.add(newFolder(excludePath));

    expect(contextRoot.analyzedFiles(),
        unorderedEquals([optionsPath, readmePath, aPath, bPath]));
  }

  test_isAnalyzed_excludedByGlob_includedFile() {
    var rootPath = '/home/test';
    var includedFile = newFile('$rootPath/lib/a1.dart', '');
    var excludedFile = newFile('$rootPath/lib/a2.dart', '');
    var implicitFile = newFile('$rootPath/lib/b.dart', '');

    var root = _createContextRoot(rootPath);
    root.included.add(includedFile);
    _addGlob(root, 'lib/a*.dart');

    // Explicitly included, so analyzed even if excluded by a glob.
    expect(root.isAnalyzed(includedFile.path), isTrue);

    // Not explicitly included, excluded by a glob.
    expect(root.isAnalyzed(excludedFile.path), isFalse);

    // Implicitly included by a folder, not excluded.
    expect(root.isAnalyzed(implicitFile.path), isTrue);

    _assertAnalyzedFiles2(root, [includedFile, implicitFile]);
  }

  test_isAnalyzed_excludedByGlob_includedFolder() {
    var rootPath = '/home/test';

    var includedFolderPath = convertPath('$rootPath/lib/src/included');
    var includedFolder = getFolder(includedFolderPath);
    var includedFile1 = newFile('$includedFolderPath/a1.dart', '');
    var includedFile2 = newFile('$includedFolderPath/inner/a2.dart', '');
    var excludedFile1 = newFile('$includedFolderPath/a1.g.dart', '');

    var excludedFolderPath = convertPath('$rootPath/lib/src/not_included');
    var excludedFile2 = newFile('$excludedFolderPath/b.dart', '');

    var implicitFile = newFile('$rootPath/lib/c.dart', '');

    var root = _createContextRoot(rootPath);
    root.included.add(includedFolder);
    _addGlob(root, 'lib/src/**');
    _addGlob(root, 'lib/**.g.dart');

    // Explicitly included, so analyzed even if excluded by a glob.
    expect(root.isAnalyzed(includedFolder.path), isTrue);
    expect(root.isAnalyzed(includedFile1.path), isTrue);
    expect(root.isAnalyzed(includedFile2.path), isTrue);

    // Not explicitly included, excluded by a glob.
    expect(root.isAnalyzed(excludedFolderPath), isFalse);
    expect(root.isAnalyzed(excludedFile1.path), isFalse);
    expect(root.isAnalyzed(excludedFile2.path), isFalse);

    // Implicitly included by a folder, not excluded.
    expect(root.isAnalyzed(implicitFile.path), isTrue);

    _assertAnalyzedFiles2(
      root,
      [includedFile1, includedFile2, implicitFile],
    );
  }

  test_isAnalyzed_explicitlyExcluded_byFile() {
    var excludePath = convertPath('/test/root/exclude/c.dart');
    var siblingPath = convertPath('/test/root/exclude/d.dart');
    contextRoot.excluded.add(newFile(excludePath, ''));
    expect(contextRoot.isAnalyzed(excludePath), isFalse);
    expect(contextRoot.isAnalyzed(siblingPath), isTrue);
  }

  test_isAnalyzed_explicitlyExcluded_byFile_analysisOptions() {
    var excludePath = convertPath('/test/root/analysis_options.yaml');
    contextRoot.excluded.add(newFile(excludePath, ''));
    expect(contextRoot.isAnalyzed(excludePath), isFalse);
  }

  test_isAnalyzed_explicitlyExcluded_byFile_pubspec() {
    var excludePath = convertPath('/test/root/pubspec.yaml');
    contextRoot.excluded.add(newFile(excludePath, ''));
    expect(contextRoot.isAnalyzed(excludePath), isFalse);
  }

  test_isAnalyzed_explicitlyExcluded_byFolder() {
    String excludePath = convertPath('/test/root/exclude');
    String filePath = convertPath('/test/root/exclude/root.dart');
    contextRoot.excluded.add(newFolder(excludePath));
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_explicitlyExcluded_same() {
    String aPath = convertPath('/test/root/lib/a.dart');
    String bPath = convertPath('/test/root/lib/b.dart');
    File aFile = getFile(aPath);

    contextRoot.excluded.add(aFile);

    expect(contextRoot.isAnalyzed(aPath), isFalse);
    expect(contextRoot.isAnalyzed(bPath), isTrue);
  }

  test_isAnalyzed_implicitlyExcluded_dotFile() {
    String filePath = convertPath('/test/root/lib/.aaa');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_implicitlyExcluded_dotFolder_containsRoot() {
    var contextRoot = _createContextRoot('/home/.foo/root');

    expect(_isAnalyzed(contextRoot, ''), isTrue);
    expect(_isAnalyzed(contextRoot, 'lib/a.dart'), isTrue);
    expect(_isAnalyzed(contextRoot, 'lib/.bar/a.dart'), isFalse);
  }

  test_isAnalyzed_implicitlyExcluded_dotFolder_directParent() {
    String filePath = convertPath('/test/root/lib/.aaa/a.dart');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_implicitlyExcluded_dotFolder_indirectParent() {
    String filePath = convertPath('/test/root/lib/.aaa/bbb/a.dart');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_implicitlyExcluded_dotFolder_isRoot() {
    var contextRoot = _createContextRoot('/home/.root');

    expect(_isAnalyzed(contextRoot, ''), isTrue);
    expect(_isAnalyzed(contextRoot, 'lib/a.dart'), isTrue);
    expect(_isAnalyzed(contextRoot, 'lib/.bar/a.dart'), isFalse);
  }

  /// https://github.com/flutter/flutter/issues/76911
  test_isAnalyzed_implicitlyExcluded_dotFolder_windows() {
    if (resourceProvider.pathContext.rootPrefix(rootPath) == r'C:\') {
      var truePath = convertPath('/test/root/lib/a.dart');
      expect(contextRoot.isAnalyzed(truePath), isTrue);
      expect(contextRoot.isAnalyzed(truePath.toLowerCase()), isTrue);

      var falsePath = convertPath('/test/root/.foo/a.dart');
      expect(contextRoot.isAnalyzed(falsePath), isFalse);
      expect(contextRoot.isAnalyzed(falsePath.toLowerCase()), isFalse);
    }
  }

  test_isAnalyzed_included() {
    String filePath = convertPath('/test/root/lib/root.dart');
    expect(contextRoot.isAnalyzed(filePath), isTrue);
  }

  test_isAnalyzed_included_same() {
    String aPath = convertPath('/test/root/lib/a.dart');
    String bPath = convertPath('/test/root/lib/b.dart');
    File aFile = getFile(aPath);

    contextRoot = ContextRootImpl(resourceProvider, rootFolder, workspace);
    contextRoot.included.add(aFile);

    expect(contextRoot.isAnalyzed(aPath), isTrue);
    expect(contextRoot.isAnalyzed(bPath), isFalse);
  }

  test_isAnalyzed_packagesDirectory_analyzed() {
    String folderPath = convertPath('/test/root/lib/packages');
    newFolder(folderPath);
    expect(contextRoot.isAnalyzed(folderPath), isTrue);
  }

  void _addGlob(ContextRootImpl root, String posixPattern) {
    var pathContext = root.resourceProvider.pathContext;
    var glob = Glob(posixPattern, context: pathContext);
    root.excludedGlobs.add(LocatedGlob(root.root, glob));
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

  ContextRootImpl _createContextRoot(String posixPath) {
    var rootPath = convertPath(posixPath);
    var rootFolder = newFolder(rootPath);
    var workspace =
        BasicWorkspace.find(resourceProvider, Packages.empty, rootPath);
    var contextRoot = ContextRootImpl(resourceProvider, rootFolder, workspace);
    contextRoot.included.add(rootFolder);
    return contextRoot;
  }

  static bool _isAnalyzed(ContextRoot contextRoot, String relPosix) {
    var pathContext = contextRoot.resourceProvider.pathContext;
    var path = pathContext.join(
      contextRoot.root.path,
      pathContext.joinAll(
        posix.split(relPosix),
      ),
    );
    return contextRoot.isAnalyzed(path);
  }
}
