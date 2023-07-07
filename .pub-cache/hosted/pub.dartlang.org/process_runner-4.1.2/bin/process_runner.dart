// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This utility sends a bunch of jobs to a ProcessPool for processing.
//
// It can speed up processing of a bunch of single-threaded CPU-intensive
// commands by a multiple of the number of processor cores you have (modulo being
// disk/network bound, of course).
//
// You can install this command with "dart pub global activate process_runner",
// and you can run it with "dart pub global run process_runner".

import '../example/main.dart' as runner_main;

Future<void> main(List<String> args) async {
  return runner_main.main(args);
}
