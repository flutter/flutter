// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library _fe_analyzer_shared.scanner.main;

import 'io.dart' show readBytesFromFileSync;

import 'scanner.dart' show ErrorToken, Token, scan;

scanAll(Map<Uri, List<int>> files,
    {bool verbose = false, bool verify = false}) {
  Stopwatch sw = new Stopwatch()..start();
  int byteCount = 0;
  files.forEach((Uri uri, List<int> bytes) {
    Token token = scan(bytes).tokens;
    if (verbose) printTokens(token);
    if (verify) verifyErrorTokens(token, uri);
    byteCount += bytes.length - 1;
  });
  sw.stop();
  print("Scanning files took: ${sw.elapsed}");
  print("Bytes/ms: ${byteCount / sw.elapsedMilliseconds}");
}

void printTokens(Token token) {
  while (!token.isEof) {
    print("${token.charOffset}: $token");
    token = token.next!;
  }
}

/// Verify that the fasta scanner recovery has moved all of the ErrorTokens
/// to the beginning of the stream. If an out-of-order ErrorToken is
/// found, then print some diagnostic information and throw an exception.
void verifyErrorTokens(Token firstToken, Uri uri) {
  Token token = firstToken;
  while (token is ErrorToken) {
    token = token.next!;
  }

  while (!token.isEof) {
    if (token is ErrorToken) {
      print('Found out-of-order ErrorTokens when scanning:\n  $uri');

      // Rescan the token stream up to the error token to find the 10 tokens
      // before the out of order ErrorToken.
      Token errorToken = token;
      Token start = firstToken;
      int count = 0;
      token = firstToken;
      while (token != errorToken) {
        token = token.next!;
        if (count < 10) {
          ++count;
        } else {
          start = start.next!;
        }
      }

      // Print the out of order error token plus some tokens before and after.
      count = 0;
      token = start;
      while (count < 20 && !token.isEof) {
        print("${token.charOffset}: $token");
        token = token.next!;
        ++count;
      }
      throw 'Out of order ErrorToken: $errorToken';
    }
    token = token.next!;
  }
}

mainEntryPoint(List<String> arguments) {
  Map<Uri, List<int>> files = <Uri, List<int>>{};
  Stopwatch sw = new Stopwatch()..start();
  bool verbose = const bool.fromEnvironment("printTokens");
  bool verify = const bool.fromEnvironment('verifyErrorTokens');
  for (String arg in arguments) {
    if (arg.startsWith('--')) {
      if (arg == '--print-tokens') {
        verbose = true;
      } else if (arg == '--verify-error-tokens') {
        verify = true;
      } else {
        print('Unrecognized option: $arg');
      }
      continue;
    }

    Uri uri = Uri.base.resolve(arg);
    List<int> bytes = readBytesFromFileSync(uri);
    files[uri] = bytes;
  }
  sw.stop();
  print("Reading files took: ${sw.elapsed}");
  scanAll(files, verbose: verbose, verify: verify);
}
