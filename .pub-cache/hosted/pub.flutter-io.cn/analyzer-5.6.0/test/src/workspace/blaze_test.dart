// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BlazeFileUriResolverTest);
    defineReflectiveTests(BlazePackageUriResolverTest);
    defineReflectiveTests(BlazeWorkspaceTest);
    defineReflectiveTests(BlazeWorkspacePackageTest);
  });
}

@reflectiveTest
class BlazeFileUriResolverTest with ResourceProviderMixin {
  late final BlazeWorkspace workspace;
  late final BlazeFileUriResolver resolver;

  void test_resolveAbsolute_blazeBin_exists() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-bin/my/test/a.dart',
    ]);
    _assertResolve(
      toUriStr('/workspace/blaze-bin/my/test/a.dart'),
      getFile('/workspace/blaze-bin/my/test/a.dart'),
      restoredUriStr: toUriStr('/workspace/my/test/a.dart'),
    );
  }

  void test_resolveAbsolute_notFile_dartUri() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    Uri uri = Uri(scheme: 'dart', path: 'core');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_httpsUri() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    Uri uri = Uri(scheme: 'https', path: '127.0.0.1/test.dart');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_outsideOfWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    expect(
      resolver.resolveAbsolute(
        toUri('/foo'),
      ),
      isNull,
    );
  }

  void test_resolveAbsolute_workspaceRoot() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    expect(
      resolver.resolveAbsolute(
        toUri('/workspace'),
      ),
      isNull,
    );
  }

  void test_resolveAbsolute_writableUri_blazeBin_hasWritable() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/my/test/a.dart',
      '/workspace/blaze-bin/my/test/a.dart',
    ]);
    _assertResolve(
      toUriStr('/workspace/my/test/a.dart'),
      getFile('/workspace/blaze-bin/my/test/a.dart'),
    );
  }

  void test_resolveAbsolute_writableUri_blazeBin_noWritable() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-bin/my/test/a.dart',
    ]);
    _assertResolve(
      toUriStr('/workspace/my/test/a.dart'),
      getFile('/workspace/blaze-bin/my/test/a.dart'),
    );
  }

  void test_resolveAbsolute_writableUri_blazeGenfiles_hasWritable() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/my/test/a.dart',
      '/workspace/blaze-genfiles/my/test/a.dart',
    ]);
    _assertResolve(
      toUriStr('/workspace/my/test/a.dart'),
      getFile('/workspace/blaze-genfiles/my/test/a.dart'),
    );
  }

  void test_resolveAbsolute_writableUri_blazeGenfiles_noWritable() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/my/test/a.dart',
    ]);
    _assertResolve(
      toUriStr('/workspace/my/test/a.dart'),
      getFile('/workspace/blaze-genfiles/my/test/a.dart'),
    );
  }

  void test_resolveAbsolute_writableUri_writable() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/my/lib/a.dart',
    ]);
    _assertResolve(
      toUriStr('/workspace/my/lib/a.dart'),
      getFile('/workspace/my/lib/a.dart'),
    );
  }

  void test_resolveAbsolute_writableUri_writable_doesNotExist() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    _assertResolve(
      toUriStr('/workspace/my/lib/a.dart'),
      getFile('/workspace/my/lib/a.dart'),
      exists: false,
    );
  }

  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path, '');
      }
    }
    workspace = BlazeWorkspace.find(
      resourceProvider,
      getFolder('/workspace').path,
    )!;
    resolver = BlazeFileUriResolver(workspace);
  }

  void _assertResolve(
    String uriStr,
    File file, {
    bool exists = true,
    String? restoredUriStr,
  }) {
    var uri = Uri.parse(uriStr);

    var source = resolver.resolveAbsolute(uri)!;
    var path = source.fullName;
    expect(path, file.path);
    expect(source.uri, uri);
    expect(source.exists(), exists);

    restoredUriStr ??= uriStr;
    expect(resolver.pathToUri(path), Uri.parse(restoredUriStr));
  }
}

@reflectiveTest
class BlazePackageUriResolverTest with ResourceProviderMixin {
  late final BlazeWorkspace workspace;
  late final BlazePackageUriResolver resolver;

