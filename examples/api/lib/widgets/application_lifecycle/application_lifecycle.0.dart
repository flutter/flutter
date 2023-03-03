// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [ApplicationLifecycleListener].

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Body()),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  late final AppLifecycleListener listener;
  bool _shouldExit = false;

  @override
  void initState() {
    super.initState();
    listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onExitRequested: _handleExitRequest,
    );
  }

  Future<void> _quit() async {
    await ServicesBinding.instance.exitApplication(AppExitType.cancelable);
  }

  Future<AppExitResponse> _handleExitRequest() async {
    final AppExitResponse response = _shouldExit ? AppExitResponse.exit : AppExitResponse.cancel;
    debugPrint('Sample App responding $response to exit request');
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
        width: 160,
        child: IntrinsicHeight(
          child: Column(
            children: <Widget>[
              LabeledRadio(
                label: const Text('Do Not Allow Exit'),
                groupValue: _shouldExit,
                value: false,
                onChanged: _radioChanged,
              ),
              LabeledRadio(
                label: const Text('Allow Exit'),
                groupValue: _shouldExit,
                value: true,
                onChanged: _radioChanged,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _quit,
                child: const Text('Quit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LabeledRadio extends StatelessWidget {
  const LabeledRadio({
    super.key,
    required this.label,
    this.padding = EdgeInsets.zero,
    required this.groupValue,
    required this.value,
    required this.onChanged,
  });

  final Widget label;
  final EdgeInsets padding;
  final bool groupValue;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (value != groupValue) {
          onChanged(value);
        }
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Radio<bool>(
              groupValue: groupValue,
              value: value,
              onChanged: (bool? newValue) {
                onChanged(newValue!);
              },
            ),
            label,
          ],
        ),
      ),
    );
  }
}
