// Copyright 2019-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class VerticalFractionBar extends StatelessWidget {
  VerticalFractionBar({this.color, this.fraction});

  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.0,
      width: 4.0,
      child: Column(
        children: [
          SizedBox(
            height: (1 - fraction) * 32.0,
            child: Container(
              color: Colors.black,
            ),
          ),
          SizedBox(
            height: fraction * 32.0,
            child: Container(color: color),
          ),
        ],
      ),
    );
  }
}
