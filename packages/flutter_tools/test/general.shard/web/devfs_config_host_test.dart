// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:test/test.dart';

void main() {
  group('default host', () {
    // The dev server serves source maps, which carry the project's Dart
    // source, and the DWDS debug handler shares its port. Defaulting the bind
    // address to `any` puts both on every IPv4 interface, so this asserts the
    // default is loopback rather than that it is merely non-empty.
    test('is loopback, not every interface', () {
      expect(const WebDevServerConfig().host, webDevHostDefault);
      expect(const WebDevServerConfig().host, isNot(webDevAnyHostDefault));
    });

    // An unset `--web-hostname` reaches copyWith as a null host, taking the
    // `host ?? this.host` branch. If that fell through to `any`, the CLI
    // default would be every interface while the flag help still describes
    // `any` as something you opt into.
    test('is preserved when copyWith is given no host', () {
      final WebDevServerConfig config = const WebDevServerConfig().copyWith(port: 8080);

      expect(config.host, webDevHostDefault);
      expect(config.port, 8080);
    });

    test('still accepts an explicit any opt-in', () {
      expect(
        const WebDevServerConfig().copyWith(host: webDevAnyHostDefault).host,
        webDevAnyHostDefault,
      );
    });

    test('still accepts an explicit hostname', () {
      expect(const WebDevServerConfig().copyWith(host: '192.168.1.5').host, '192.168.1.5');
    });
  });
}
