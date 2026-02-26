// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/170805.
  DropdownButtonFormField(value: 'one');

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButton(onChanged: null);

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButtonFormField(onChanged: null);

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButton(onChanged: (String? v) {});

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButtonFormField(onChanged: (String? v) {});

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButton(onChanged: null, enabled: true);

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButtonFormField(onChanged: null, enabled: true);

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButton(onChanged: null, enabled: false);

  // Changes made in https://github.com/flutter/flutter/pull/182419.
  DropdownButtonFormField(onChanged: null, enabled: false);
}
