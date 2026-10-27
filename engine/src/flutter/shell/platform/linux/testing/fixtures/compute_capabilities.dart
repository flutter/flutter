// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

// Run with Impeller and Flutter GPU enabled. This probes the actual engine
// context, independently of GTK's GSK presentation renderer.
void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Compute capability probe'))),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final Map<String, Object?> report = <String, Object?>{'pid': pid};
    try {
      final gpu.GpuContext context = gpu.gpuContext;
      report['supports_compute'] = context.supportsCompute;
      report['max_workgroup_invocations'] = context.maxComputeWorkgroupInvocations;
      report['max_shared_memory_bytes'] = context.maxComputeSharedMemorySizeInBytes;
      report['max_workgroup_size'] = <int>[
        context.maxComputeWorkgroupSize.x,
        context.maxComputeWorkgroupSize.y,
        context.maxComputeWorkgroupSize.z,
      ];
      report['max_workgroup_count'] = <int>[
        context.maxComputeWorkgroupCount.x,
        context.maxComputeWorkgroupCount.y,
        context.maxComputeWorkgroupCount.z,
      ];
      bool rejected = false;
      try {
        context.createCommandBuffer().createComputePass();
      } on UnsupportedError catch (error) {
        rejected = true;
        report['compute_error'] = error.toString();
      }
      report['create_compute_pass_rejected'] = rejected;
      // Capability detection is not a successful compute dispatch. On a future
      // supported backend, use the upstream compute-to-render integration tests.
      report['dispatch_tested'] = false;
    } catch (error, stack) {
      report['error'] = error.toString();
      report['stack'] = stack.toString();
    }
    final String encoded = jsonEncode(report);
    print('COMPUTE_PROBE $encoded');
    final String? output = Platform.environment['COMPUTE_PROBE_OUTPUT'];
    if (output != null) {
      await File(output).writeAsString(encoded, flush: true);
    }
  });
}
