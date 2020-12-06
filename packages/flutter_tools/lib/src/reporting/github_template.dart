// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of reporting;

/// Provide suggested GitHub issue templates to user when Flutter encounters an error.
class GitHubTemplateCreator {
  GitHubTemplateCreator({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required FlutterProjectFactory flutterProjectFactory,
    @required HttpClient client,
  }) : _fileSystem = fileSystem,
      _logger = logger,
      _flutterProjectFactory = flutterProjectFactory,
      _client = client;

  final FileSystem _fileSystem;
  final Logger _logger;
  final FlutterProjectFactory _flutterProjectFactory;
  final HttpClient _client;

  static String toolCrashSimilarIssuesURL(String errorString) {
    return 'https://github.com/flutter/flutter/issues?q=is%3Aissue+${Uri.encodeQueryComponent(errorString)}';
  }

  /// Restricts exception object strings to contain only information about tool internals.
  static String sanitizedCrashException(dynamic error) {
    if (error is ProcessException) {
      // Suppress args.
      return 'ProcessException: ${error.message} Command: ${error.executable}, OS error code: ${error.errorCode}';
    } else if (error is FileSystemException) {
      // Suppress path.
      return 'FileSystemException: ${error.message}, ${error.osError}';
    } else if (error is SocketException) {
      // Suppress address and port.
      return 'SocketException: ${error.message}, ${error.osError}';
    } else if (error is DevFSException) {
      // Suppress underlying error.
      return 'DevFSException: ${error.message}';
    } else if (error is NoSuchMethodError
      || error is ArgumentError
      || error is VersionCheckError
      || error is MissingDefineException
      || error is UnsupportedError
      || error is UnimplementedError
      || error is StateError
      || error is ProcessExit
      || error is OSError) {
      // These exception objects only reference tool internals, print the whole error.
      return '${error.runtimeType}: $error';
    } else if (error is Error) {
      return '${error.runtimeType}: ${LineSplitter.split(error.stackTrace.toString()).take(1)}';
    } else if (error is String) {
      // Force comma separator to standardize.
      return 'String: <${NumberFormat(null, 'en_US').format(error.length)} characters>';
    }
    // Exception, other.
    return error.runtimeType.toString();
  }

  /// GitHub URL to present to the user containing encoded suggested template.
  ///
  /// Shorten the URL, if possible.
  Future<String> toolCrashIssueTemplateGitHubURL(
      String command,
      dynamic error,
      StackTrace stackTrace,
      String doctorText
    ) async {
    final String errorString = sanitizedCrashException(error);
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
$errorString
```
${LineSplitter.split(stackTrace.toString()).take(25).join('\n')}
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
      project = _flutterProjectFactory.fromDirectory(_fileSystem.currentDirectory);
    } on Exception catch (exception) {
      // pubspec may be malformed.
      return exception.toString();
    }
    try {
      final FlutterManifest manifest = project?.manifest;
      if (project == null || manifest == null || manifest.isEmpty) {
        return 'No pubspec in working directory.';
      }
      final FlutterProjectMetadata metadata = FlutterProjectMetadata(project.metadataFile, _logger);
      final StringBuffer description = StringBuffer()
        ..writeln('**Type**: ${metadata.projectType?.name}')
        ..writeln('**Version**: ${manifest.appVersion}')
        ..writeln('**Material**: ${manifest.usesMaterialDesign}')
        ..writeln('**Android X**: ${manifest.usesAndroidX}')
        ..writeln('**Module**: ${manifest.isModule}')
        ..writeln('**Plugin**: ${manifest.isPlugin}')
        ..writeln('**Android package**: ${manifest.androidPackage}')
        ..writeln('**iOS bundle identifier**: ${manifest.iosBundleIdentifier}')
        ..writeln('**Creation channel**: ${metadata.versionChannel}')
        ..writeln('**Creation framework version**: ${metadata.versionRevision}');

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
          final List<String> pathParts = _fileSystem.path.split(pluginParts[1]);
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
      _logger.printTrace('Attempting git.io shortener: $fullURL');
      final List<int> bodyBytes = utf8.encode('url=${Uri.encodeQueryComponent(fullURL)}');
      final HttpClientRequest request = await _client.postUrl(Uri.parse('https://git.io'));
      request.headers.set(HttpHeaders.contentLengthHeader, bodyBytes.length.toString());
      request.add(bodyBytes);
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 201) {
        url = response.headers[HttpHeaders.locationHeader]?.first;
      } else {
        _logger.printTrace('Failed to shorten GitHub template URL. Server responded with HTTP status code ${response.statusCode}');
      }
    } on Exception catch (sendError) {
      _logger.printTrace('Failed to shorten GitHub template URL: $sendError');
    }

    return url ?? fullURL;
  }
}