  void test_resolveAbsolute_bin() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
      '/workspace/blaze-bin/my/foo/lib/foo1.dart'
    ]);
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/blaze-bin/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_bin_notInWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-bin/my/foo/lib/foo1.dart'
    ]);
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/blaze-bin/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_file_bin_pathHasSpace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/my/foo/test',
    ]);
    _assertResolve(toUriStr('/workspace/blaze-bin/my/test/a .dart'),
        '/workspace/my/test/a .dart',
        exists: false, restore: false);
  }

  void test_resolveAbsolute_file_bin_to_genfiles() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/my/foo/test/foo1.dart',
      '/workspace/blaze-bin/'
    ]);
    _assertResolve(toUriStr('/workspace/blaze-bin/my/foo/test/foo1.dart'),
        '/workspace/blaze-genfiles/my/foo/test/foo1.dart',
        restore: false);
  }

  void test_resolveAbsolute_file_genfiles_to_workspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/test/foo1.dart'
    ]);
    _assertResolve(toUriStr('/workspace/blaze-genfiles/my/foo/test/foo1.dart'),
        '/workspace/my/foo/test/foo1.dart',
        restore: false);
  }

  void test_resolveAbsolute_file_not_in_workspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/other/my/foo/test/foo1.dart'
    ]);
    _assertNoResolve(toUriStr('/other/my/foo/test/foo1.dart'));
  }

  void test_resolveAbsolute_file_workspace_to_genfiles() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/my/foo/test/foo1.dart'
    ]);
    _assertResolve(toUriStr('/workspace/my/foo/test/foo1.dart'),
        '/workspace/blaze-genfiles/my/foo/test/foo1.dart',
        restore: false);
  }

  void test_resolveAbsolute_genfiles() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
      '/workspace/blaze-genfiles/my/foo/lib/foo1.dart'
    ]);
    _assertResolve('package:my.foo/foo1.dart',
        '/workspace/blaze-genfiles/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_genfiles_notInWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-genfiles/my/foo/lib/foo1.dart'
    ]);
    _assertResolve('package:my.foo/foo1.dart',
        '/workspace/blaze-genfiles/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_null_doubleDot() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var uri = Uri.parse('package:foo..bar/baz.dart');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_doubleSlash() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var uri = Uri.parse('package:foo//bar/baz.dart');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_emptyFileUriPart() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    var uri = Uri.parse('package:foo.bar/');
    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_noSlash() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var source = resolver.resolveAbsolute(Uri.parse('package:foo'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_notPackage() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var source = resolver.resolveAbsolute(Uri.parse('dart:async'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_null_startsWithSlash() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/lib/bar.dart',
    ]);
    var source = resolver.resolveAbsolute(Uri.parse('package:/foo/bar.dart'));
    expect(source, isNull);
  }

  void test_resolveAbsolute_thirdParty_bin() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
      '/workspace/blaze-bin/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/blaze-bin/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_bin_notInWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-bin/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/blaze-bin/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_doesNotExist() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo2.dart',
        '/workspace/third_party/dart/foo/lib/foo2.dart',
        exists: false);
  }

  void test_resolveAbsolute_thirdParty_exists() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_genfiles() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/third_party/dart/foo/lib/foo1.dart',
      '/workspace/blaze-genfiles/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/blaze-genfiles/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_thirdParty_genfiles_notInWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-genfiles/third_party/dart/foo/lib/foo1.dart',
    ]);
    _assertResolve('package:foo/foo1.dart',
        '/workspace/blaze-genfiles/third_party/dart/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_workspace_doesNotExist() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    _assertResolve('package:my.foo/doesNotExist.dart',
        '/workspace/my/foo/lib/doesNotExist.dart',
        exists: false);
  }

  void test_resolveAbsolute_workspace_exists() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
    ]);
    _assertResolve(
        'package:my.foo/foo1.dart', '/workspace/my/foo/lib/foo1.dart',
        exists: true);
  }

  void test_resolveAbsolute_workspace_exists_hasSpace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/lib/foo .dart',
    ]);
    _assertResolve(
        'package:my.foo/foo .dart', '/workspace/my/foo/lib/foo .dart',
        exists: true, restore: false);
  }

  void test_restoreAbsolute_noPackageName_workspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/lib/foo1.dart',
      '/workspace/foo/lib/foo2.dart',
    ]);
    _assertRestore('/workspace/lib/foo1.dart', null);
    _assertRestore('/workspace/foo/lib/foo2.dart', null);
  }

  void test_restoreAbsolute_noPathInLib_bin() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-bin/my/foo/lib/foo1.dart',
    ]);
    _assertRestore('/workspace/blaze-bin', null);
    _assertRestore('/workspace/blaze-bin/my', null);
    _assertRestore('/workspace/blaze-bin/my/foo', null);
    _assertRestore('/workspace/blaze-bin/my/foo/lib', null);
  }

  void test_restoreAbsolute_noPathInLib_genfiles() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-genfiles/my/foo/lib/foo1.dart',
    ]);
    _assertRestore('/workspace/blaze-genfiles', null);
    _assertRestore('/workspace/blaze-genfiles/my', null);
    _assertRestore('/workspace/blaze-genfiles/my/foo', null);
    _assertRestore('/workspace/blaze-genfiles/my/foo/lib', null);
  }

  void test_restoreAbsolute_noPathInLib_workspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/my/foo/lib/foo1.dart',
    ]);
    _assertRestore('/workspace', null);
    _assertRestore('/workspace/my', null);
    _assertRestore('/workspace/my/foo', null);
    _assertRestore('/workspace/my/foo/lib', null);
  }

  void test_restoreAbsolute_thirdPartyNotDart_workspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
      '/workspace/third_party/something/lib/foo.dart',
    ]);
    _assertRestore('/workspace/third_party/something/lib/foo.dart',
        'package:third_party.something/foo.dart');
  }

  void test_restoreAbsolute_workspace_nestedLib() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/my/components/lib/src/foo/lib/foo.dart',
    ]);
    _assertRestore('/workspace/my/components/lib/src/foo/lib/foo.dart',
        'package:my.components.lib.src.foo/foo.dart');
  }

  void _addResources(List<String> paths,
      {String workspacePath = '/workspace'}) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path, '');
      }
    }
    workspace =
        BlazeWorkspace.find(resourceProvider, convertPath(workspacePath))!;
    resolver = BlazePackageUriResolver(workspace);
  }

  void _assertNoResolve(String uriStr) {
    var uri = Uri.parse(uriStr);
    expect(resolver.resolveAbsolute(uri), isNull);
  }

  void _assertResolve(String uriStr, String posixPath,
      {bool exists = true, bool restore = true}) {
    Uri uri = Uri.parse(uriStr);
    var source = resolver.resolveAbsolute(uri)!;
    var path = source.fullName;
    expect(path, convertPath(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    // If enabled, test also "restoreAbsolute".
    if (restore) {
      expect(resolver.pathToUri(path), uri);
    }
  }

  void _assertRestore(String posixPath, String? expectedUriStr) {
    var expectedUri = expectedUriStr != null ? Uri.parse(expectedUriStr) : null;
    String path = convertPath(posixPath);
    expect(resolver.pathToUri(path), expectedUri);
  }
}

@reflectiveTest
class BlazeWorkspacePackageTest with ResourceProviderMixin {
  late final BlazeWorkspace workspace;
  BlazeWorkspacePackage? package;

  void test_contains_differentPackage_summarySource() {
    _setUpPackage();
    var source = _inSummarySource('package:some.other.code/file.dart');
    expect(package!.contains(source), isFalse);
  }

  void test_contains_differentPackageInWorkspace() {
    _setUpPackage();

    // A file that is _not_ in this package is not required to have a BUILD
    // file above it, for simplicity and reduced I/O.
    expect(
      package!.contains(
        _testSource('/ws/some/other/code/file.dart'),
      ),
      isFalse,
    );
  }

  void test_contains_differentWorkspace() {
    _setUpPackage();
    expect(
      package!.contains(
        _testSource('/ws2/some/file.dart'),
      ),
      isFalse,
    );
  }

  void test_contains_samePackage() {
    _setUpPackage();
    final targetFile = newFile('/ws/some/code/lib/code2.dart', '');
    final targetFile2 = newFile('/ws/some/code/lib/src/code3.dart', '');
    final targetBinFile = newFile('/ws/some/code/bin/code.dart', '');
    final targetTestFile = newFile('/ws/some/code/test/code_test.dart', '');

    expect(package!.contains(_testSource(targetFile.path)), isTrue);
    expect(package!.contains(_testSource(targetFile2.path)), isTrue);
    expect(package!.contains(_testSource(targetBinFile.path)), isTrue);
    expect(package!.contains(_testSource(targetTestFile.path)), isTrue);
  }

  void test_contains_samePackage_summarySource() {
    _setUpPackage();
    newFile('/ws/some/code/lib/code2.dart', '');
    newFile('/ws/some/code/lib/src/code3.dart', '');
    final file2Source = _inSummarySource('package:some.code/code2.dart');
    final file3Source = _inSummarySource('package:some.code/src/code2.dart');

    expect(package!.contains(file2Source), isTrue);
    expect(package!.contains(file3Source), isTrue);
  }

  void test_contains_subPackage() {
    _setUpPackage();
    newFile('/ws/some/code/testing/BUILD', '');
    newFile('/ws/some/code/testing/lib/testing.dart', '');

    expect(
      package!.contains(
        _testSource('/ws/some/code/testing/lib/testing.dart'),
      ),
      isFalse,
    );
  }

  void test_findPackageFor_buildFileExists() {
    _setUpPackage();

    expect(package, isNotNull);
    expect(package?.root, convertPath('/ws/some/code'));
    expect(package?.workspace, equals(workspace));
  }

  void test_findPackageFor_generatedFileInBlazeOutAndBin() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/blaze-out/host/bin/some/code/code.dart',
      '/ws/blaze-bin/some/code/code.dart',
    ]);
    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code/testing'),
    )!;

    // Make sure that we can find the package of the generated file.
    var file = workspace.findFile(convertPath('/ws/some/code/code.dart'));
    package = workspace.findPackageFor(file!.path);

    expect(package, isNotNull);
    expect(package?.root, convertPath('/ws/some/code'));
    expect(package?.workspace, equals(workspace));
  }

  void test_findPackageFor_inBlazeOut_notPackage() {
    var path =
        convertPath('/ws/blaze-out/k8-opt/bin/news/lib/news_base.pb.dart');
    newFile('/ws/news/BUILD', '');
    newFile(path, '');
    workspace = BlazeWorkspace.find(resourceProvider, path)!;

    var package = workspace.findPackageFor(path);
    expect(package, isNull);
  }

  void test_findPackageFor_missingMarkerFiles() {
    _addResources([
      '/ws/${file_paths.blazeWorkspaceMarker}',
      '/ws/blaze-genfiles',
    ]);
    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    )!;
    final targetFile = newFile('/ws/some/code/lib/code.dart', '');

    package = workspace.findPackageFor(targetFile.path);
    expect(package, isNull);
  }

  void test_findPackageFor_noBuildFile_disabledPackagesFile() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/some/code/lib/code.dart',
    ]);
    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
      lookForBuildFileSubstitutes: false,
    )!;

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
    expect(package, isNull);
  }

  void test_findPackageFor_packagesFileExistsInOneOfSeveralBinPaths() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/blaze-out/k8-opt/bin/some/code/',
      '/ws/some/code/lib/code.dart',
    ]);
    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    )!;

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
    expect(package, isNotNull);
    expect(package?.root, convertPath('/ws/some/code'));
    expect(package?.workspace, equals(workspace));
  }

  void test_findPackageFor_packagesFileExistsInOnlyBinPath() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/some/code/lib/code.dart',
    ]);
    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    )!;

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
    expect(package, isNotNull);
    expect(package?.root, convertPath('/ws/some/code'));
    expect(package?.workspace, equals(workspace));
  }

  void test_findPackageFor_packagesFileInBinExists_subPackage() {
    _addResources([
      '/ws/blaze-out/host/bin/some/code/code.packages',
      '/ws/blaze-out/host/bin/some/code/testing/testing.packages',
      '/ws/some/code/lib/code.dart',
      '/ws/some/code/testing/lib/testing.dart',
    ]);
    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code/testing'),
    )!;

    package = workspace.findPackageFor(
      convertPath('/ws/some/code/testing/lib/testing.dart'),
    );
    expect(package, isNotNull);
    expect(package?.root, convertPath('/ws/some/code/testing'));
    expect(package?.workspace, equals(workspace));
  }

  void test_packagesAvailableTo() {
    _setUpPackage();
    var path = convertPath('/ws/some/code/lib/code.dart');
    var packages = package?.packagesAvailableTo(path);
    expect(packages?.packages, isEmpty);
  }

  /// Create new files and directories from [paths].
  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path, '');
      }
    }
  }

  Source _inSummarySource(String uriStr) {
    var uri = Uri.parse(uriStr);
    return InSummarySource(
      uri: uri,
      summaryPath: '',
      kind: InSummarySourceKind.library,
    );
  }

  void _setUpPackage() {
    _addResources([
      '/ws/${file_paths.blazeWorkspaceMarker}',
      '/ws/blaze-genfiles/',
      '/ws/some/code/BUILD',
      '/ws/some/code/lib/code.dart',
    ]);

    workspace = BlazeWorkspace.find(
      resourceProvider,
      convertPath('/ws/some/code'),
    )!;
    package = workspace.findPackageFor(
      convertPath('/ws/some/code/lib/code.dart'),
    );
  }

  Source _testSource(String path) {
    path = convertPath(path);
    return TestSource(path);
  }
}

