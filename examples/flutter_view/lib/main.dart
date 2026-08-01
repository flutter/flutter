// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _grey = Color(0xFF9E9E9E);
const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);
const Color _blue = Color(0xFF2196F3);

void main() {
  runApp(const FlutterView());
}

class FlutterView extends StatelessWidget {
  const FlutterView({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Flutter View',
      color: _grey,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return builder(context);
              },
        );
      },
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _channel = 'increment';
  static const String _pong = 'pong';
  static const String _emptyMessage = '';
  static const BasicMessageChannel<String?> platform = BasicMessageChannel<String?>(
    _channel,
    StringCodec(),
  );

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    platform.setMessageHandler(_handlePlatformIncrement);
  }

  Future<String> _handlePlatformIncrement(String? message) async {
    setState(() {
      _counter++;
    });
    return _emptyMessage;
  }

  void _sendFlutterIncrement() {
    platform.send(_pong); // ignore: unawaited_futures
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _white,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Text(
                    'Platform button tapped $_counter time${_counter == 1 ? '' : 's'}.',
                    style: const TextStyle(
                      color: _black,
                      fontSize: 17.0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 15.0, left: 5.0),
                child: Row(
                  children: <Widget>[
                    Image.asset('assets/flutter-mark-square-64.png', scale: 1.5),
                    const Text(
                      'Flutter',
                      style: TextStyle(
                        color: _black,
                        fontSize: 30.0,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: _Button(
              onPressed: _sendFlutterIncrement,
              icon: const Text(
                '+',
                style: TextStyle(
                  color: _white,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56.0,
        height: 56.0,
        decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
        child: Center(child: icon),
      ),
    );
  }
}
