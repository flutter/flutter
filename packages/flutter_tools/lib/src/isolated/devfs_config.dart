// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../globals.dart' as globals;
import 'devfs_proxy.dart';

const String devConfigFilePath = 'web_dev_config.yaml';

@immutable
class DevConfig {
  const DevConfig({
    this.headers = const <String, String>{},
    this.host = 'any',
    this.port,
    this.https,
    this.proxy = const <ProxyRule>[],
  });

  factory DevConfig.fromYaml(YamlMap yaml) {
    final Map<String, String> headers = <String, String>{};
    if (yaml['headers'] != null) {
      if (yaml['headers'] is! YamlList) {
        throwToolExit('Headers must be a List of maps. Found ${yaml['headers'].runtimeType}');
      }
      final YamlList headersList = yaml['headers'] as YamlList;
      for (final dynamic item in headersList) {
        if (item is! YamlMap) {
          throwToolExit(
            'Each header entry must be a map with "name" and "value" keys. Found ${item.runtimeType}',
          );
        }
        final YamlMap headerMap = item;
        if (!headerMap.containsKey('name') || !headerMap.containsKey('value')) {
          throwToolExit('Each header entry must contain "name" and "value" keys.');
        }
        final dynamic name = headerMap['name'];
        final dynamic value = headerMap['value'];

        if (name is! String || value is! String) {
          throwToolExit(
            'Header "name" and "value" must be strings. Found name: ${name.runtimeType}, value: ${value.runtimeType}',
          );
        }
        headers[name] = value;
      }
    }
    if (yaml['host'] is! String && yaml['host'] != null) {
      throwToolExit('Host must be a String. Found ${yaml['host'].runtimeType}');
    }
    if (yaml['port'] is! int && yaml['port'] != null) {
      throwToolExit('Port must be an int. Found ${yaml['port'].runtimeType}');
    }
    if (yaml['https'] is! YamlMap && yaml['https'] != null) {
      throwToolExit('Https must be a Map. Found ${yaml['https'].runtimeType}');
    }

    final List<ProxyRule> proxyRules = <ProxyRule>[];
    if (yaml['proxy'] != null) {
      if (yaml['proxy'] is! YamlList) {
        throwToolExit('Proxy must be a list. Found ${yaml['proxy'].runtimeType}');
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

    return DevConfig(
      headers: headers,
      host: yaml['host'] as String?,
      port: yaml['port'] as int?,
      https: yaml['https'] == null ? null : HttpsConfig.fromYaml(yaml['https'] as YamlMap),
      proxy: proxyRules,
    );
  }

  final Map<String, String> headers;
  final String? host;
  final int? port;
  final HttpsConfig? https;
  final List<ProxyRule> proxy;

  @override
  String toString() {
    return '''
  DevConfig:
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
      throwToolExit('Https cert-path must be a String. Found ${yaml['cert-path'].runtimeType}');
    }
    if (yaml['cert-key-path'] is! String && yaml['cert-key-path'] != null) {
      throwToolExit(
        'Https cert-key-path must be a String. Found ${yaml['cert-key-path'].runtimeType}',
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

T? _getOverriddenValue<T>(String filedName, T? fileValue, T? cliValue) {
  if (cliValue != null) {
    if (fileValue != null && cliValue != fileValue) {
      globals.printStatus(
        'Overriding $filedName from $devConfigFilePath ($fileValue) with command-line argument ($cliValue)',
      );
    }
    return cliValue;
  }
  return fileValue;
}

Future<DevConfig> loadDevConfig({
  String? hostname,
  String? port,
  String? tlsCertPath,
  String? tlsCertKeyPath,
  Map<String, String>? headers,
  int? debugPort,
  List<String>? browserFlags,
}) async {
  final io.File devConfigFile = globals.fs.file(devConfigFilePath);
  DevConfig fileConfig = const DevConfig();

  if (!devConfigFile.existsSync()) {
    globals.printStatus('No $devConfigFilePath found');
  } else {
    try {
      final String devConfigContent = await devConfigFile.readAsString();
      final YamlDocument yamlDoc = loadYamlDocument(devConfigContent);
      final YamlNode contents = yamlDoc.contents;
      if (contents is! YamlMap) {
        throw YamlException(
          '$devConfigFilePath file found, but it must be a YAML map (e.g., "server:"). Found a ${contents.runtimeType} instead.',
          contents.span,
        );
      }

      if (!contents.containsKey('server') || contents['server'] is! YamlMap) {
        final SourceSpan span = (contents.containsKey('server') && contents['server'] is YamlNode)
            ? (contents['server'] as YamlNode).span
            : contents.span;
        throw YamlException(
          '"$devConfigFilePath" file found, but the "server" key is missing or malformed. It must be a YAML map.',
          span,
        );
      }

      final YamlMap serverYaml = contents['server'] as YamlMap;
      fileConfig = DevConfig.fromYaml(serverYaml);
      globals.printStatus('\nLoaded configuration from $devConfigFilePath');
      globals.printTrace(fileConfig.toString());
    } on YamlException catch (e) {
      globals.printError('Error: Failed to parse $devConfigFilePath: ${e.message} ${e.span}');
      rethrow;
    } on Exception catch (e) {
      globals.printError('An unexpected error occurred while reading $devConfigFilePath: $e');
      globals.printStatus(
        'Reverting to default flutter_tools web server configuration due to unexpected error.',
      );
    }
  }

  final String finalHost =
      _getOverriddenValue<String>('host', fileConfig.host, hostname) ?? 'localhost';
  final int? finalPort = _getOverriddenValue<int>(
    'port',
    fileConfig.port,
    port != null ? int.tryParse(port) : null,
  );
  final String? finalCertPath = _getOverriddenValue<String>(
    'TLS cert path',
    fileConfig.https?.certPath,
    tlsCertPath,
  );
  final String? finalCertKeyPath = _getOverriddenValue<String>(
    'TLS cert key path',
    fileConfig.https?.certKeyPath,
    tlsCertKeyPath,
  );
  HttpsConfig? finalHttpsConfig;
  if (finalCertPath != null || finalCertKeyPath != null || fileConfig.https != null) {
    finalHttpsConfig = HttpsConfig(certPath: finalCertPath, certKeyPath: finalCertKeyPath);
  } else {
    finalHttpsConfig = null;
  }
  final Map<String, String> finalHeaders = <String, String>{};
  finalHeaders.addAll(fileConfig.headers);
  if (headers != null && headers.isNotEmpty) {
    for (final MapEntry<String, String> entry in headers.entries) {
      if (fileConfig.headers.containsKey(entry.key)) {
        globals.printStatus(
          'Overriding headers "${entry.key}" from $devConfigFilePath ("${fileConfig.headers[entry.key]}") with command-line argument("${entry.value}").',
        );
      } else {
        globals.printStatus('Adding header "${entry.key}" from command-line arguments.');
      }
    }
    finalHeaders.addAll(headers);
  }

  return DevConfig(
    host: finalHost,
    port: finalPort,
    https: finalHttpsConfig,
    headers: finalHeaders,
    proxy: fileConfig.proxy,
  );
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
