// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print
import 'dart:async';

import 'package:data_asset_package/data_asset_package.dart';
import 'package:flutter/material.dart';

import 'helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AssetData? _assetData;
  String _dependencyAsset = 'Loading...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final data = await dumpAssets();
      final depAsset = await readAsset();
      // Print for integration test discovery
      if (data != null) {
        print('DUMPED ASSETS for ${data.version}');
      }
      print('DEPENDENCY_ASSET: $depAsset');

      if (mounted) {
        setState(() {
          if (data != null) {
            _assetData = data;
          }
          _dependencyAsset = depAsset;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Asset Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Data Asset Demo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Version: ${_assetData?.version ?? "Unknown"}',
                style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            const Text('Local Assets:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (_assetData != null) ...[
              if (_assetData!.found.isEmpty && _assetData!.notFound.isEmpty)
                const Text('No assets requested.'),
              for (final MapEntry(:key, :value) in _assetData!.found.entries)
                Text('FOUND "$key": "$value"'),
              for (final id in _assetData!.notFound)
                Text('NOT FOUND "$id"',
                    style: const TextStyle(color: Colors.red)),
            ] else
              const Text('Loading assets...'),
            const Divider(),
            const Text('Dependency Asset:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_dependencyAsset),
          ],
        ),
      ),
    );
  }
}
