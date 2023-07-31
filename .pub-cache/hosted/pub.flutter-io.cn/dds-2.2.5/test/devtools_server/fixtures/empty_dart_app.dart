// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

void main() async {
  print('starting empty app');

  var myVar = 0;
  while (true) {
    myVar++;
    print(myVar);
    await (Future.delayed(const Duration(seconds: 2)));
  }
}
