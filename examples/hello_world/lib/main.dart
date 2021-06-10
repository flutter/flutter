// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(
      MaterialApp(
        home: Material(
          color: Colors.white,
          child: DraggableScrollableSheet(
            snapPoints: [],
            builder: (BuildContext context, ScrollController controller) =>
                Material(
              color: Colors.blueAccent,
              child: ListView.builder(
                controller: controller,
                itemBuilder: (BuildContext context, int i) => Text(
                  i.toString(),
                  style: const TextStyle(fontSize: 32),
                ),
                itemCount: 50,
              ),
            ),
          ),
        ),
      ),
    );
