// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path Provider',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Path Provider'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PathProviderPlatform provider = PathProviderPlatform.instance;
  Future<String?>? _tempDirectory;
  Future<String?>? _appSupportDirectory;
  Future<String?>? _appLibraryDirectory;
  Future<String?>? _appDocumentsDirectory;

  void _requestTempDirectory() {
    setState(() {
      _tempDirectory = provider.getTemporaryPath();
    });
  }

  Widget _buildDirectory(
      BuildContext context, AsyncSnapshot<String?> snapshot) {
    Text text = const Text('');
    if (snapshot.connectionState == ConnectionState.done) {
      if (snapshot.hasError) {
        text = Text('Error: ${snapshot.error}');
      } else if (snapshot.hasData) {
        text = Text('path: ${snapshot.data}');
      } else {
        text = const Text('path unavailable');
      }
    }
    return Padding(padding: const EdgeInsets.all(16.0), child: text);
  }

  void _requestAppDocumentsDirectory() {
    setState(() {
      _appDocumentsDirectory = provider.getApplicationDocumentsPath();
    });
  }

  void _requestAppSupportDirectory() {
    setState(() {
      _appSupportDirectory = provider.getApplicationSupportPath();
    });
  }

  void _requestAppLibraryDirectory() {
    setState(() {
      _appLibraryDirectory = provider.getLibraryPath();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _requestTempDirectory,
                child: const Text('Get Temporary Directory'),
              ),
            ),
            FutureBuilder<String?>(
                future: _tempDirectory, builder: _buildDirectory),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _requestAppDocumentsDirectory,
                child: const Text('Get Application Documents Directory'),
              ),
            ),
            FutureBuilder<String?>(
                future: _appDocumentsDirectory, builder: _buildDirectory),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _requestAppSupportDirectory,
                child: const Text('Get Application Support Directory'),
              ),
            ),
            FutureBuilder<String?>(
                future: _appSupportDirectory, builder: _buildDirectory),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _requestAppLibraryDirectory,
                child: const Text('Get Application Library Directory'),
              ),
            ),
            FutureBuilder<String?>(
                future: _appLibraryDirectory, builder: _buildDirectory),
          ],
        ),
      ),
    );
  }
}
