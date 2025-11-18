// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart' as fs show File, FileSystem;
import '../base/logger.dart' show Logger;
import '../base/os.dart';
import 'devfs_proxy.dart';

const webDevServerConfigFilePath = 'web_dev_config.yaml';

/// Represents the default value for the web dev server.
///
/// Maps to `localhost` and/or `127.0.0.1`.
const webDevAnyHostDefault = 'any';
const _kLogEntryPrefix = '[WebDevServer]';
const _kServer = 'server';
const _kName = 'name';
const _kValue = 'value';
const _kHost = 'host';
const _kPort = 'port';
const _kHttps = 'https';
const _kProxy = 'proxy';
const _kHeaders = 'headers';
const _kCertKeyPath = 'cert-key-path';
const _kCertPath = 'cert-path';

/// Checks if a given [value] has the expected type [T].
///
/// Throws a [ToolExit] if the [value] is not null and has the wrong type.
T? _validateType<T>({required Object? value, required String fieldName}) {
  if (value != null && value is! T) {
    throwToolExit('$_kLogEntryPrefix $fieldName must be a $T. Found ${value.runtimeType}');
  }
  return value as T?;
}

/// Represents the configuration for the web development server as a [WebDevServerConfig].
@immutable
class WebDevServerConfig {
  const WebDevServerConfig({
    this.headers = const <String, String>{},
    this.host = webDevAnyHostDefault,
    this.port = 0,
    this.https,
    this.proxy = const <ProxyRule>[],
  });

  factory WebDevServerConfig.fromYaml(YamlMap yaml, Logger logger) {
    final String? host = _validateType<String>(value: yaml[_kHost], fieldName: _kHost);
    final int? port = _validateType<int>(value: yaml[_kPort], fieldName: _kPort);
    final YamlMap? https = _validateType<YamlMap>(value: yaml[_kHttps], fieldName: _kHttps);

    final YamlList? headersList = _validateType<YamlList>(
      value: yaml[_kHeaders],
      fieldName: _kHeaders,
    );

    final headers = <String, String>{};
    if (headersList != null) {
      for (final Object? item in headersList) {
        if (item is YamlMap) {
          final YamlMap headerMap = item;
          if (!headerMap.containsKey(_kName) || !headerMap.containsKey(_kValue)) {
            throwToolExit(
              '$_kLogEntryPrefix Each header entry must contain "$_kName" and "$_kValue" keys.',
            );
          }

          final Object? name = headerMap[_kName];
          if (name is! String) {
            throwToolExit(
              '$_kLogEntryPrefix Header "$_kName" must be a non-null String. Found ${name.runtimeType}',
            );
          }

          final Object? value = headerMap[_kValue];
          if (value is! String) {
            throwToolExit(
              '$_kLogEntryPrefix Header "$_kValue" must be a non-null String. Found ${value.runtimeType}',
            );
          }
          headers[name] = value;
        } else {
          throwToolExit(
            '$_kLogEntryPrefix Each header entry must be a map. Found ${item.runtimeType}',
          );
        }
      }
    }

    final YamlList? proxyList = _validateType<YamlList>(value: yaml[_kProxy], fieldName: _kProxy);
    final proxyRules = <ProxyRule>[
      ...?proxyList?.whereType<YamlMap>().map((e) => ProxyRule.fromYaml(e, logger)).nonNulls,
    ];

    return WebDevServerConfig(
      headers: headers,
      host: host ?? webDevAnyHostDefault,
      port: port ?? 0,
      https: https == null ? null : HttpsConfig.fromYaml(https),
      proxy: proxyRules,
    );
  }

  static var _loadFromFileAlreadyLogged = false;

