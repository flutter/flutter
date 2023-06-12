// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Example script to illustrate how to use the mdns package to discover the port
// of a Dart observatory over mDNS.

import 'package:multicast_dns/multicast_dns.dart';

Future<void> main() async {
  // Parse the command line arguments.

  const String name = '_dartobservatory._tcp.local';
  final MDnsClient client = MDnsClient();
  // Start the client with default options.
  await client.start();

  // Get the PTR record for the service.
  await for (final PtrResourceRecord ptr in client
      .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
    // Use the domainName from the PTR record to get the SRV record,
    // which will have the port and local hostname.
    // Note that duplicate messages may come through, especially if any
    // other mDNS queries are running elsewhere on the machine.
    await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName))) {
      // Domain name will be something like "io.flutter.example@some-iphone.local._dartobservatory._tcp.local"
      final String bundleId =
          ptr.domainName; //.substring(0, ptr.domainName.indexOf('@'));
      print('Dart observatory instance found at '
          '${srv.target}:${srv.port} for "$bundleId".');
    }
  }
  client.stop();

  print('Done.');
}
