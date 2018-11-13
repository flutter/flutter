// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'customized/home.dart';

class CustomizedDemo extends StatelessWidget {
  const CustomizedDemo({Key key}) : super(key: key);

  static const String routeName = '/customized';

  @override
  Widget build(BuildContext context) => CustomizedDesign();
}
