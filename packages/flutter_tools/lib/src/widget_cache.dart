// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'package:_fe_analyzer_shared/src/parser/parser.dart'; // ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/scanner/token.dart'; // ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/parser/listener.dart'; // ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'; // ignore: implementation_imports

import 'base/file_system.dart';
import 'features.dart';

/// The widget cache determines if the body of a single widget was modified since
/// the last scan of the token stream.
class WidgetCache {
  WidgetCache({
    @required FeatureFlags featureFlags,
    @required FileSystem fileSystem,
  }) : _featureFlags = featureFlags,
       _fileSystem = fileSystem;

  static const int _kCacheSize = 5;

  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final Map<Uri, _TokenCache> _cache = <Uri, _TokenCache>{};

  /// If the build method of a single widget was modified, return the widget name.
  ///
  /// If any other changes were made, or there is an error scanning the file,
  /// return `null`.
  Future<String> validateLibrary(Uri uri) async {
    if (!_featureFlags.isSingleWidgetReloadEnabled) {
      return null;
    }
    final File file = _fileSystem.file(uri);
    final Uint8List bytes = Uint8List(file.lengthSync() + 1);
    file.openSync().readIntoSync(bytes);
    final Utf8BytesScanner scanner = Utf8BytesScanner(
      bytes,
      includeComments: true,
    );
    final Token firstToken = scanner.tokenize();
    final WidgetBuildCollector collector = WidgetBuildCollector();
    final Token endToken = Parser(collector).parseUnit(firstToken);

    final _TokenCache tokenCache = _cache.remove(uri);
    if (tokenCache == null) {
       // Ensure that the cache does not grow beyond `_kCacheSize`.
      while (_cache.length + 1 > _kCacheSize) {
        final Uri keyToRemove = _cache.keys.first;
        _cache.remove(keyToRemove);
      }
      _cache[uri] = _TokenCache(firstToken, endToken);
      return null;
    } else {
      // preserve LRU behavior.
      _cache[uri] = tokenCache;
    }

    Token current = firstToken;
    Token currentPrev = tokenCache.startToken;

    // Walk forward through the token stream until the first difference is found.
    while (current != null && currentPrev != null && !current.isEof && !currentPrev.isEof) {
      if (current.type == TokenType.BAD_INPUT || currentPrev.type == TokenType.BAD_INPUT) {
        break;
      }
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
      if (current.type == TokenType.BAD_INPUT || currentPrev.type == TokenType.BAD_INPUT) {
        break;
      }
      if (currentEnd.lexeme != currentPrevEnd.lexeme) {
        break;
      }
      currentEnd = currentEnd.previous;
      currentPrevEnd = currentPrevEnd.previous;
    }

    // If either the beginning or end tokens are invalid, ensure that a full
    // reload is performed.
    if (current.type == TokenType.BAD_INPUT ||
        currentPrev.type == TokenType.BAD_INPUT ||
        currentEnd.type == TokenType.BAD_INPUT ||
        currentPrevEnd.type == TokenType.BAD_INPUT) {
      _cache.remove(uri);
      return null;
    }

    // If the beginning and end tokens are the same, there is no difference in
    // the token streams.
    if (currentEnd.lexeme == currentPrevEnd.lexeme
      && current.lexeme == currentPrev.lexeme) {
      // TODO(jonahwilliams): Technically this could skip the reassemble altogether.
      // to be safe, keep the old behavior for now.
      return null;
    }

    // Determine whether the delta lies entirely within the class body of a
    // Widget or State class declaration.
    final Map<Token, _ClassDeclaration> fenceStart = <Token, _ClassDeclaration>{};
    final Map<Token, _ClassDeclaration> fenceEnd = <Token, _ClassDeclaration>{};
    for (final _ClassDeclaration declaration in collector.declarations) {
      fenceStart[declaration.startToken] = declaration;
      fenceEnd[declaration.endToken] = declaration;
    }

    // Look backwards from the current token until the beginning of a class
    // declaration is hit. If the end of a class declaration or the beginning
    // of the file is hit, the diff is not valid.
    bool validRange = false;
    _ClassDeclaration containingClassBackwards;
    _ClassDeclaration containingClassForwards;
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
    _cache[uri] = _TokenCache(firstToken, endToken);
    if (validRange && containingClassForwards == containingClassBackwards) {
      return containingClassForwards.widgetName;
    }
    return null;
  }
}

class _TokenCache {
  _TokenCache(this.startToken, this.endToken);

  final Token startToken;
  final Token endToken;
}

class WidgetBuildCollector extends Listener {
  final List<_ClassDeclaration> declarations = <_ClassDeclaration>[];
  _ClassDeclaration currentDeclaration;

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    currentDeclaration = _ClassDeclaration()
      ..name = name.lexeme
      ..startToken = begin;
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    if (extendsKeyword != null) {
      if (extendsKeyword?.next?.lexeme == 'StatelessWidget') {
        currentDeclaration.isStatelessWidget = true;
        currentDeclaration.widgetName = currentDeclaration.name;
      } else if (extendsKeyword?.next?.lexeme == 'State') {
        // If next token is `<`, then token following is the widget name.
        // Otherwise the State class is for a dynamic widget and it might
        // not be safe to perform a fast reassemble.
        if (extendsKeyword?.next?.next?.lexeme != '<') {
          return;
        }
        currentDeclaration.isStatefulWidget = true;
        currentDeclaration.widgetName = extendsKeyword?.next?.next?.next?.lexeme;
      }
    }
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    currentDeclaration.endToken = endToken;
    if (currentDeclaration.isStatelessWidget || currentDeclaration.isStatefulWidget) {
      declarations.add(currentDeclaration);
    }
    currentDeclaration = null;
  }
}

class _ClassDeclaration {
  String name;
  String widgetName;
  bool isStatelessWidget = false;
  bool isStatefulWidget = false;
  Token endToken;
  Token startToken;
}