  /// Creates a [WebDevServerConfig] from the `web_dev_config.yaml` file.
  ///
  /// This method is responsible for loading and parsing the configuration
  static Future<WebDevServerConfig> loadFromFile({
    required fs.FileSystem fileSystem,
    required Logger logger,
  }) async {
    final fs.File webDevServerConfigFile = fileSystem.file(webDevServerConfigFilePath);

    if (!webDevServerConfigFile.existsSync()) {
      return const WebDevServerConfig();
    }

    try {
      final String fileContent = await webDevServerConfigFile.readAsString();
      final YamlDocument yamlDoc = loadYamlDocument(fileContent);
      final YamlNode contents = yamlDoc.contents;
      if (contents is! YamlMap ||
          !contents.containsKey(_kServer) ||
          contents[_kServer] is! YamlMap) {
        throwToolExit(
          '$_kLogEntryPrefix Found $webDevServerConfigFilePath configuration file but it was malformed.',
        );
      }

      final serverYaml = contents[_kServer] as YamlMap;
      final fileConfig = WebDevServerConfig.fromYaml(serverYaml, logger);
      if (!_loadFromFileAlreadyLogged) {
        logger.printStatus(
          '$_kLogEntryPrefix Loaded configuration from $webDevServerConfigFilePath',
        );
        logger.printTrace(fileConfig.toString());
        _loadFromFileAlreadyLogged = true;
      }
      return fileConfig;
    } on Exception catch (e) {
      throwToolExit('$_kLogEntryPrefix Error: Failed to parse $webDevServerConfigFilePath: $e');
    }
  }

  /// Creates a copy of a [WebDevServerConfig] with optional overrides.
  WebDevServerConfig copyWith({
    String? host,
    int? port,
    HttpsConfig? https,
    Map<String, String>? headers,
    List<ProxyRule>? proxy,
  }) {
    return WebDevServerConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      https: https ?? this.https,
      headers: {...?headers, ...this.headers},
      proxy: proxy ?? this.proxy,
    );
  }

  final Map<String, String> headers;
  final String host;
  final int port;
  final HttpsConfig? https;
  final List<ProxyRule> proxy;

  @override
  String toString() {
    return '''
WebDevServerConfig:
  $_kHeaders: $headers
  $_kHost: $host
  $_kPort: $port
  $_kHttps: $https
  $_kProxy: $proxy''';
  }
}

/// Represents the [HttpsConfig] for the web dev server
@immutable
class HttpsConfig {
  const HttpsConfig({required this.certPath, required this.certKeyPath});
  factory HttpsConfig.fromYaml(YamlMap yaml) {
    final String? certPath = _validateType<String>(value: yaml[_kCertPath], fieldName: _kCertPath);
    if (certPath == null) {
      throw ArgumentError.value(yaml, 'yaml', '"$_kCertPath" must be defined');
    }

    final String? certKeyPath = _validateType<String>(
      value: yaml[_kCertKeyPath],
      fieldName: _kCertKeyPath,
    );
    if (certKeyPath == null) {
      throw ArgumentError.value(yaml, 'yaml', '"$_kCertKeyPath" must be defined');
    }

    return HttpsConfig(certPath: certPath, certKeyPath: certKeyPath);
  }

  /// If [tlsCertPath] and [tlsCertKeyPath] are both [String] return an instance.
  ///
  /// If they are both `null`, return `null`.
  ///
  /// Otherwise, throw an [Exception].
  static HttpsConfig? parse(Object? tlsCertPath, Object? tlsCertKeyPath) =>
      switch ((tlsCertPath, tlsCertKeyPath)) {
        (final String certPath, final String certKeyPath) => HttpsConfig(
          certPath: certPath,
          certKeyPath: certKeyPath,
        ),
        (null, null) => null,
        (final Object? certPath, final Object? certKeyPath) => throw ArgumentError(
          'When providing TLS certificates, both `tlsCertPath` and '
          '`tlsCertKeyPath` must be provided as strings. '
          'Found: tlsCertPath: ${certPath ?? 'null'}, tlsCertKeyPath: ${certKeyPath ?? 'null'}',
        ),
      };

  /// Creates a copy of this [HttpsConfig] with optional overrides.
  HttpsConfig copyWith({String? certPath, String? certKeyPath}) => HttpsConfig(
    certPath: certPath ?? this.certPath,
    certKeyPath: certKeyPath ?? this.certKeyPath,
  );

  final String certPath;
  final String certKeyPath;

  @override
  String toString() {
    return '''
HttpsConfig:
  $_kCertPath: $certPath
  $_kCertKeyPath: $certKeyPath''';
  }
}

/// Finds a free port or validates the provided port is within the valid range
Future<int> resolvePort(int? port, OperatingSystemUtils os) async {
  if (port == null) {
    return os.findFreePort();
  }
  if (port < 0 || port > 65535) {
    throwToolExit('''
Invalid port: $port
Please provide a valid TCP port (an integer between 0 and 65535, inclusive).
''');
  }
  return port;
}
