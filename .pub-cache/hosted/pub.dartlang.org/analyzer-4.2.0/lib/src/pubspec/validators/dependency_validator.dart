// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class DependencyValidator extends BasePubspecValidator {
  DependencyValidator(super.provider, super.source);

  /// Validate the value of the required `name` field.
  void validate(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    Map<dynamic, YamlNode> declaredDependencies = _getDeclaredDependencies(
        reporter, contents, PubspecField.DEPENDENCIES_FIELD);
    Map<dynamic, YamlNode> declaredDevDependencies = _getDeclaredDependencies(
        reporter, contents, PubspecField.DEV_DEPENDENCIES_FIELD);

    bool isPublishablePackage = false;
    var version = contents[PubspecField.VERSION_FIELD];
    if (version != null) {
      var publishTo = asString(contents[PubspecField.PUBLISH_TO_FIELD]);
      if (publishTo != 'none') {
        isPublishablePackage = true;
      }
    }

    for (var dependency in declaredDependencies.entries) {
      _validatePathEntries(reporter, dependency.value, isPublishablePackage);
    }

    for (var dependency in declaredDevDependencies.entries) {
      var packageName = dependency.key as YamlNode;
      if (declaredDependencies.containsKey(packageName)) {
        reportErrorForNode(reporter, packageName,
            PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY, [packageName.value]);
      }
      _validatePathEntries(reporter, dependency.value, false);
    }
  }

  /// Return a map whose keys are the names of declared dependencies and whose
  /// values are the specifications of those dependencies. The map is extracted
  /// from the given [contents] using the given [key].
  Map<dynamic, YamlNode> _getDeclaredDependencies(
      ErrorReporter reporter, Map<dynamic, YamlNode> contents, String key) {
    var field = contents[key];
    if (field == null || (field is YamlScalar && field.value == null)) {
      return <String, YamlNode>{};
    } else if (field is YamlMap) {
      return field.nodes;
    }
    reportErrorForNode(
        reporter, field, PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP, [key]);
    return <String, YamlNode>{};
  }

  /// Validate that `path` entries reference valid paths.
  ///
  /// Valid paths are directories that:
  ///
  /// 1. exist,
  /// 2. contain a pubspec.yaml file
  ///
  /// If [checkForPathAndGitDeps] is true, `git` or `path` dependencies will
  /// be marked invalid.
  void _validatePathEntries(ErrorReporter reporter, YamlNode dependency,
      bool checkForPathAndGitDeps) {
    if (dependency is YamlMap) {
      var pathEntry = asString(dependency[PubspecField.PATH_FIELD]);
      if (pathEntry != null) {
        YamlNode pathKey() => dependency.getKey(PubspecField.PATH_FIELD)!;
        YamlNode pathValue() => dependency.valueAt(PubspecField.PATH_FIELD)!;

        if (pathEntry.contains(r'\')) {
          reportErrorForNode(reporter, pathValue(),
              PubspecWarningCode.PATH_NOT_POSIX, [pathEntry]);
          return;
        }
        var context = provider.pathContext;
        var normalizedPath = context.joinAll(path.posix.split(pathEntry));
        var packageRoot = context.dirname(source.fullName);
        var dependencyPath = context.join(packageRoot, normalizedPath);
        dependencyPath = context.absolute(dependencyPath);
        dependencyPath = context.normalize(dependencyPath);
        var packageFolder = provider.getFolder(dependencyPath);
        if (!packageFolder.exists) {
          reportErrorForNode(reporter, pathValue(),
              PubspecWarningCode.PATH_DOES_NOT_EXIST, [pathEntry]);
        } else {
          if (!packageFolder.getChild(file_paths.pubspecYaml).exists) {
            reportErrorForNode(reporter, pathValue(),
                PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST, [pathEntry]);
          }
        }
        if (checkForPathAndGitDeps) {
          reportErrorForNode(reporter, pathKey(),
              PubspecWarningCode.INVALID_DEPENDENCY, [PubspecField.PATH_FIELD]);
        }
      }

      var gitEntry = dependency[PubspecField.GIT_FIELD];
      if (gitEntry != null && checkForPathAndGitDeps) {
        reportErrorForNode(reporter, dependency.getKey(PubspecField.GIT_FIELD)!,
            PubspecWarningCode.INVALID_DEPENDENCY, [PubspecField.GIT_FIELD]);
      }
    }
  }
}
