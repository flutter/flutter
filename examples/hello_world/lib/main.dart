//// Copyright 2015 The Chromium Authors. All rights reserved.
//// Use of this source code is governed by a BSD-style license that can be
//// found in the LICENSE file.
//
//import 'package:flutter/widgets.dart';
//
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));


// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
//
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));

void main() {
  runApp(
    const MaterialApp(
      home: Material(
        child: TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'nick name',
            contentPadding: EdgeInsets.all(2.0),
            border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFEEEEEE),style: BorderStyle.solid,width: 10.0),
                borderRadius: BorderRadius.all(Radius.circular(2.0))
            ),
            hintStyle: TextStyle(
                fontSize: 14.0,
                color: Colors.black38
            ),
          ),
        ),
      ),
    ),
  );
}