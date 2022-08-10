// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {
  print('Hello windows engine test main!');
}

@pragma('vm:entry-point')
void customEntrypoint() {
  print('Hello windows engine test customEntrypoint!');
}
