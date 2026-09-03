// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:yaml/yaml.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('web dev server defaults to a loopback host', () {
    expect(webDevDefaultHost, 'localhost');
    expect(const WebDevServerConfig().host, webDevDefaultHost);
  });

  testWithoutContext('web_dev_config.yaml may opt into all interfaces', () {
    final yaml = loadYaml('server:\n  host: any') as YamlMap;
    final config = WebDevServerConfig.fromYaml(
      yaml['server']! as YamlMap,
      BufferLogger.test(),
    );
    expect(config.host, 'any');
  });

  testWithoutContext('web_dev_config.yaml falls back to the loopback default', () {
    final yaml = loadYaml('server:\n  port: 8080') as YamlMap;
    final config = WebDevServerConfig.fromYaml(
      yaml['server']! as YamlMap,
      BufferLogger.test(),
    );
    expect(config.host, webDevDefaultHost);
  });

  testWithoutContext('copyWith host override takes precedence', () {
    const config = WebDevServerConfig();
    expect(config.copyWith(host: '0.0.0.0').host, '0.0.0.0');
    expect(config.copyWith().host, 'localhost');
  });
}
