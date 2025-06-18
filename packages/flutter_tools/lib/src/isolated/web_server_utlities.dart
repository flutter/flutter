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


void log(Logger logger, logging.LogRecord event) {
  final String error = event.error == null ? '' : 'Error: ${event.error}';
  if (event.level >= logging.Level.SEVERE) {
    logger.printError('${event.loggerName}: ${event.message}$error', stackTrace: event.stackTrace);
  } else if (event.level == logging.Level.WARNING) {
    // Temporary fix for https://github.com/flutter/flutter/issues/109792
    // TODO(annagrin): Remove the condition after the bogus warning is
    // removed in dwds: https://github.com/dart-lang/webdev/issues/1722
    if (!event.message.contains('No module for')) {
      logger.printWarning('${event.loggerName}: ${event.message}$error');
    }
  } else {
    logger.printTrace('${event.loggerName}: ${event.message}$error');
  }
}

Future<Directory> loadDwdsDirectory(FileSystem fileSystem, Logger logger) async {
  final PackageConfig packageConfig = await currentPackageConfig();
  return fileSystem.directory(packageConfig['dwds']!.packageUriRoot);
}

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

WebTemplate getWebTemplate(FileSystem fileSystem, String filename, String fallbackContent) {
  final String htmlContent = htmlTemplate(fileSystem, filename, fallbackContent);
  return WebTemplate(htmlContent);
}

String htmlTemplate(FileSystem fileSystem, String filename, String fallbackContent) {
  final File template = fileSystem.currentDirectory.childDirectory('web').childFile(filename);
  return template.existsSync() ? template.readAsStringSync() : fallbackContent;
}
