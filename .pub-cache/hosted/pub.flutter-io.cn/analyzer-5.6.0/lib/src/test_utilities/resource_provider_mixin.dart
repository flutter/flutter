// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

/// A mixin for test classes that adds a [ResourceProvider] and utility methods
/// for manipulating the file system. The utility methods all take a posix style
/// path and convert it as appropriate for the actual platform.
mixin ResourceProviderMixin {
  MemoryResourceProvider resourceProvider = MemoryResourceProvider();

  String convertPath(String path) => resourceProvider.convertPath(path);

  void deleteAnalysisOptionsYamlFile(String directoryPath) {
    var path = join(directoryPath, file_paths.analysisOptionsYaml);
    deleteFile(path);
  }

  void deleteFile(String path) {
    String convertedPath = convertPath(path);
    resourceProvider.deleteFile(convertedPath);
  }

  void deleteFolder(String path) {
    String convertedPath = convertPath(path);
    resourceProvider.deleteFolder(convertedPath);
  }

  void deletePackageConfigJsonFile(String directoryPath) {
    var path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    deleteFile(path);
  }

  File getFile(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFile(convertedPath);
  }

  Folder getFolder(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFolder(convertedPath);
  }

  String join(String part1,
          [String? part2,
          String? part3,
          String? part4,
          String? part5,
          String? part6,
          String? part7,
          String? part8]) =>
      resourceProvider.pathContext
          .join(part1, part2, part3, part4, part5, part6, part7, part8);

  void modifyFile(String path, String content) {
    String convertedPath = convertPath(path);
    resourceProvider.modifyFile(convertedPath, content);
  }

  File newAnalysisOptionsYamlFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.analysisOptionsYaml);
    return newFile(path, content);
  }

  @Deprecated('Use newAnalysisOptionsYamlFile() instead')
  File newAnalysisOptionsYamlFile2(String directoryPath, String content) {
    return newAnalysisOptionsYamlFile(directoryPath, content);
  }

  File newBlazeBuildFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.blazeBuild);
    return newFile(path, content);
  }

  File newBuildGnFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.buildGn);
    return newFile(path, content);
  }

  File newFile(String path, String content) {
    String convertedPath = convertPath(path);
    return resourceProvider.newFile(convertedPath, content);
  }

  @Deprecated('Use newFile() instead')
  File newFile2(String path, String content) {
    String convertedPath = convertPath(path);
    return resourceProvider.newFile(convertedPath, content);
  }

  Folder newFolder(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.newFolder(convertedPath);
  }

  File newPackageConfigJsonFile(String directoryPath, String content) {
    String path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    return newFile(path, content);
  }

  File newPubspecYamlFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.pubspecYaml);
    return newFile(path, content);
  }

  Uri toUri(String path) {
    path = convertPath(path);
    return resourceProvider.pathContext.toUri(path);
  }

  String toUriStr(String path) {
    return toUri(path).toString();
  }
}
