// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../convert.dart';
import '../flutter_manifest.dart';
import '../globals.dart' as globals;
import '../project.dart';

/// Provide suggested GitHub issue templates to user when Flutter encounters an error.
class GitHubTemplateCreator {
  GitHubTemplateCreator() :
      _client = (context.get<HttpClientFactory>() == null)
        ? HttpClient()
        : context.get<HttpClientFactory>()();

  final HttpClient _client;

  Future<String> toolCrashSimilarIssuesGitHubURL(String errorString) async {
    final String fullURL = 'https://github.com/flutter/flutter/issues?q=is%3Aissue+${Uri.encodeQueryComponent(errorString)}';
    return await _shortURL(fullURL);
  }

  /// GitHub URL to present to the user containing encoded suggested template.
  ///
  /// Shorten the URL, if possible.
  Future<String> toolCrashIssueTemplateGitHubURL(
      String command,
      String errorString,
      String exception,
      StackTrace stackTrace,
      String doctorText
    ) async {
    final String title = '[tool_crash] $errorString';
    final String body = '''
## Command
```
$command
```

## Steps to Reproduce
1. ...
2. ...
3. ...

## Logs
$exception
```
${LineSplitter.split(stackTrace.toString()).take(20).join('\n')}
```
```
$doctorText
```

## Flutter Application Metadata
${_projectMetadataInformation()}
''';

    final String fullURL = 'https://github.com/flutter/flutter/issues/new?'
      'title=${Uri.encodeQueryComponent(title)}'
      '&body=${Uri.encodeQueryComponent(body)}'
      '&labels=${Uri.encodeQueryComponent('tool,severe: crash')}';

    return await _shortURL(fullURL);
  }

  /// Provide information about the Flutter project in the working directory, if present.
  String _projectMetadataInformation() {
    FlutterProject project;
    try {
      project = FlutterProject.current();
    } on Exception catch (exception) {
      // pubspec may be malformed.
      return exception.toString();
    }
    try {
      final FlutterManifest manifest = project?.manifest;
      if (project == null || manifest == null || manifest.isEmpty) {
        return 'No pubspec in working directory.';
      }
      final StringBuffer description = StringBuffer()
        ..writeln('**Version**: ${manifest.appVersion}')
        ..writeln('**Material**: ${manifest.usesMaterialDesign}')
        ..writeln('**Android X**: ${manifest.usesAndroidX}')
        ..writeln('**Module**: ${manifest.isModule}')
        ..writeln('**Plugin**: ${manifest.isPlugin}')
        ..writeln('**Android package**: ${manifest.androidPackage}')
        ..writeln('**iOS bundle identifier**: ${manifest.iosBundleIdentifier}');

      final File file = project.flutterPluginsFile;
      if (file.existsSync()) {
        description.writeln('### Plugins');
        // Format is:
        // camera=/path/to/.pub-cache/hosted/pub.dartlang.org/camera-0.5.7+2/
        for (final String plugin in project.flutterPluginsFile.readAsLinesSync()) {
          final List<String> pluginParts = plugin.split('=');
          if (pluginParts.length != 2) {
            continue;
          }
          // Write the last part of the path, which includes the plugin name and version.
          // Example: camera-0.5.7+2
          final List<String> pathParts = globals.fs.path.split(pluginParts[1]);
          description.writeln(pathParts.isEmpty ? pluginParts.first : pathParts.last);
        }
      }

      return description.toString();
    } on Exception catch (exception) {
      return exception.toString();
    }
  }

  /// Shorten GitHub URL with git.io API.
  ///
  /// See https://github.blog/2011-11-10-git-io-github-url-shortener.
  Future<String> _shortURL(String fullURL) async {
    String url;
    try {
      globals.printTrace('Attempting git.io shortener: $fullURL');
      final List<int> bodyBytes = utf8.encode('url=${Uri.encodeQueryComponent(fullURL)}');
      final HttpClientRequest request = await _client.postUrl(Uri.parse('https://git.io'));
      request.headers.set(HttpHeaders.contentLengthHeader, bodyBytes.length.toString());
      request.add(bodyBytes);
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 201) {
        url = response.headers[HttpHeaders.locationHeader]?.first;
      } else {
        globals.printTrace('Failed to shorten GitHub template URL. Server responded with HTTP status code ${response.statusCode}');
      }
    } catch (sendError) {
      globals.printTrace('Failed to shorten GitHub template URL: $sendError');
    }

    return url ?? fullURL;
  }
}
