// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample for [AppLifecycleListener].

void main() {
  runApp(const AppLifecycleListenerExample());
}

class AppLifecycleListenerExample extends StatelessWidget {
  const AppLifecycleListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: ApplicationExitControl()));
  }
}

class ApplicationExitControl extends StatefulWidget {
  const ApplicationExitControl({super.key});

  @override
  State<ApplicationExitControl> createState() => _ApplicationExitControlState();
}

class _ApplicationExitControlState extends State<ApplicationExitControl> {
  late final AppLifecycleListener _listener;
  bool _shouldExit = false;
  String _lastExitResponse = 'No exit requested yet';

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onExitRequested: _handleExitRequest);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<void> _quit() async {
    final AppExitType exitType = _shouldExit
        ? AppExitType.required
        : AppExitType.cancelable;
    await ServicesBinding.instance.exitApplication(exitType);
  }

  Future<AppExitResponse> _handleExitRequest() async {
    final AppExitResponse response = _shouldExit
        ? AppExitResponse.exit
        : AppExitResponse.cancel;
    setState(() {
      _lastExitResponse = 'App responded ${response.name} to exit request';
    });
    return response;
  }

  void _radioChanged(bool? value) {
    value ??= true;
    if (_shouldExit == value) {
      return;
    }
    setState(() {
      _shouldExit = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: RadioGroup<bool>(
          groupValue: _shouldExit,
          onChanged: (bool? value) => _radioChanged(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const RadioListTile<bool>(
                title: Text('Do Not Allow Exit'),
                value: false,
              ),
              const RadioListTile<bool>(title: Text('Allow Exit'), value: true),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _quit, child: const Text('Quit')),
              const SizedBox(height: 30),
              Text('Exit Request: $_lastExitResponse'),
            ],
          ),
        ),
      ),
    );
  }
}
