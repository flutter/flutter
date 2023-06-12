// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Example script to illustrate how to use the mdns package to discover services
// on the local network.

import 'package:multicast_dns/multicast_dns.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('''
Please provide the name of a service as argument.

For example:
  dart mdns_sd.dart [--verbose] _workstation._tcp.local''');
    return;
  }

  final bool verbose = args.contains('--verbose') || args.contains('-v');
  final String name = args.last;
  final MDnsClient client = MDnsClient();
  await client.start();

  await for (final PtrResourceRecord ptr in client
      .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
    if (verbose) {
      print(ptr);
    }
    await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName))) {
      if (verbose) {
        print(srv);
      }
      if (verbose) {
        await client
            .lookup<TxtResourceRecord>(ResourceRecordQuery.text(ptr.domainName))
            .forEach(print);
      }
      await for (final IPAddressResourceRecord ip
          in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
        if (verbose) {
          print(ip);
        }
        print('Service instance found at '
            '${srv.target}:${srv.port} with ${ip.address}.');
      }
      await for (final IPAddressResourceRecord ip
          in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv6(srv.target))) {
        if (verbose) {
          print(ip);
        }
        print('Service instance found at '
            '${srv.target}:${srv.port} with ${ip.address}.');
      }
    }
  }
  client.stop();
}
