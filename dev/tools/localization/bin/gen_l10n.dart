// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Runs `flutter generate_localizations with arguments passed in.
///
/// This script exists as a legacy entrypoint, since existing users of
/// gen_l10n tool used to call
/// `dart ${FLUTTER}/dev/tools/localizations/bin/gen_l10n.dart <options>` to
/// generate their Flutter project's localizations resources.
///
/// Now, the appropriate way to use this tool is to either define an `l10n.yaml`
/// file in the Flutter project repository, or call
/// `flutter generate_localizations <options>`, since the code has moved
/// into `flutter_tools`.
Future<void> main(List<String> rawArgs) async {
  final ProcessResult result = await Process.run(
    'flutter',
    <String>[
      'generate_localizations',
      ...rawArgs,
    ],
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);
}
