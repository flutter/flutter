// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/localizations/gen_l10n.dart';

import '../../src/common.dart';

void main() {
  late FileSystem fs;
  late BufferLogger logger;

  setUp(() {
    fs = MemoryFileSystem.test();
    logger = BufferLogger.test();
  });

  testWithoutContext('AppResourceBundle throws if file contains non-string value', () {
    const String inputPathString = 'lib/l10n';
    const String templateArbFileName = 'app_en.arb';
    const String outputFileString = 'app_localizations.dart';
    const String classNameString = 'AppLocalizations';

    fs.file(fs.path.join(inputPathString, templateArbFileName))
      ..createSync(recursive: true)
      ..writeAsStringSync('{ "helloWorld": "Hello World!" }');
    fs.file(fs.path.join(inputPathString, 'app_es.arb'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{ "helloWorld": {} }');

    final LocalizationsGenerator generator = LocalizationsGenerator(
      fileSystem: fs,
      inputPathString: inputPathString,
      templateArbFileName: templateArbFileName,
      outputFileString: outputFileString,
      classNameString: classNameString,
      logger: logger,
    );
    expect(
        () => generator.loadResources(),
        throwsToolExit(message: 'Localized message for key "helloWorld" in '
          '"lib/l10n/app_es.arb" is not a string.'));
  });
}
