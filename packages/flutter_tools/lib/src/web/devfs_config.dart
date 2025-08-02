// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart' as fs;
import '../globals.dart' as globals;
import 'devfs_proxy.dart';

const webDevServerConfigFilePath = 'web_dev_config.yaml';

@immutable
class WebDevServerConfig {
  const WebDevServerConfig({
    this.headers = const <String, String>{},
    this.host = 'any',
    this.port = 0,
    this.https,
    this.proxy = const <ProxyRule>[],
  });

  factory WebDevServerConfig.fromYaml(YamlMap yaml) {
    final headers = <String, String>{};
    if (yaml['headers'] != null) {
      if (yaml['headers'] is! YamlList) {
        throwToolExit(
          '[WebDevServer] Headers must be a List of maps. Found ${yaml['headers'].runtimeType}',
        );
      }
      final headersList = yaml['headers'] as YamlList;
      for (final Object? item in headersList) {
        if (item is! YamlMap) {
          throwToolExit(
            '[WebDevServer] Each header entry must be a map with "name" and "value" keys. Found ${item.runtimeType}',
          );
        }
        final YamlMap headerMap = item;
        if (!headerMap.containsKey('name') || !headerMap.containsKey('value')) {
          throwToolExit('[WebDevServer] Each header entry must contain "name" and "value" keys.');
        }
        final Object? name = headerMap['name'];
        final Object? value = headerMap['value'];

        if (name is! String || value is! String) {
          throwToolExit(
            '[WebDevServer] Header "name" and "value" must be strings. Found name: ${name.runtimeType}, value: ${value.runtimeType}',
          );
        }
        headers[name] = value;
      }
    }
    if (yaml['host'] is! String && yaml['host'] != null) {
      throwToolExit('[WebDevServer] host must be a String. Found ${yaml['host'].runtimeType}');
    }
    if (yaml['port'] is! int && yaml['port'] != null) {
      throwToolExit('[WebDevServer] port must be an int. Found ${yaml['port'].runtimeType}');
    }
    if (yaml['https'] is! YamlMap && yaml['https'] != null) {
      throwToolExit('[WebDevServer] Https must be a Map. Found ${yaml['https'].runtimeType}');
    }

    final proxyRules = <ProxyRule>[];
    if (yaml['proxy'] != null) {
      if (yaml['proxy'] is! YamlList) {
        throwToolExit('[WebDevServer]Proxy must be a list. Found ${yaml['proxy'].runtimeType}');
      }
      final proxyList = yaml['proxy'] as YamlList;
      for (final dynamic item in proxyList) {
        if (item is YamlMap) {
          final ProxyRule? rule = ProxyRule.fromYaml(item);
          if (rule != null) {
            proxyRules.add(rule);
          }
        }
      }
    }

    return WebDevServerConfig(
      headers: headers,
      host: yaml['host'] as String? ?? 'any',
      port: yaml['port'] as int? ?? 0,
      https: yaml['https'] == null ? null : HttpsConfig.fromYaml(yaml['https'] as YamlMap),
      proxy: proxyRules,
    );
  }

  static Future<WebDevServerConfig> loadFromFile({
    String? overrideHostname,
    String? overridePort,
    String? overrideTlsCertPath,
    String? overrideTlsCertKeyPath,
    Map<String, String>? extraHeaders,
    List<String>? browserFlags,
  }) async {
    var fileConfig = const WebDevServerConfig();
    final fs.File webDevServerConfigFile = globals.fs.file(webDevServerConfigFilePath);

    if (webDevServerConfigFile.existsSync()) {
      try {
        final String fileContent = await webDevServerConfigFile.readAsString();
        final YamlDocument yamlDoc = loadYamlDocument(fileContent);
        final YamlNode contents = yamlDoc.contents;
        if (contents is! YamlMap ||
            !contents.containsKey('server') ||
            contents['server'] is! YamlMap) {
          throwToolExit(
            '"[WebDevServer] $webDevServerConfigFilePath" file is missing or malformed.',
          );
        }

        final serverYaml = contents['server'] as YamlMap;
        fileConfig = WebDevServerConfig.fromYaml(serverYaml);
        globals.printStatus(
          '\n [WebDevServer] Loaded configuration from $webDevServerConfigFilePath',
        );
        globals.printTrace(fileConfig.toString());
      } on Exception catch (e) {
        throwToolExit('[WebDevServer] Error: Failed to parse $webDevServerConfigFilePath: $e');
      }
    }

    HttpsConfig? httpsOverride;
    if (overrideTlsCertPath != null || overrideTlsCertKeyPath != null) {
      httpsOverride = HttpsConfig(
        certPath: overrideTlsCertPath,
        certKeyPath: overrideTlsCertKeyPath,
      );
    }

    final combinedHeaders = <String, String>{...fileConfig.headers, ...?extraHeaders};

    return fileConfig.copyWith(
      host: overrideHostname,
      port: overridePort != null ? int.tryParse(overridePort) : null,
      https: httpsOverride,
      headers: combinedHeaders,
    );
  }

  /// Creates a new [WebDevServerConfig] by overriding existing properties
  /// with the provided non-null values.
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
      headers: headers ?? this.headers,
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
  headers: $headers
  host: $host
  port: $port
  https: $https
  proxy: $proxy''';
  }
}

@immutable
class HttpsConfig {
  const HttpsConfig({required this.certPath, required this.certKeyPath});

  factory HttpsConfig.fromYaml(YamlMap yaml) {
    if (yaml['cert-path'] is! String && yaml['cert-path'] != null) {
      throwToolExit(
        '[WebDevServer] Https cert-path must be a String. Found ${yaml['cert-path'].runtimeType}',
      );
    }
    if (yaml['cert-key-path'] is! String && yaml['cert-key-path'] != null) {
      throwToolExit(
        '[WebDevServer] Https cert-key-path must be a String. Found ${yaml['cert-key-path'].runtimeType}',
      );
    }
    return HttpsConfig(
      certPath: yaml['cert-path'] as String?,
      certKeyPath: yaml['cert-key-path'] as String?,
    );
  }

  final String? certPath;
  final String? certKeyPath;

  @override
  String toString() {
    return '''
    HttpsConfig:
        certPath: $certPath
        certKeyPath: $certKeyPath''';
  }
}

Future<int> resolvePort(int? port) async {
  if (port == null) {
    return globals.os.findFreePort();
  }
  if (port < 0 || port > 65535) {
    throwToolExit('''
Invalid port: $port
Please provide a valid TCP port (an integer between 0 and 65535, inclusive).
''');
  }
  return port;
}
