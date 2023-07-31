// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.main;

import 'dart:convert' show LineSplitter, utf8;

import 'dart:io' show File;

import '../scanner/token.dart' show Token;

import '../scanner/io.dart' show readBytesFromFileSync;

import '../scanner/scanner.dart' show scan;

import 'listener.dart' show Listener;

import 'top_level_parser.dart' show TopLevelParser;

import 'identifier_context.dart' show IdentifierContext;

class DebugListener extends Listener {
  void handleIdentifier(Token token, IdentifierContext context) {
    logEvent("Identifier: ${token.lexeme}");
  }

  void logEvent(String name) {
    print(name);
  }
}

mainEntryPoint(List<String> arguments) async {
  for (String argument in arguments) {
    if (argument.startsWith("@")) {
      Uri uri = Uri.base.resolve(argument.substring(/* startIndex = */ 1));
      await for (String file in new File.fromUri(uri)
          .openRead()
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        outLine(uri.resolve(file));
      }
    } else {
      outLine(Uri.base.resolve(argument));
    }
  }
}

void outLine(Uri uri) {
  new TopLevelParser(new DebugListener())
      .parseUnit(scan(readBytesFromFileSync(uri)).tokens);
}
