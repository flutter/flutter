// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart' as logging;
import 'package:package_config/package_config.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../dart/package_map.dart';
import '../web_template.dart';

/// Logs [event] to [logger].
///
/// The `event.level` property determines whether the event will
/// be logged as an Error (SEVERE), a warning (WARNING) or a trace
/// (everything else).
void log(Logger logger, logging.LogRecord event) {
  final error = event.error == null ? '' : 'Error: ${event.error}';
  if (event.level >= logging.Level.SEVERE) {
    logger.printError('${event.loggerName}: ${event.message}$error', stackTrace: event.stackTrace);
  } else if (event.level == logging.Level.WARNING) {
    logger.printWarning('${event.loggerName}: ${event.message}$error');
  } else {
    logger.printTrace('${event.loggerName}: ${event.message}$error');
  }
}

/// Finds and returns the directory of the Dart Web Development Service (DWDS).
///
/// This function locates the `dwds` package directory using the current
/// package configuration.
Future<Directory> loadDwdsDirectory(FileSystem fileSystem, Logger logger) async {
  final PackageConfig packageConfig = await currentPackageConfig();
  return fileSystem.directory(packageConfig['dwds']!.packageUriRoot);
}

/// Removes the [basePath] from the beginning of [path].
///
/// If [path] does not start with [basePath], this function returns null.
/// Leading slashes are stripped from the beginning of the resulting path.
String? stripBasePath(String path, String basePath) {
  path = stripLeadingSlash(path);
  if (path.startsWith(basePath)) {
    path = path.substring(basePath.length);
  } else {
    // The given path isn't under base path, return null to indicate that.
    return null;
  }
  return stripLeadingSlash(path);
}

/// Constructs a [WebTemplate] from an HTML file.
///
/// It reads the content of [filename] using [htmlTemplate] and wraps it
/// in a [WebTemplate] object.
WebTemplate getWebTemplate(FileSystem fileSystem, String filename, String fallbackContent) {
  final String htmlContent = htmlTemplate(fileSystem, filename, fallbackContent);
  return WebTemplate(htmlContent);
}

/// Reads the content of an HTML template file.
///
/// This function looks for [filename] in the `web` directory of the
/// current project. If the file exists, its content is returned. Otherwise,
/// [fallbackContent] is returned.
String htmlTemplate(FileSystem fileSystem, String filename, String fallbackContent) {
  final File template = fileSystem.currentDirectory.childDirectory('web').childFile(filename);
  return template.existsSync() ? template.readAsStringSync() : fallbackContent;
}
