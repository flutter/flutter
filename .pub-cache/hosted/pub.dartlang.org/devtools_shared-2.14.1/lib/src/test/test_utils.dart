// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

Future<void> waitFor(
  Future<bool> condition(), {
  Duration timeout = const Duration(seconds: 10),
  String timeoutMessage = 'condition not satisfied',
  Duration delay = _shortDelay,
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (!end.isBefore(DateTime.now())) {
    if (await condition()) {
      return;
    }
    await Future.delayed(delay);
  }
  throw timeoutMessage;
}

Future delay({Duration duration = const Duration(milliseconds: 500)}) {
  return Future.delayed(duration);
}

Future shortDelay() {
  return delay(duration: _shortDelay);
}

const _shortDelay = Duration(milliseconds: 100);
