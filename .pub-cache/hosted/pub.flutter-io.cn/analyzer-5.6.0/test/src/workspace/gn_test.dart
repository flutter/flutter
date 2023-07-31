// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GnWorkspaceTest);
    defineReflectiveTests(GnWorkspacePackageTest);
  });
}

@reflectiveTest
class GnWorkspacePackageTest with ResourceProviderMixin {
  void test_contains_differentPackageInWorkspace() {
    GnWorkspace workspace = _buildStandardGnWorkspace();
    newBuildGnFile('/ws/some/code', '');
    var targetFile = newFile('/ws/some/code/lib/code.dart', '');

    var package = workspace.findPackageFor(targetFile.path)!;
    // A file that is _not_ in this package is not required to have a BUILD.gn
    // file above it, for simplicity and reduced I/O.
    expect(
        package
            .contains(TestSource(convertPath('/ws/some/other/code/file.dart'))),
        isFalse);
  }

  void test_contains_differentWorkspace() {
    GnWorkspace workspace = _buildStandardGnWorkspace();
    newBuildGnFile('/ws/some/code', '');
    var targetFile = newFile('/ws/some/code/lib/code.dart', '');

    var package = workspace.findPackageFor(targetFile.path)!;
    expect(package.contains(TestSource(convertPath('/ws2/some/file.dart'))),
        isFalse);
  }

  void test_contains_samePackage() {
    GnWorkspace workspace = _buildStandardGnWorkspace();
    newBuildGnFile('/ws/some/code', '');
    var targetFile = newFile('/ws/some/code/lib/code.dart', '');
    var targetFile2 = newFile('/ws/some/code/lib/code2.dart', '');
    var targetFile3 = newFile('/ws/some/code/lib/src/code3.dart', '');
    var targetBinFile = newFile('/ws/some/code/bin/code.dart', '');
    var targetTestFile = newFile('/ws/some/code/test/code_test.dart', '');

    var package = workspace.findPackageFor(targetFile.path)!;
    expect(package.contains(TestSource(targetFile2.path)), isTrue);
    expect(package.contains(TestSource(targetFile3.path)), isTrue);
    expect(package.contains(TestSource(targetBinFile.path)), isTrue);
    expect(package.contains(TestSource(targetTestFile.path)), isTrue);
  }

  void test_contains_subPackage() {
    GnWorkspace workspace = _buildStandardGnWorkspace();
    newBuildGnFile('/ws/some/code', '');
    newFile('/ws/some/code/lib/code.dart', '');
    newBuildGnFile('/ws/some/code/testing', '');
    newFile('/ws/some/code/testing/lib/testing.dart', '');

    var package =
        workspace.findPackageFor(convertPath('/ws/some/code/lib/code.dart'))!;
    expect(
        package.contains(
            TestSource(convertPath('/ws/some/code/testing/lib/testing.dart'))),
        isFalse);
  }

  void test_findPackageFor_buildFileExists() {
    GnWorkspace workspace = _buildStandardGnWorkspace();
    newBuildGnFile('/ws/some/code', '');
    var targetFile = newFile('/ws/some/code/lib/code.dart', '');

    var package = workspace.findPackageFor(targetFile.path)!;
    expect(package.root, convertPath('/ws/some/code'));
    expect(package.workspace, equals(workspace));
  }

  void test_packagesAvailableTo() {
    GnWorkspace workspace = _buildStandardGnWorkspace();
    newBuildGnFile('/ws/some/code', '');
    var libraryPath = newFile('/ws/some/code/lib/code.dart', '').path;
    var package = workspace.findPackageFor(libraryPath)!;
    var packages = package.packagesAvailableTo(libraryPath);
    expect(
      packages.packages.map((e) => e.name),
      unorderedEquals(['p1', 'workspace']),
    );
  }

