// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Expansible].

void main() => runApp(const ExpansibleExampleApp());

class ExpansibleExampleApp extends StatelessWidget {
  const ExpansibleExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Expansible FAQ Sample')),
        body: const ExpansibleExample(),
      ),
    );
  }
}

class ExpansibleExample extends StatefulWidget {
  const ExpansibleExample({super.key});

  @override
  State<ExpansibleExample> createState() => _ExpansibleExampleState();
}

class _ExpansibleExampleState extends State<ExpansibleExample> {
  late ExpansibleController _controller1;
  late ExpansibleController _controller2;
  late ExpansibleController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = ExpansibleController();
    _controller2 = ExpansibleController();
    _controller3 = ExpansibleController();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          controller: _controller1,
          question: 'What is Flutter?',
          answer:
              'Flutter is an open-source UI software development kit created by Google. '
              'It is used to develop cross-platform applications for Android, iOS, Linux, '
              'macOS, Windows, and the web from a single codebase.',
        ),
        const SizedBox(height: 8),
        _buildFAQItem(
          controller: _controller2,
          question: 'How does Expansible work?',
          answer:
              'The Expansible widget provides a way to show and hide content with an animation. '
              'When tapped, it expands to reveal the child widget and collapses when tapped again.',
        ),
        const SizedBox(height: 8),
        _buildFAQItem(
          controller: _controller3,
          question: 'Can I customize the appearance?',
          answer:
              'Yes! The Expansible widget supports various customization options including '
              'custom headers, styling, animation duration, and more.',
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required ExpansibleController controller,
    required String question,
    required String answer,
  }) {
    return Expansible(
      controller: controller,
      headerBuilder: (BuildContext context, Animation<double> animation) {
        return GestureDetector(
          onTap: () {
            if (controller.isExpanded) {
              controller.collapse();
            } else {
              controller.expand();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 0.5).animate(animation),
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        );
      },
      bodyBuilder: (BuildContext context, Animation<double> animation) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: Text(answer, style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}
