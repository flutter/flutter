// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [FocusNode.unfocus].

void main() => runApp(const UnfocusExampleApp());

class UnfocusExampleApp extends StatelessWidget {
  const UnfocusExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: UnfocusExample());
  }
}

class UnfocusExample extends StatefulWidget {
  const UnfocusExample({super.key});

  @override
  State<UnfocusExample> createState() => _UnfocusExampleState();
}

class _UnfocusExampleState extends State<UnfocusExample> {
  UnfocusDisposition disposition = UnfocusDisposition.scope;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Wrap(
              children: List<Widget>.generate(4, (int index) {
                return const SizedBox(
                  width: 200,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                );
              }),
            ),
            RadioGroup<UnfocusDisposition>(
              groupValue: disposition,
              onChanged: (UnfocusDisposition? value) {
                setState(() {
                  if (value != null) {
                    disposition = value;
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  for (final UnfocusDisposition unfocusDisposition
                      in UnfocusDisposition.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Radio<UnfocusDisposition>(value: unfocusDisposition),
                        Text(unfocusDisposition.name),
                      ],
                    ),
                  OutlinedButton(
                    child: const Text('UNFOCUS'),
                    onPressed: () {
                      setState(() {
                        primaryFocus!.unfocus(disposition: disposition);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
