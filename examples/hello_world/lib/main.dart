// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  final TextEditingController controller = TextEditingController();
  runApp(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, _) =>
                RepaintBoundary(
                  child: ListView(
                    children: <Widget>[
                      TextFormField(
                        minLines: 1,
                        maxLines: 4,
                        controller: controller,
                        // onChanged: Material.of(context).markNeedsPaint,
                      ),
                      Ink(
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: Colors.red
                              )
                          ),
                        ),
                        child: const SizedBox(height: 1,),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      )
    );
}
