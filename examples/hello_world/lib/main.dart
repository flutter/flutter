// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp( MaterialApp(
  theme: ThemeData(
    inputDecorationTheme: InputDecorationTheme(
      focusColor: Colors.brown
    ),
    iconTheme: IconThemeData(
      color: Colors.red,
    )
  ),
  home: Scaffold(
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
            icon: Icon(Icons.ac_unit),
          ),
        )
      ],
    )
  )
));
