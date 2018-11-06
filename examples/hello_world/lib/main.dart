// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
// void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));
void main() {
  runApp(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(
            left: 10.0,
            top: 20.0,
            right: 30.0,
            bottom: 40.0,
          ),
        ),
        child: Material(
          child: Center(
            child: UserAccountsDrawerHeader(
              onDetailsPressed: () {},
              currentAccountPicture: const ExcludeSemantics(
                child: CircleAvatar(
                  child: Text('A'),
                ),
              ),
              otherAccountsPictures: const <Widget>[
                CircleAvatar(
                  child: Text('B'),
                ),
                CircleAvatar(
                  child: Text('C'),
                ),
                CircleAvatar(
                  child: Text('D'),
                ),
                CircleAvatar(
                  child: Text('E'),
                )
              ],
              accountName: const Text('name'),
              accountEmail: const Text('email'),
            ),
          ),
        ),
      ),
    ),
  );
}