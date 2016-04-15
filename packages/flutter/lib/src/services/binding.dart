// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'shell.dart';

abstract class Services extends BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    new MojoShell();
  }
}
