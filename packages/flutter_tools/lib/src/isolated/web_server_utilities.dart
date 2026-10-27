// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart' as logging;

import '../base/file_system.dart';
import '../base/logger.dart';
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

/// Whether [requestPath] may be treated as a path relative to a trusted web
/// server root.
///
/// [Uri.resolve] interprets its argument as a URI *reference*, not as a path. A
/// reference that carries a scheme (`file:///etc/passwd`), an authority
/// (`//host/share`) or an absolute path replaces the base instead of being
/// appended below it, so resolving an untrusted request path against a trusted
/// root can select a location outside that root. Request paths arrive from the
/// network, so anything that is not a relative reference is rejected before it
/// reaches [Uri.resolve].
///
/// Backslashes and NUL are rejected as well, because the resolved result is
/// handed to the filesystem. `.` and `..` segments are allowed here and handled
/// by the containment check in [resolveRequestPathUnder], which keeps paths
/// that normalize back inside the root working.
bool isRelativeRequestPath(String requestPath) {
  if (requestPath.isEmpty) {
    return false;
  }
  if (requestPath.contains(r'\') || requestPath.contains('\u0000')) {
    return false;
  }
  // An absolute-path reference, which also covers a `//authority` reference.
  if (requestPath.startsWith('/')) {
    return false;
  }
  // In a relative-path reference the first segment cannot contain a colon, or
  // it parses as a scheme instead (RFC 3986 section 4.2). This also rejects a
  // Windows drive letter such as `C:/Windows/win.ini`.
  final int firstSlash = requestPath.indexOf('/');
  final int firstColon = requestPath.indexOf(':');
  if (firstColon != -1 && (firstSlash == -1 || firstColon < firstSlash)) {
    return false;
  }
  return true;
}

/// Resolves the untrusted [requestPath] against the trusted directory [root].
///
/// Returns null if [requestPath] is not a relative reference, or if resolving
/// it does not land inside [root]. Only a location below [root] is ever
/// returned, so each search root a server consults keeps its own boundary.
Uri? resolveRequestPathUnder(
  Uri root,
  String requestPath, {
  required FileSystem fileSystem,
  required bool windows,
}) {
  if (!isRelativeRequestPath(requestPath)) {
    return null;
  }
  final Uri candidate;
  try {
    candidate = root.resolve(requestPath);
  } on FormatException {
    // A reference that does not parse cannot name a file below [root].
    return null;
  }
  if (candidate.scheme != root.scheme || candidate.authority != root.authority) {
    return null;
  }
  final String rootPath;
  final String candidatePath;
  try {
    rootPath = root.toFilePath(windows: windows);
    candidatePath = candidate.toFilePath(windows: windows);
  } on UnsupportedError {
    // `toFilePath` rejects a URI that does not name a file path at all, such as
    // one whose decoded segment contains a separator (`a%2Fb`) or, on Windows,
    // a colon. Those reach here from a request path, so they are answered
    // instead of being thrown out of the handler.
    return null;
  }
  // Compares whole path components, and on Windows compares case-insensitively.
  if (!fileSystem.path.isWithin(rootPath, candidatePath)) {
    return null;
  }
  return candidate;
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
