// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json, utf8;
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

// import 'package:flutter/painting.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart' as vm_io;
// import 'package:test_api/test_api.dart';

import '../flutter_test_alternative.dart';
// import '../rendering/rendering_tester.dart';

void main() {
  // setUpAll(() {
  //   TestRenderingFlutterBinding();
  // });

  test('Image cache tracing',  () async {
    await _getTimelineData();
    await Future<void>.delayed(const Duration(seconds: 20));
  });
}

Future<String> _getTimelineData() async {
  final String isolateId = developer.Service.getIsolateID(Isolate.current);
  final developer.ServiceProtocolInfo info = await developer.Service.controlWebServer(enable: true);
  // final developer.ServiceProtocolInfo info = await developer.Service.controlWebServer(enable: true);
  print(info.serverUri);
  // final Uri cpuProfileTimelineUri = info.serverUri.resolve(
  //   '_getCpuProfileTimeline?tags=None&isolateId=$isolateId',
  // );
  // print(cpuProfileTimelineUri);
  // final int port = developer.ServiceProtocolInfo.
  // final VmService vmService = await vmServiceConnectUri('ws://localhost:$port/ws');
  // final VM vm = await VmService.getVM();
  // isolate.
  // final String isolateId = developer.Service.getIsolateID(Isolate.current);
  // final developer.ServiceProtocolInfo info = await developer.Service.getInfo();
  // final Uri cpuProfileTimelineUri = info.serverUri.resolve(
  //   '_getCpuProfileTimeline?tags=None&isolateId=$isolateId',
  // );
  // final Uri vmServiceTimelineUri = info.serverUri.resolve('getVMTimeline');
  // final Map<String, dynamic> cpuTimelineJson = await _getJson(cpuProfileTimelineUri);
  // final Map<String, dynamic> vmServiceTimelineJson = await _getJson(vmServiceTimelineUri);
  // final Map<String, dynamic> cpuResult = cpuTimelineJson['result'] as Map<String, dynamic>;
  // final Map<String, dynamic> vmServiceResult = vmServiceTimelineJson['result'] as Map<String, dynamic>;

  // return json.encode(<String, dynamic>{
  //   'stackFrames': cpuResult['stackFrames'],
  //   'traceEvents': <dynamic>[
  //     ...cpuResult['traceEvents'] as List<dynamic>,
  //     ...vmServiceResult['traceEvents'] as List<dynamic>,
  //   ],
  // });
}

Future<Map<String, dynamic>> _getJson(Uri uri) async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(uri);
  final HttpClientResponse response = await request.close();
  if (response.statusCode > 299) {
    return null;
  }
  final String data = await utf8.decodeStream(response);
  return json.decode(data) as Map<String, dynamic>;
}
