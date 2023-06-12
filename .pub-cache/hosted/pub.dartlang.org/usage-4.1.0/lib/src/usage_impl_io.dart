// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder, jsonDecode;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'usage_impl.dart';

/// An interface to a Google Analytics session, suitable for use in command-line
/// applications.
///
/// [analyticsUrl] is an optional replacement for the default Google Analytics
/// URL (`https://www.google-analytics.com/collect`).
///
/// `trackingId`, `applicationName`, and `applicationVersion` values should be supplied.
/// `analyticsUrl` is optional, and lets user's substitute their own analytics URL for
/// the default.
///
/// `documentDirectory` is where the analytics settings are stored. It
/// defaults to the user home directory. For regular `dart:io` apps this doesn't need to
/// be supplied. For Flutter applications, you should pass in a value like
/// `PathProvider.getApplicationDocumentsDirectory()`.
///
/// [batchingDelay] is used to control batching behaviour. Events will be sent
/// batches of 20 after the duration is over from when the first message was
/// sent.
///
/// If [batchingDelay] is `Duration()` messages will be sent when control
/// returns to the event loop.
///
/// Batched messages are sent in batches of up to 20 messages. They will be sent
/// to [analyticsBatchingUrl] defaulting to
/// `https://www.google-analytics.com/batch`.
class AnalyticsIO extends AnalyticsImpl {
  AnalyticsIO(
    String trackingId,
    String applicationName,
    String applicationVersion, {
    String? analyticsUrl,
    String? analyticsBatchingUrl,
    Directory? documentDirectory,
    HttpClient? client,
    Duration? batchingDelay,
  }) : super(
          trackingId,
          IOPersistentProperties(applicationName,
              documentDirPath: documentDirectory?.path),
          IOPostHandler(client: client),
          applicationName: applicationName,
          applicationVersion: applicationVersion,
          analyticsUrl: analyticsUrl,
          analyticsBatchingUrl: analyticsBatchingUrl,
          batchingDelay: batchingDelay,
        ) {
    final locale = getPlatformLocale();
    if (locale != null) {
      setSessionValue('ul', locale);
    }
  }
}

@visibleForTesting
String createUserAgent() {
  final locale = getPlatformLocale() ?? '';

  if (Platform.isAndroid) {
    return 'Mozilla/5.0 (Android; Mobile; $locale)';
  } else if (Platform.isIOS) {
    return 'Mozilla/5.0 (iPhone; U; CPU iPhone OS like Mac OS X; $locale)';
  } else if (Platform.isMacOS) {
    return 'Mozilla/5.0 (Macintosh; Intel Mac OS X; Macintosh; $locale)';
  } else if (Platform.isWindows) {
    return 'Mozilla/5.0 (Windows; Windows; Windows; $locale)';
  } else if (Platform.isLinux) {
    return 'Mozilla/5.0 (Linux; Linux; Linux; $locale)';
  } else {
    // Dart/1.8.0 (macos; macos; macos; en_US)
    var os = Platform.operatingSystem;
    return 'Dart/${getDartVersion()} ($os; $os; $os; $locale)';
  }
}

String userHomeDir() {
  var envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  var value = Platform.environment[envKey];
  return value ?? '.';
}

String getDartVersion() {
  var ver = Platform.version;
  var index = ver.indexOf(' ');
  if (index != -1) ver = ver.substring(0, index);
  return ver;
}

class IOPostHandler extends PostHandler {
  final HttpClient _client;

  IOPostHandler({HttpClient? client})
      : _client = (client ?? HttpClient())..userAgent = createUserAgent();

  @override
  String encodeHit(Map<String, String> hit) {
    return postEncode(hit);
  }

  @override
  Future sendPost(String url, List<String> batch) async {
    var data = batch.join('\n');
    try {
      var req = await _client.postUrl(Uri.parse(url));
      req.write(data);
      var response = await req.close();
      await response.drain();
    } on Exception {
      // Catch errors that can happen during a request, but that we can't do
      // anything about, e.g. a missing internet connection.
    }
  }

  @override
  void close() {
    // Do a force close to ensure that lingering requests will not stall the
    // program.
    _client.close(force: true);
  }
}

JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

class IOPersistentProperties extends PersistentProperties {
  late final File _file;
  late Map _map;

  IOPersistentProperties(String name, {String? documentDirPath}) : super(name) {
    var fileName = '.${name.replaceAll(' ', '_')}';
    documentDirPath ??= userHomeDir();
    _file = File(path.join(documentDirPath, fileName));
    if (!_file.existsSync()) {
      _file.createSync();
    }
    syncSettings();
  }

  IOPersistentProperties.fromFile(File file) : super(path.basename(file.path)) {
    _file = file;
    if (!_file.existsSync()) {
      _file.createSync();
    }
    syncSettings();
  }

  @override
  dynamic operator [](String key) => _map[key];

  @override
  void operator []=(String key, dynamic value) {
    if (value == null && !_map.containsKey(key)) return;
    if (_map[key] == value) return;

    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }

    try {
      _file.writeAsStringSync('${_jsonEncoder.convert(_map)}\n');
    } catch (_) {}
  }

  @override
  void syncSettings() {
    try {
      var contents = _file.readAsStringSync();
      if (contents.isEmpty) contents = '{}';
      _map = jsonDecode(contents);
    } catch (_) {
      _map = {};
    }
  }
}

/// Return the string for the platform's locale; return's `null` if the locale
/// can't be determined.
String? getPlatformLocale() {
  var locale = Platform.localeName;

  // Convert `en_US.UTF-8` to `en_US`.
  var index = locale.indexOf('.');
  if (index != -1) locale = locale.substring(0, index);

  // Convert `en_US` to `en-us`.
  locale = locale.replaceAll('_', '-').toLowerCase();

  return locale;
}
