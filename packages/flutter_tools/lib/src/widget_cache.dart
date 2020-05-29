// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:meta/meta.dart';

import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:_fe_analyzer_shared/src/parser/listener.dart';
import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart';

import 'base/file_system.dart';

/// Determines if a full reassemble can be skipped by checking if a file modification
/// is entirely contained in the body of a single StatelessWidget or State class.
class WidgetCache {
  WidgetCache({
    @required FileSystem fileSystem,
  }) : _fileSystem = fileSystem;

  final FileSystem _fileSystem;
  final Map<Uri, TokenCache> _cache = <Uri, TokenCache>{};

  /// Return the name of a single widget invalidation.
  String validate(Uri uri) {
    final Uint8List rawBytes = _fileSystem.file(uri).readAsBytesSync();
    final Uint8List resultBytes = Uint8List(rawBytes.length + 1);
    resultBytes.setRange(0, rawBytes.length, rawBytes);
    final Utf8BytesScanner scanner = Utf8BytesScanner(
      resultBytes,
      includeComments: true,
    );
    final Token firstToken = scanner.tokenize();
    final WidgetBuildCollector collector = WidgetBuildCollector();
    final Token endToken = Parser(collector).parseUnit(firstToken);

    final TokenCache tokenCache = _cache[uri];
    if (tokenCache == null) {
      _cache.clear(); // Ensure that there is only a single token stream cached at a time.
      _cache[uri] = TokenCache(firstToken, endToken);
      return null;
    }

    Token current = firstToken;
    Token currentPrev = tokenCache.startToken;

    // Walk forward through the token stream until the first difference is found.
    while (current != null && currentPrev != null && !current.isEof && !currentPrev.isEof) {
      if (current.lexeme != currentPrev.lexeme) {
        break;
      }
      current = current.next;
      currentPrev = currentPrev.next;
    }

    Token currentEnd = endToken;
    Token currentPrevEnd = tokenCache.endToken;

    // Walk background through the token stream until the first difference is found.
    while (currentEnd != current && currentPrevEnd != currentPrev) {
      if (currentEnd.lexeme != currentPrevEnd.lexeme) {
        break;
      }
      currentEnd = currentEnd.previous;
      currentPrevEnd = currentPrevEnd.previous;
    }

    // If the beginning and end tokens are the same, there is no difference in
    // the token streams.
    if (currentEnd.lexeme == currentPrevEnd.lexeme
      && current.lexeme == currentPrev.lexeme) {
      return null;
    }

    // Determine whether the delta lies entirely within the class body of a
    // Widget or State class declaration.
    final Map<Token, ClassDeclaration> fenceStart = <Token, ClassDeclaration>{};
    final Map<Token, ClassDeclaration> fenceEnd = <Token, ClassDeclaration>{};
    for (final ClassDeclaration declaration in collector.declarations) {
      fenceStart[declaration.startToken] = declaration;
      fenceEnd[declaration.endToken] = declaration;
    }

    // Look backwards from the current token until the beginning of a class
    // declaration is hit. If the end of a class declaration or the beginning
    // of the file is hit, the diff is not valid.
    bool validRange = false;
    ClassDeclaration containingClassBackwards;
    ClassDeclaration containingClassForwards;
    while (current != null) {
      if (fenceStart.containsKey(current)) {
        containingClassBackwards = fenceStart[current];
        validRange = true;
        break;
      }
      if (fenceEnd.containsKey(current)) {
        validRange = false;
        break;
      }
      if (current == firstToken) {
        validRange = false;
        break;
      }
      current = current.previous;
    }

    // Look forward from the current end token until the end of a class
    // declaration is hit. If the beginning of a class declaration or EOF
    // is hit, the diff is not valid.
    while (currentEnd != null) {
      if (fenceEnd.containsKey(currentEnd)) {
        containingClassForwards = fenceEnd[currentEnd];
        break;
      }
      if (fenceStart.containsKey(currentEnd)) {
        validRange = false;
        break;
      }
      if (currentEnd.isEof) {
        validRange = false;
        break;
      }
      currentEnd = currentEnd.next;
    }

    // If the class start and end correspond the same declaration, return the name
    // of the widget.
    _cache[uri] = TokenCache(firstToken, endToken);
    if (validRange && containingClassForwards == containingClassBackwards) {
      return containingClassForwards.name;
    }
    return null;
  }
}

void main() {
  final MemoryFileSystem fileSystem = MemoryFileSystem();
  final File dartFile = fileSystem.file('a.dart');
  dartFile.writeAsStringSync('''
class Foo extends StatelessWidget {

  Widget buildContext(context) {
    return Text('hello');
  }
}
  ''');
  final WidgetCache cache = WidgetCache(fileSystem: fileSystem);
  cache.validate(dartFile.uri);

  dartFile.writeAsStringSync('''

class Foo extends StatelessWidget {
  Widget buildContext(context) {
    return Text('he2llo');
  }
}
  ''');
  final Stopwatch sw = Stopwatch()..start();
  print( cache.validate(dartFile.uri));
  print(sw.elapsedMilliseconds);
}

class TokenCache {
  TokenCache(this.startToken, this.endToken);

  final Token startToken;
  final Token endToken;
}

class WidgetBuildCollector extends Listener {
  final List<ClassDeclaration> declarations = <ClassDeclaration>[];
  ClassDeclaration currentDeclaration;

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    currentDeclaration = ClassDeclaration()
      ..name = name.lexeme
      ..startToken = begin;
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    if (extendsKeyword != null && extendsKeyword?.next?.lexeme == 'StatelessWidget') {
      currentDeclaration.isStatelessWidget = true;
    }
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    currentDeclaration.endToken = endToken;
    if (currentDeclaration.isStatelessWidget) {
      declarations.add(currentDeclaration);
    }
    currentDeclaration = null;
  }
}

class ClassDeclaration {
  String name;
  Token startToken;
  bool isStatelessWidget = false;
  Token endToken;
}
