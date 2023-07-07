// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

/// Sample app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _tempDirectory = 'Unknown';
  String? _downloadsDirectory = 'Unknown';
  String? _libraryDirectory = 'Unknown';
  String? _appSupportDirectory = 'Unknown';
  String? _documentsDirectory = 'Unknown';
  String? _containerDirectory = 'Unknown';

  @override
  void initState() {
    super.initState();
    initDirectories();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initDirectories() async {
    String? tempDirectory;
    String? downloadsDirectory;
    String? appSupportDirectory;
    String? libraryDirectory;
    String? documentsDirectory;
    String? containerDirectory;
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final PathProviderFoundation providerFoundation = PathProviderFoundation();

    try {
      tempDirectory = await provider.getTemporaryPath();
    } catch (exception) {
      tempDirectory = 'Failed to get temp directory: $exception';
    }
    try {
      downloadsDirectory = await provider.getDownloadsPath();
    } catch (exception) {
      downloadsDirectory = 'Failed to get downloads directory: $exception';
    }

    try {
      documentsDirectory = await provider.getApplicationDocumentsPath();
    } catch (exception) {
      documentsDirectory = 'Failed to get documents directory: $exception';
    }

    try {
      libraryDirectory = await provider.getLibraryPath();
    } catch (exception) {
      libraryDirectory = 'Failed to get library directory: $exception';
    }

    try {
      appSupportDirectory = await provider.getApplicationSupportPath();
    } catch (exception) {
      appSupportDirectory = 'Failed to get app support directory: $exception';
    }

    try {
      containerDirectory = await providerFoundation.getContainerPath(
          appGroupIdentifier: 'group.flutter.appGroupTest');
    } catch (exception) {
      containerDirectory =
          'Failed to get app group container directory: $exception';
    }

    setState(() {
      _tempDirectory = tempDirectory;
      _downloadsDirectory = downloadsDirectory;
      _libraryDirectory = libraryDirectory;
      _appSupportDirectory = appSupportDirectory;
      _documentsDirectory = documentsDirectory;
      _containerDirectory = containerDirectory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Path Provider example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Temp Directory: $_tempDirectory\n'),
              Text('Documents Directory: $_documentsDirectory\n'),
              Text('Downloads Directory: $_downloadsDirectory\n'),
              Text('Library Directory: $_libraryDirectory\n'),
              Text('Application Support Directory: $_appSupportDirectory\n'),
              Text('App Group Container Directory: $_containerDirectory\n'),
            ],
          ),
        ),
      ),
    );
  }
}