@reflectiveTest
class BlazeWorkspaceTest with ResourceProviderMixin {
  late final BlazeWorkspace workspace;

  void test_blazeNotifications() async {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-bin/my/module/test1.dart',
    ]);
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    var notifications = StreamQueue(workspace.blazeCandidateFiles);

    var file1 =
        workspace.findFile(convertPath('/workspace/my/module/test1.dart'))!;
    expect(file1.exists, true);
    var info = await notifications.next;
    expect(info.requestedPath, convertPath('my/module/test1.dart'));
    expect(
        info.candidatePaths,
        containsAll([
          convertPath('/workspace/blaze-bin/my/module/test1.dart'),
          convertPath('/workspace/blaze-genfiles/my/module/test1.dart'),
        ]));

    var file2 =
        workspace.findFile(convertPath('/workspace/my/module/test2.dart'))!;
    expect(file2.exists, false);
    info = await notifications.next;
    expect(info.requestedPath, convertPath('my/module/test2.dart'));
    expect(
        info.candidatePaths,
        containsAll([
          convertPath('/workspace/blaze-bin/my/module/test2.dart'),
          convertPath('/workspace/blaze-genfiles/my/module/test2.dart'),
        ]));
  }

  void test_find_fail_notAbsolute() {
    expect(
        () =>
            BlazeWorkspace.find(resourceProvider, convertPath('not_absolute')),
        throwsA(const TypeMatcher<ArgumentError>()));
  }

  void test_find_hasBlazeBinFolderInOutFolder() {
    _addResources([
      '/workspace/blaze-out/host/bin/',
      '/workspace/my/module/BUILD',
    ]);
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
        workspace.binPaths.first, convertPath('/workspace/blaze-out/host/bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
    expect(
        workspace
            .findPackageFor(convertPath(
                '/workspace/blaze-out/host/bin/my/module/lib/foo.dart'))!
            .root,
        convertPath('/workspace/my/module'));
  }

  void test_find_hasBlazeOutFolder_missingBinFolder() {
    _addResources([
      '/workspace/blaze-genfiles/',
      '/workspace/blaze-out/',
      '/workspace/my/module/',
    ]);
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasMultipleBlazeBinFolderInOutFolder() {
    _addResources([
      '/workspace/blaze-out/host/bin/',
      '/workspace/blaze-out/k8-fastbuild/bin/',
      '/workspace/my/module/',
    ]);
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths, hasLength(3));
    expect(workspace.binPaths,
        contains(convertPath('/workspace/blaze-out/host/bin')));
    expect(workspace.binPaths,
        contains(convertPath('/workspace/blaze-out/k8-fastbuild/bin')));
    expect(workspace.binPaths, contains(convertPath('/workspace/blaze-bin')));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile_forModuleInWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var workspace =
        BlazeWorkspace.find(resourceProvider, convertPath('/workspace'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_hasWorkspaceFile_forWorkspace_blaze() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/blaze-genfiles/',
    ]);
    var workspace =
        BlazeWorkspace.find(resourceProvider, convertPath('/workspace'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_find_null_noWorkspaceMarkers() {
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'));
    expect(workspace, isNull);
  }

  void test_find_null_noWorkspaceMarkers_inRoot() {
    var workspace = BlazeWorkspace.find(resourceProvider, convertPath('/'));
    expect(workspace, isNull);
  }

  void test_find_null_symlinkPrefix() {
    newFile('/workspace/${file_paths.blazeWorkspaceMarker}', '');
    var workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  void test_findFile() {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
      '/workspace/my/module/test1.dart',
      '/workspace/my/module/test2.dart',
      '/workspace/my/module/test3.dart',
      '/workspace/blaze-bin/my/module/test2.dart',
      '/workspace/blaze-genfiles/my/module/test3.dart',
    ]);
    workspace = BlazeWorkspace.find(
        resourceProvider, convertPath('/workspace/my/module'))!;
    _expectFindFile('/workspace/my/module/test1.dart',
        equals: '/workspace/my/module/test1.dart');
    _expectFindFile('/workspace/my/module/test2.dart',
        equals: '/workspace/blaze-bin/my/module/test2.dart');
    _expectFindFile('/workspace/my/module/test3.dart',
        equals: '/workspace/blaze-genfiles/my/module/test3.dart');
  }

  void test_forBuild() {
    // We don't have to create any resources, `forBuild()` does not check.
    var workspace = BlazeWorkspace.forBuild(
      root: getFolder('/workspace'),
    );
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.binPaths.single, convertPath('/workspace/blaze-bin'));
    expect(workspace.genfiles, convertPath('/workspace/blaze-genfiles'));
  }

  /// Create new files and directories from [paths].
  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path, '');
      }
    }
  }

  /// Expect that [BlazeWorkspace.findFile], given [path], returns [equals].
  void _expectFindFile(String path, {required String equals}) =>
      expect(workspace.findFile(convertPath(path))!.path, convertPath(equals));
}
