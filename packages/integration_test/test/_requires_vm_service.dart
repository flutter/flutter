import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';

Future<bool> hasVmServiceEnabled() async {
  final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
  final bool result = info.serverUri != null;
  if (!result) {
    print('Run test suite with --enable-vmservice to enable this test.');
  }
  return result;
}
