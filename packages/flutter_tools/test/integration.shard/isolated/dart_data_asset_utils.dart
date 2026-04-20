// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:yaml_edit/yaml_edit.dart' show YamlEditor;

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;
const packageName = 'data_asset_app';
const packageNameDependency = 'data_asset_package';

void setUpAllDataAssets() {
  processManager.runSync(<String>[flutterBin, 'config', '--enable-native-assets']);
  processManager.runSync(<String>[flutterBin, 'config', '--enable-dart-data-assets']);
}

late Directory tempDirectory;
late Directory appRoot;
late Directory dependencyRoot;

Future<void> setUpDataAssets() async {
  // Do not reuse project structure to be able to make local changes
  tempDirectory = fileSystem.directory(
    fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync(),
  );
  final Directory integrationTestsDir = tempDirectory
      .childDirectory('dev')
      .childDirectory('integration_tests');

  appRoot = integrationTestsDir.childDirectory(packageName);
  appRoot.createSync(recursive: true);
  copyTestProject(packageName, appRoot);
  await pinDependencies(appRoot.childFile('pubspec.yaml'));

  dependencyRoot = integrationTestsDir.childDirectory(packageNameDependency);
  dependencyRoot.createSync(recursive: true);
  copyTestProject(packageNameDependency, dependencyRoot);
  await pinDependencies(dependencyRoot.childFile('pubspec.yaml'));

  expect(
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'get',
    ], workingDirectory: dependencyRoot.path),
    const ProcessResultMatcher(),
  );
  expect(
    await processManager.run(<String>[flutterBin, 'pub', 'get'], workingDirectory: appRoot.path),
    const ProcessResultMatcher(),
  );
}

void tearDownDataAssets() {
  tryToDelete(tempDirectory);
}

Future<void> modifyPubspec(Directory dir, void Function(YamlEditor editor) modify) async {
  final File pubspecFile = dir.childFile('pubspec.yaml');
  final String content = await pubspecFile.readAsString();
  final yamlEditor = YamlEditor(content);
  modify(yamlEditor);
  pubspecFile.writeAsStringSync(yamlEditor.toString());
}

void copyTestProject(String sourceName, Directory targetDirectory) {
  final Directory flutterRoot = fileSystem.directory(getFlutterRoot());
  final Directory sourceDirectory = flutterRoot
      .childDirectory('dev')
      .childDirectory('integration_tests')
      .childDirectory(sourceName);

  if (!sourceDirectory.existsSync()) {
    throw Exception('Source directory ${sourceDirectory.path} does not exist.');
  }

  for (final FileSystemEntity entity in sourceDirectory.listSync(recursive: true)) {
    final String relativePath = fileSystem.path.relative(entity.path, from: sourceDirectory.path);
    if (entity is Directory) {
      targetDirectory.childDirectory(relativePath).createSync(recursive: true);
    } else if (entity is File) {
      final File targetFile = targetDirectory.childFile(relativePath);
      targetFile.parent.createSync(recursive: true);
      entity.copySync(targetFile.path);
      if (relativePath == 'pubspec.yaml') {
        String content = targetFile.readAsStringSync();
        content = content.replaceFirst('resolution: workspace', '');
        targetFile.writeAsStringSync(content);
      }
    }
  }
}

void writeHookLibrary(
  Directory root,
  Map<String, String> dataAssets, {
  required List<String> available,
  String namePrefix = 'data/',
  String filePrefix = 'data/',
}) {
  final File hookFile = root.childDirectory('hook').childFile('build.dart');
  final String content = hookFile.readAsStringSync();
  final assetList = "<String>[${available.map((String id) => "'$id'").join(', ')}]";
  String newContent = content.replaceFirst(
    RegExp(r'final assets = <String>\[[^\]]*\]; // @assets'),
    'final assets = $assetList; // @assets',
  );
  newContent = newContent.replaceFirst(RegExp(r"name: '.*\$id'"), "name: '$namePrefix\$id'");
  newContent = newContent.replaceFirst(
    RegExp(r"file: input.packageRoot.resolve\('.*\$id'\)"),
    "file: input.packageRoot.resolve('$filePrefix\$id')",
  );
  writeFile(hookFile, newContent);

  for (final MapEntry(:key, :value) in dataAssets.entries) {
    writeFile(root.childDirectory('data').childFile(key), value);
  }
}

void writeAssets(Map<String, String> dataAssets, Directory root, {String subdir = 'data'}) {
  final Directory targetDir = subdir.isEmpty ? root : root.childDirectory(subdir);
  if (targetDir.existsSync() && subdir.isNotEmpty) {
    targetDir.deleteSync(recursive: true);
  }
  targetDir.createSync(recursive: true);
  dataAssets.forEach((String id, String content) {
    writeFile(targetDir.childFile(id), content);
  });
}

void writeHelperLibrary(Directory root, String version, List<String> assetIds) {
  final File helperFile = root.childDirectory('lib').childFile('helper.dart');
  final String content = helperFile.readAsStringSync();
  final assetList =
      "<String>[${assetIds.map((String id) => "'packages/$packageName/data/$id'").join(', ')}]";
  String newContent = content.replaceFirst(
    RegExp(r"const version = '\w+'; // @version"),
    "const version = '$version'; // @version",
  );
  newContent = newContent.replaceFirst(
    RegExp(r'final assets = <String>\[[^\]]*\]; // @assets'),
    'final assets = $assetList; // @assets',
  );
  helperFile.writeAsStringSync(newContent);
}

void writeFile(File file, String content) => file
  ..createSync(recursive: true)
  ..writeAsStringSync(content);
