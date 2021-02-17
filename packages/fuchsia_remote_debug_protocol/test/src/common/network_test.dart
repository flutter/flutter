// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fuchsia_remote_debug_protocol/src/common/network.dart';

import '../../common.dart';

void main() {
  final List<String> ipv4Addresses = <String>['127.0.0.1', '8.8.8.8'];
  final List<String> ipv6Addresses = <String>['::1',
    'fe80::8eae:4cff:fef4:9247', 'fe80::8eae:4cff:fef4:9247%e0'];

  group('test validation', () {
    test('isIpV4Address', () {
      expect(ipv4Addresses.map(isIpV4Address), everyElement(isTrue));
      expect(ipv6Addresses.map(isIpV4Address), everyElement(isFalse));
    });

    test('isIpV6Address', () {
      expect(ipv4Addresses.map(isIpV6Address), everyElement(isFalse));
      expect(ipv6Addresses.map(isIpV6Address), everyElement(isTrue));
    });
  });
}