  GnWorkspace _buildStandardGnWorkspace() {
    newFolder('/ws/.jiri_root');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/ws/.fx-build-dir', '$buildDir\n');
    newFile(
        '/ws/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "p1",
      "packageUri": "lib",
      "rootUri": "some/path/"
    },
    {
      "languageVersion": "2.2",
      "name": "workspace",
      "packageUri": "lib",
      "rootUri": ""
    }
  ]
}''');
    newFolder('/ws/some/code');
    var buildGnFile = newBuildGnFile('/ws/some/code', '');
    var gnWorkspace = GnWorkspace.find(buildGnFile)!;
    expect(gnWorkspace.isBlaze, isFalse);
    return gnWorkspace;
  }
}

@reflectiveTest
class GnWorkspaceTest with ResourceProviderMixin {
  void test_find_noJiriRoot() {
    newFolder('/workspace');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    var workspace = GnWorkspace.find(buildGnFile);
    expect(workspace, isNull);
  }

  void test_find_withRoot() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.fx-build-dir', '$buildDir\n');
    newFile(
      '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
      '',
    );
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_packages() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.fx-build-dir', '$buildDir\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "flutter",
      "packageUri": "lib",
      "rootUri": "$packageUri"
    }
  ]
}''');
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
      workspace.packages.packages,
      unorderedEquals([
        _PackageMatcher(
          name: 'flutter',
          rootFolder: getFolder(packageLocation),
        ),
      ]),
    );
  }

  void test_packages_absoluteBuildDir() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    String buildDir = convertPath('/workspace/out/debug-x87_128');
    newFile('/workspace/.fx-build-dir', '$buildDir\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "flutter",
      "packageUri": "lib",
      "rootUri": "$packageUri"
    }
  ]
}''');
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
      workspace.packages.packages,
      unorderedEquals([
        _PackageMatcher(
          name: 'flutter',
          rootFolder: getFolder(packageLocation),
        ),
      ]),
    );
  }

  void test_packages_fallbackBuildDir() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "flutter",
      "packageUri": "lib",
      "rootUri": "$packageUri"
    }
  ]
}''');
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
      workspace.packages.packages,
      unorderedEquals([
        _PackageMatcher(
          name: 'flutter',
          rootFolder: getFolder(packageLocation),
        ),
      ]),
    );
  }

  void test_packages_fallbackBuildDirWithUselessConfig() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    newFile('/workspace/.fx-build-dir', '');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "flutter",
      "packageUri": "lib",
      "rootUri": "$packageUri"
    }
  ]
}''');
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
      workspace.packages.packages,
      unorderedEquals([
        _PackageMatcher(
          name: 'flutter',
          rootFolder: getFolder(packageLocation),
        ),
      ]),
    );
  }

  void test_packages_multipleCandidates() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    String buildDir = convertPath('out/release-y22_256');
    newFile('/workspace/.fx-build-dir', '$buildDir\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "flutter",
      "packageUri": "lib1",
      "rootUri": "$packageUri"
    }
  ]
}''');
    String otherPackageLocation = convertPath('/workspace/here/too');
    Uri otherPackageUri =
        resourceProvider.pathContext.toUri(otherPackageLocation);
    newFile(
        '/workspace/out/release-y22_256/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "rettulf",
      "packageUri": "lib2",
      "rootUri": "$otherPackageUri"
    }
  ]
}''');
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
      workspace.packages.packages,
      unorderedEquals([
        _PackageMatcher(
          name: 'rettulf',
          rootFolder: getFolder(otherPackageLocation),
          libFolder: getFolder('$otherPackageLocation/lib2'),
        ),
      ]),
    );
  }

  void test_packages_multipleFiles() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    var buildGnFile = newBuildGnFile('/workspace/some/code', '');
    newPubspecYamlFile('/workspace/some/code', '');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.fx-build-dir', '$buildDir\n');
    String packageOneLocation = convertPath('/workspace/this/is/the/package');
    Uri packageOneUri = resourceProvider.pathContext.toUri(packageOneLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "flutter",
      "packageUri": "one/lib",
      "rootUri": "$packageOneUri"
    }
  ]
}''');
    String packageTwoLocation =
        convertPath('/workspace/this/is/the/other/package');
    Uri packageTwoUri = resourceProvider.pathContext.toUri(packageTwoLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_test_package_config.json',
        '''{
  "configVersion": 2,
  "packages": [
    {
      "languageVersion": "2.2",
      "name": "rettulf",
      "packageUri": "two/lib",
      "rootUri": "$packageTwoUri"
    }
  ]
}''');
    var workspace = GnWorkspace.find(buildGnFile)!;
    expect(workspace.root, convertPath('/workspace'));
    expect(
      workspace.packages.packages,
      unorderedEquals([
        _PackageMatcher(
          name: 'flutter',
          rootFolder: getFolder(packageOneLocation),
          libFolder: getFolder('$packageOneLocation/one/lib'),
        ),
        _PackageMatcher(
          name: 'rettulf',
          rootFolder: getFolder(packageTwoLocation),
          libFolder: getFolder('$packageTwoLocation/two/lib'),
        ),
      ]),
    );
  }
}

class _PackageMatcher extends Matcher {
  final String name;
  final Folder rootFolder;
  final Folder libFolder;

  _PackageMatcher({
    required this.name,
    required this.rootFolder,
    Folder? libFolder,
  }) : libFolder = libFolder ?? rootFolder.getChildAssumingFolder('lib');

  @override
  Description describe(Description description) => description
      .add('Package(name:')
      .addDescriptionOf(name)
      .add(', rootFolder:')
      .addDescriptionOf(rootFolder.path)
      .add(')');

  @override
  bool matches(Object? item, Map matchState) {
    return item is Package &&
        item.name == name &&
        item.rootFolder == rootFolder &&
        item.libFolder == libFolder;
  }
}
