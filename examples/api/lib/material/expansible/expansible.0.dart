// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Expansible].

void main() => runApp(const ExpansibleExampleApp());

/// An application that shows an example of how to use [Expansible].
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

/// A StatefulWidget that displays a list of expandable FAQ items.
class ExpansibleExample extends StatefulWidget {
  const ExpansibleExample({super.key});

  @override
  State<ExpansibleExample> createState() => _ExpansibleExampleState();
}

class _ExpansibleExampleState extends State<ExpansibleExample> {
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);

  late final List<_FaqItem> _items;

  @override
  void initState() {
    super.initState();
    _items = <_FaqItem>[
      _FaqItem(
        question: 'What is Flutter?',
        answer:
            'Flutter is an open-source UI software development kit created by Google. '
            'It is used to develop cross-platform applications for Android, iOS, Linux, '
            'macOS, Windows, and the web from a single codebase.',
        controller: ExpansibleController(),
      ),
      _FaqItem(
        question: 'How does Expansible work?',
        answer:
            'The Expansible widget provides a way to show and hide content with an animation. '
            'When tapped, it expands to reveal the child widget and collapses when tapped again.',
        controller: ExpansibleController(),
      ),
      _FaqItem(
        question: 'Can I customize the appearance?',
        answer:
            'Yes! The Expansible widget supports various customization options including '
            'custom headers, styling, animation duration, and more.',
        controller: ExpansibleController(),
      ),
    ];
  }

  @override
  void dispose() {
    for (final _FaqItem item in _items) {
      item.controller.dispose();
    }
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
        for (int index = 0; index < _items.length; index++) ...<Widget>[
          _buildFAQItem(item: _items[index]),
          if (index != _items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildFAQItem({required _FaqItem item}) {
    final ExpansibleController controller = item.controller;
    return Expansible(
      controller: controller,
      headerBuilder: (BuildContext context, Animation<double> animation) {
        return GestureDetector(
          onTap: controller.isExpanded ? controller.collapse : controller.expand,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: controller.isExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    )
                  : BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.question,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                RotationTransition(
                  turns: _halfTween.animate(animation),
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
          child: Text(item.answer, style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}

class _FaqItem {
  _FaqItem({required this.question, required this.answer, required this.controller});

  final String question;
  final String answer;
  final ExpansibleController controller;
}
