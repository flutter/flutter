// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_shared/src/service_utils.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeVmServiceUri', () {
    test('normalizes simple URIs', () {
      expect(
        normalizeVmServiceUri('http://127.0.0.1:60667/72K34Xmq0X0=').toString(),
        equals('http://127.0.0.1:60667/72K34Xmq0X0='),
      );
      expect(
        normalizeVmServiceUri('http://127.0.0.1:60667/72K34Xmq0X0=/   ')
            .toString(),
        equals('http://127.0.0.1:60667/72K34Xmq0X0=/'),
      );
      expect(
        normalizeVmServiceUri('http://127.0.0.1:60667').toString(),
        equals('http://127.0.0.1:60667'),
      );
      expect(
        normalizeVmServiceUri('http://127.0.0.1:60667/').toString(),
        equals('http://127.0.0.1:60667/'),
      );
    });

    test('properly strips leading whitespace and trailing URI fragments', () {
      expect(
        normalizeVmServiceUri('  http://127.0.0.1:60667/72K34Xmq0X0=/#/vm')
            .toString(),
        equals('http://127.0.0.1:60667/72K34Xmq0X0=/'),
      );
      expect(
        normalizeVmServiceUri('  http://127.0.0.1:60667/72K34Xmq0X0=/#/vm  ')
            .toString(),
        equals('http://127.0.0.1:60667/72K34Xmq0X0=/'),
      );
    });

    test('properly handles encoded urls', () {
      expect(
        normalizeVmServiceUri('http%3A%2F%2F127.0.0.1%3A58824%2FCnvgRrQJG7w%3D')
            .toString(),
        equals('http://127.0.0.1:58824/CnvgRrQJG7w='),
      );

      expect(
        normalizeVmServiceUri(
          'http%3A%2F%2F127.0.0.1%3A58824%2FCnvgRrQJG7w%3D  ',
        ).toString(),
        equals('http://127.0.0.1:58824/CnvgRrQJG7w='),
      );

      expect(
        normalizeVmServiceUri(
          '  http%3A%2F%2F127.0.0.1%3A58824%2FCnvgRrQJG7w%3D   ',
        ).toString(),
        equals('http://127.0.0.1:58824/CnvgRrQJG7w='),
      );
    });

    test('handles prefixed devtools server uris', () {
      expect(
        normalizeVmServiceUri(
          'http://127.0.0.1:9101?uri=http%3A%2F%2F127.0.0.1%3A56142%2FHOwgrxalK00%3D%2F',
        ).toString(),
        equals('http://127.0.0.1:56142/HOwgrxalK00=/'),
      );
    });

    test('Returns null when given a non-absolute url', () {
      expect(normalizeVmServiceUri('my/page'), null);
    });
  });
}
