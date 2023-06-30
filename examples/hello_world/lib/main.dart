// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() =>
  runApp(
    MaterialApp(
      title: 'Hello, world!',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child:
            Text('Hello, world!',
              key: Key('title'),
              textDirection: TextDirection.ltr,
            ),
          ),
      ),
    ),
    );
