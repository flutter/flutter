// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test that the resource record cache works correctly.  In particular, make
// sure that it removes all entries for a name before insertingrecords
// of that name.

import 'dart:io';

import 'package:multicast_dns/src/native_protocol_client.dart'
    show ResourceRecordCache;
import 'package:multicast_dns/src/resource_record.dart';
import 'package:test/test.dart';

void main() {
  testOverwrite();
  testTimeout();
}

void testOverwrite() {
  test('Cache can overwrite entries', () {
    final InternetAddress ip1 = InternetAddress('192.168.1.1');
    final InternetAddress ip2 = InternetAddress('192.168.1.2');
    final int valid = DateTime.now().millisecondsSinceEpoch + 86400 * 1000;

    final ResourceRecordCache cache = ResourceRecordCache();

    // Add two different records.
    cache.updateRecords(<ResourceRecord>[
      IPAddressResourceRecord('hest', valid, address: ip1),
      IPAddressResourceRecord('fisk', valid, address: ip2)
    ]);
    expect(cache.entryCount, 2);

    // Update these records.
    cache.updateRecords(<ResourceRecord>[
      IPAddressResourceRecord('hest', valid, address: ip1),
      IPAddressResourceRecord('fisk', valid, address: ip2)
    ]);
    expect(cache.entryCount, 2);

    // Add two records with the same name (should remove the old one
    // with that name only.)
    cache.updateRecords(<ResourceRecord>[
      IPAddressResourceRecord('hest', valid, address: ip1),
      IPAddressResourceRecord('hest', valid, address: ip2)
    ]);
    expect(cache.entryCount, 3);

    // Overwrite the two cached entries with one with the same name.
    cache.updateRecords(<ResourceRecord>[
      IPAddressResourceRecord('hest', valid, address: ip1),
    ]);
    expect(cache.entryCount, 2);
  });
}

void testTimeout() {
  test('Cache can evict records after timeout', () {
    final InternetAddress ip1 = InternetAddress('192.168.1.1');
    final int valid = DateTime.now().millisecondsSinceEpoch + 86400 * 1000;
    final int notValid = DateTime.now().millisecondsSinceEpoch - 1;

    final ResourceRecordCache cache = ResourceRecordCache();

    cache.updateRecords(
        <ResourceRecord>[IPAddressResourceRecord('hest', valid, address: ip1)]);
    expect(cache.entryCount, 1);

    cache.updateRecords(<ResourceRecord>[
      IPAddressResourceRecord('fisk', notValid, address: ip1)
    ]);

    List<ResourceRecord> results = <ResourceRecord>[];
    cache.lookup('hest', ResourceRecordType.addressIPv4, results);
    expect(results.isEmpty, isFalse);

    results = <ResourceRecord>[];
    cache.lookup('fisk', ResourceRecordType.addressIPv4, results);
    expect(results.isEmpty, isTrue);
    expect(cache.entryCount, 1);
  });
}
