// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(reidbaker-agent): Remove once AGP 10 removes android.newDsl=false (https://github.com/flutter/flutter/issues/180137).

enum _GradleTokenKind {
  ident,
  string,
  number,
  lBrace,
  rBrace,
  lParen,
  rParen,
  lBracket,
  rBracket,
  dot,
  colon,
  comma,
  equals,
  arrow,
  semicolon,
  star,
  other,
}

final class _GradleToken {
  const _GradleToken(this.kind, this.text, this.line);

  final _GradleTokenKind kind;
  final String text;
  final int line;
}

final class _StringLexState {
  _StringLexState({required this.quote, required this.triple, this.dollarSlashy = false});

  final int quote;
  final bool triple;
  final bool dollarSlashy;
  final StringBuffer buffer = StringBuffer();
  int? interpolationBraceDepth;
}

final class _GuardDeclaration {
  const _GuardDeclaration({
    required this.name,
    required this.declarationIndex,
    required this.bodyStart,
    required this.bodyEnd,
  });

  final String name;
  final int declarationIndex;
  final int bodyStart;
  final int bodyEnd;
}

/// Lexical scanner for Groovy and Kotlin Gradle build files.
abstract final class GradleNewDslScanner {
  static const _unconditionalLegacyIdentifiers = <String>{
    'applicationVariants',
    'libraryVariants',
    'testVariants',
    'unitTestVariants',
    'variantFilter',
    'BaseExtension',
    'AppExtension',
    'BaseAppModuleExtension',
  };

  static const _dualPackageExtensionIdentifiers = <String>{
    'LibraryExtension',
    'TestedExtension',
    'TestExtension',
  };

  static const _directGuardIdentifiers = <String>{
    'ANDROID_GRADLE_PLUGIN_VERSION',
    'AndroidPluginVersion',
    'agpVersion',
    'pluginVersion',
  };

  static const _declarationKeywords = <String>{
    'def',
    'fun',
    'val',
    'var',
    'final',
    'boolean',
    'Boolean',
    'int',
    'Int',
    'String',
  };

  static const _slashyPrefixKeywords = <String>{'return', 'case', 'in', 'assert', 'throw', 'else'};

  static const _slashyPrefixOperators = <String>{
    '!',
    '~',
    '?',
    '?:',
    '&&',
    '||',
    '&',
    '|',
    '^',
    '==',
    '===',
    '!=',
    '!==',
    '=~',
    '==~',
    '<',
    '<=',
    '>',
    '>=',
    '+',
    '-',
    '%',
    '+=',
    '-=',
    '*=',
  };

  static const _lineContinuationTrailingOperators = <String>{
    '&&',
    '||',
    '?',
    '?:',
    '?.',
    '+',
    '-',
    '==',
    '===',
    '!=',
    '!==',
    '<',
    '<=',
    '>',
    '>=',
  };

  static const _lineContinuationLeadingOperators = <String>{
    '&&',
    '||',
    '?',
    '?:',
    '?.',
    '==',
    '===',
    '!=',
    '!==',
    '<',
    '<=',
    '>',
    '>=',
  };

  static const _legacyGradlePackage = <String>['com', 'android', 'build', 'gradle'];
  static const _newApiDslPackage = <String>['com', 'android', 'build', 'api', 'dsl'];

  static final _kotlinAndroidCatalogPattern = RegExp(
    r'^(?!.*multiplatform)(?:.*kotlin.*android|.*android.*kotlin)$',
    caseSensitive: false,
  );

  /// Whether [contents] uses a legacy Android Gradle Plugin DSL or variant API,
  /// or applies the `kotlin-android` plugin without an AGP-version,
  /// `android.builtInKotlin`, or `android.newDsl` guard.
  ///
  /// Uses [isKotlinDsl] to apply Kotlin raw-string and nested block-comment
  /// lexical rules instead of Groovy string and slashy-literal rules.
  static bool blocksNewDsl(String contents, {required bool isKotlinDsl}) {
    final List<_GradleToken> tokens = _tokenize(contents, isKotlinDsl: isKotlinDsl);
    if (tokens.isEmpty) {
      return false;
    }

    final List<int?> matchingClose = _computeMatchingDelimiters(tokens);
    final inPluginsBlock = List<bool>.filled(tokens.length, false);
    if (_hasBlockingPluginsBlockDeclaration(tokens, matchingClose, inPluginsBlock)) {
      return true;
    }
    if (_hasBlockingLegacyApiReference(tokens)) {
      return true;
    }
    return _hasUnguardedImperativeKotlinAndroidApply(tokens, matchingClose, inPluginsBlock);
  }

  static List<_GradleToken> _tokenize(String source, {required bool isKotlinDsl}) {
    final tokens = <_GradleToken>[];
    final stringStack = <_StringLexState>[];
    final int length = source.length;
    var i = 0;
    var line = 1;

    while (i < length) {
      final _StringLexState? activeString = stringStack.isNotEmpty ? stringStack.last : null;
      final int? activeInterpDepth = activeString?.interpolationBraceDepth;
      if (activeString != null && activeInterpDepth == null) {
        final int ch = source.codeUnitAt(i);
        if (activeString.dollarSlashy) {
          if (ch == 0x24 /* $ */ && i + 1 < length) {
            final int nextCh = source.codeUnitAt(i + 1);
            if (nextCh == 0x24 /* $ */ || nextCh == 0x2F /* / */ ) {
              activeString.buffer.writeCharCode(nextCh);
              i += 2;
              continue;
            }
            if (nextCh == 0x7B /* { */ ) {
              activeString.interpolationBraceDepth = 0;
              i += 2;
              continue;
            }
          }
          if (ch == 0x2F /* / */ && i + 1 < length && source.codeUnitAt(i + 1) == 0x24 /* $ */ ) {
            tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
            stringStack.removeLast();
            i += 2;
            continue;
          }
          if (ch == 0x0A /* \n */ ) {
            line++;
          }
          activeString.buffer.writeCharCode(ch);
          i++;
          continue;
        }

        if (ch == 0x5C /* \ */ && !(isKotlinDsl && activeString.triple)) {
          if (i + 1 < length) {
            if (source.codeUnitAt(i + 1) == 0x0A /* \n */ ) {
              line++;
            }
            activeString.buffer.writeCharCode(source.codeUnitAt(i + 1));
            i += 2;
            continue;
          }
          i++;
          continue;
        }
        if (activeString.quote == 0x22 /* " */ &&
            ch == 0x24 /* $ */ &&
            i + 1 < length &&
            source.codeUnitAt(i + 1) == 0x7B /* { */ ) {
          activeString.interpolationBraceDepth = 0;
          i += 2;
          continue;
        }
        if (activeString.triple) {
          if (ch == activeString.quote &&
              i + 2 < length &&
              source.codeUnitAt(i + 1) == activeString.quote &&
              source.codeUnitAt(i + 2) == activeString.quote) {
            while (i + 3 < length && source.codeUnitAt(i + 3) == activeString.quote) {
              activeString.buffer.writeCharCode(activeString.quote);
              i++;
            }
            tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
            stringStack.removeLast();
            i += 3;
            continue;
          }
          if (ch == 0x0A /* \n */ ) {
            line++;
          }
          activeString.buffer.writeCharCode(ch);
          i++;
          continue;
        }
        if (ch == activeString.quote) {
          tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
          stringStack.removeLast();
          i++;
          continue;
        }
        if (ch == 0x0A /* \n */ ) {
          tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
          stringStack.removeLast();
          line++;
          i++;
          continue;
        }
        activeString.buffer.writeCharCode(ch);
        i++;
        continue;
      }

      final int ch = source.codeUnitAt(i);
      if (ch == 0x0A /* \n */ ) {
        line++;
        i++;
        continue;
      }
      if (ch <= 0x20) {
        i++;
        continue;
      }

      // Groovy dollar-slashy string `$/.../$` (must precede `$` identifier lexing).
      if (!isKotlinDsl &&
          ch == 0x24 /* $ */ &&
          i + 1 < length &&
          source.codeUnitAt(i + 1) == 0x2F /* / */ ) {
        stringStack.add(_StringLexState(quote: 0, triple: false, dollarSlashy: true));
        i += 2;
        continue;
      }

      // Line comment `// ...`
      if (ch == 0x2F /* / */ && i + 1 < length && source.codeUnitAt(i + 1) == 0x2F /* / */ ) {
        i += 2;
        while (i < length && source.codeUnitAt(i) != 0x0A /* \n */ ) {
          i++;
        }
        continue;
      }

      // Block comment `/* ... */`
      if (ch == 0x2F /* / */ && i + 1 < length && source.codeUnitAt(i + 1) == 0x2A /* * */ ) {
        i += 2;
        var depth = 1;
        while (i < length && depth > 0) {
          final int c = source.codeUnitAt(i);
          if (c == 0x0A /* \n */ ) {
            line++;
            i++;
          } else if (isKotlinDsl &&
              c == 0x2F /* / */ &&
              i + 1 < length &&
              source.codeUnitAt(i + 1) == 0x2A /* * */ ) {
            depth++;
            i += 2;
          } else if (c == 0x2A /* * */ &&
              i + 1 < length &&
              source.codeUnitAt(i + 1) == 0x2F /* / */ ) {
            depth--;
            i += 2;
          } else {
            i++;
          }
        }
        continue;
      }

      // Groovy single-line slashy regex literal `/.../` in expression-prefix position.
      if (!isKotlinDsl && ch == 0x2F /* / */ && _canStartGroovySlashyLiteral(tokens, line)) {
        final int? slashEnd = _scanGroovySlashyEnd(source, i + 1, length);
        if (slashEnd != null) {
          tokens.add(
            _GradleToken(_GradleTokenKind.string, source.substring(i + 1, slashEnd), line),
          );
          i = slashEnd + 1;
          continue;
        }
      }

      // String and character literals
      if (ch == 0x22 /* " */ || ch == 0x27 /* ' */ ) {
        final bool isTriple =
            i + 2 < length &&
            source.codeUnitAt(i + 1) == ch &&
            source.codeUnitAt(i + 2) == ch &&
            (!isKotlinDsl || ch == 0x22 /* " */ );
        stringStack.add(_StringLexState(quote: ch, triple: isTriple));
        i += isTriple ? 3 : 1;
        continue;
      }

      // Backticked Kotlin identifier
      if (ch == 0x60 /* ` */ ) {
        final int start = i + 1;
        i++;
        while (i < length && source.codeUnitAt(i) != 0x60 && source.codeUnitAt(i) != 0x0A) {
          i++;
        }
        tokens.add(_GradleToken(_GradleTokenKind.ident, source.substring(start, i), line));
        if (i < length && source.codeUnitAt(i) == 0x60) {
          i++;
        }
        continue;
      }

      // Numeric literals
      if (ch >= 0x30 && ch <= 0x39) {
        final start = i;
        i++;
        while (i < length && _isIdentPart(source.codeUnitAt(i))) {
          i++;
        }
        tokens.add(_GradleToken(_GradleTokenKind.number, source.substring(start, i), line));
        continue;
      }

      // Identifiers
      if (_isIdentStart(ch)) {
        final start = i;
        i++;
        while (i < length && _isIdentPart(source.codeUnitAt(i))) {
          i++;
        }
        tokens.add(_GradleToken(_GradleTokenKind.ident, source.substring(start, i), line));
        continue;
      }

      if (ch == 0x7B /* { */ ) {
        if (activeString != null && activeInterpDepth != null) {
          activeString.interpolationBraceDepth = activeInterpDepth + 1;
        }
        tokens.add(_GradleToken(_GradleTokenKind.lBrace, '{', line));
        i++;
        continue;
      }
      if (ch == 0x7D /* } */ ) {
        if (activeString != null && activeInterpDepth != null) {
          if (activeInterpDepth == 0) {
            activeString.interpolationBraceDepth = null;
            i++;
            continue;
          }
          activeString.interpolationBraceDepth = activeInterpDepth - 1;
        }
        tokens.add(_GradleToken(_GradleTokenKind.rBrace, '}', line));
        i++;
        continue;
      }

      // Multi-character operators so standalone `=` and `->` are unambiguous.
      if (ch == 0x2D /* - */ && i + 1 < length && source.codeUnitAt(i + 1) == 0x3E /* > */ ) {
        tokens.add(_GradleToken(_GradleTokenKind.arrow, '->', line));
        i += 2;
        continue;
      }
      final int? multiOpEnd = _consumeMultiCharOperator(source, i, length);
      if (multiOpEnd != null) {
        tokens.add(_GradleToken(_GradleTokenKind.other, source.substring(i, multiOpEnd), line));
        i = multiOpEnd;
        continue;
      }

      final _GradleTokenKind kind = switch (ch) {
        0x28 /* ( */ => _GradleTokenKind.lParen,
        0x29 /* ) */ => _GradleTokenKind.rParen,
        0x5B /* [ */ => _GradleTokenKind.lBracket,
        0x5D /* ] */ => _GradleTokenKind.rBracket,
        0x2E /* . */ => _GradleTokenKind.dot,
        0x3A /* : */ => _GradleTokenKind.colon,
        0x2C /* , */ => _GradleTokenKind.comma,
        0x3D /* = */ => _GradleTokenKind.equals,
        0x3B /* ; */ => _GradleTokenKind.semicolon,
        0x2A /* * */ => _GradleTokenKind.star,
        _ => _GradleTokenKind.other,
      };
      tokens.add(_GradleToken(kind, String.fromCharCode(ch), line));
      i++;
    }

    while (stringStack.isNotEmpty) {
      final _StringLexState unclosed = stringStack.removeLast();
      tokens.add(_GradleToken(_GradleTokenKind.string, unclosed.buffer.toString(), line));
    }

    return tokens;
  }

  static int? _consumeMultiCharOperator(String source, int index, int length) {
    if (index + 1 >= length) {
      return null;
    }
    final int ch = source.codeUnitAt(index);
    final int next = source.codeUnitAt(index + 1);
    if (ch == 0x3D /* = */ ) {
      if (next == 0x3D /* = */ ) {
        return index + 2 < length && source.codeUnitAt(index + 2) == 0x3D ? index + 3 : index + 2;
      }
      if (next == 0x7E /* ~ */ || next == 0x3E /* > */ ) {
        return index + 2;
      }
      return null;
    }
    if (ch == 0x21 /* ! */ && next == 0x3D /* = */ ) {
      return index + 2 < length && source.codeUnitAt(index + 2) == 0x3D ? index + 3 : index + 2;
    }
    if ((ch == 0x3C /* < */ ||
            ch == 0x3E /* > */ ||
            ch == 0x2B /* + */ ||
            ch == 0x2D /* - */ ||
            ch == 0x2A /* * */ ||
            ch == 0x25 /* % */ ) &&
        next == 0x3D /* = */ ) {
      return index + 2;
    }
    if (ch == 0x3F /* ? */ && (next == 0x3A /* : */ || next == 0x2E /* . */ )) {
      return index + 2;
    }
    if ((ch == 0x26 /* & */ && next == 0x26) || (ch == 0x7C /* | */ && next == 0x7C)) {
      return index + 2;
    }
    return null;
  }

  static bool _canStartGroovySlashyLiteral(List<_GradleToken> tokens, int currentLine) {
    if (tokens.isEmpty) {
      return true;
    }
    final _GradleToken prev = tokens.last;
    if (prev.line < currentLine) {
      return true;
    }
    return switch (prev.kind) {
      _GradleTokenKind.lParen ||
      _GradleTokenKind.lBracket ||
      _GradleTokenKind.lBrace ||
      _GradleTokenKind.colon ||
      _GradleTokenKind.comma ||
      _GradleTokenKind.equals ||
      _GradleTokenKind.arrow ||
      _GradleTokenKind.semicolon => true,
      _GradleTokenKind.ident => _slashyPrefixKeywords.contains(prev.text),
      _GradleTokenKind.other => _slashyPrefixOperators.contains(prev.text),
      _GradleTokenKind.string ||
      _GradleTokenKind.number ||
      _GradleTokenKind.rBrace ||
      _GradleTokenKind.rParen ||
      _GradleTokenKind.rBracket ||
      _GradleTokenKind.dot ||
      _GradleTokenKind.star => false,
    };
  }

  static int? _scanGroovySlashyEnd(String source, int start, int length) {
    var k = start;
    while (k < length) {
      final int c = source.codeUnitAt(k);
      if (c == 0x0A /* \n */ || c == 0x0D /* \r */ ) {
        return null;
      }
      if (c == 0x5C /* \ */ && k + 1 < length && source.codeUnitAt(k + 1) == 0x2F /* / */ ) {
        k += 2;
        continue;
      }
      if (c == 0x2F /* / */ ) {
        return k;
      }
      k++;
    }
    return null;
  }

  static bool _isIdentStart(int ch) =>
      (ch >= 0x41 && ch <= 0x5A) ||
      (ch >= 0x61 && ch <= 0x7A) ||
      ch == 0x5F /* _ */ ||
      ch == 0x24 /* $ */;

  static bool _isIdentPart(int ch) => _isIdentStart(ch) || (ch >= 0x30 && ch <= 0x39);

  static List<int?> _computeMatchingDelimiters(List<_GradleToken> tokens) {
    final matching = List<int?>.filled(tokens.length, null);
    final braceStack = <int>[];
    final parenStack = <int>[];
    final bracketStack = <int>[];
    for (var i = 0; i < tokens.length; i++) {
      switch (tokens[i].kind) {
        case _GradleTokenKind.lBrace:
          braceStack.add(i);
        case _GradleTokenKind.rBrace:
          if (braceStack.isNotEmpty) {
            matching[braceStack.removeLast()] = i;
          }
        case _GradleTokenKind.lParen:
          parenStack.add(i);
        case _GradleTokenKind.rParen:
          if (parenStack.isNotEmpty) {
            matching[parenStack.removeLast()] = i;
          }
        case _GradleTokenKind.lBracket:
          bracketStack.add(i);
        case _GradleTokenKind.rBracket:
          if (bracketStack.isNotEmpty) {
            matching[bracketStack.removeLast()] = i;
          }
        case _GradleTokenKind.ident ||
            _GradleTokenKind.string ||
            _GradleTokenKind.number ||
            _GradleTokenKind.dot ||
            _GradleTokenKind.colon ||
            _GradleTokenKind.comma ||
            _GradleTokenKind.equals ||
            _GradleTokenKind.arrow ||
            _GradleTokenKind.semicolon ||
            _GradleTokenKind.star ||
            _GradleTokenKind.other:
          break;
      }
    }
    return matching;
  }

  static bool _hasBlockingPluginsBlockDeclaration(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    List<bool> inPluginsBlock,
  ) {
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.ident ||
          tokens[i].text != 'plugins' ||
          (i > 0 && tokens[i - 1].kind == _GradleTokenKind.dot) ||
          tokens[i + 1].kind != _GradleTokenKind.lBrace) {
        continue;
      }
      final int blockEnd = matchingClose[i + 1] ?? tokens.length;
      for (var k = i; k < blockEnd && k < tokens.length; k++) {
        inPluginsBlock[k] = true;
      }

      for (int j = i + 2; j < blockEnd; j++) {
        final int? afterSpec = _matchDeclarativeKotlinAndroidSpec(
          tokens,
          matchingClose,
          j,
          blockEnd,
        );
        if (afterSpec == null) {
          continue;
        }
        if (!_hasApplyFalseModifier(tokens, afterSpec, blockEnd)) {
          return true;
        }
      }
      i = blockEnd;
    }
    return false;
  }

  static int? _matchDeclarativeKotlinAndroidSpec(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    int index,
    int blockEnd,
  ) {
    final _GradleToken token = tokens[index];
    if (token.kind != _GradleTokenKind.ident ||
        (index > 0 && tokens[index - 1].kind == _GradleTokenKind.dot)) {
      return null;
    }
    if (_isKotlinAndroidPluginId(token.text)) {
      return index + 1;
    }
    if (token.text == 'id') {
      if (index + 1 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.string &&
          _isKotlinAndroidPluginId(tokens[index + 1].text)) {
        return index + 2;
      }
      if (index + 3 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.lParen &&
          tokens[index + 2].kind == _GradleTokenKind.string &&
          _isKotlinAndroidPluginId(tokens[index + 2].text) &&
          tokens[index + 3].kind == _GradleTokenKind.rParen) {
        return index + 4;
      }
      return null;
    }
    if (token.text == 'kotlin') {
      if (index + 1 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.string &&
          tokens[index + 1].text == 'android') {
        return index + 2;
      }
      if (index + 3 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.lParen &&
          tokens[index + 2].kind == _GradleTokenKind.string &&
          tokens[index + 2].text == 'android' &&
          tokens[index + 3].kind == _GradleTokenKind.rParen) {
        return index + 4;
      }
      return null;
    }
    if (token.text == 'alias' &&
        index + 1 < blockEnd &&
        tokens[index + 1].kind == _GradleTokenKind.lParen) {
      final int? closeParen = matchingClose[index + 1];
      if (closeParen == null || closeParen > blockEnd) {
        return null;
      }
      if (index + 6 < closeParen &&
          tokens[index + 2].kind == _GradleTokenKind.ident &&
          tokens[index + 2].text == 'libs' &&
          tokens[index + 3].kind == _GradleTokenKind.dot &&
          tokens[index + 4].kind == _GradleTokenKind.ident &&
          tokens[index + 4].text == 'plugins' &&
          tokens[index + 5].kind == _GradleTokenKind.dot) {
        final segments = <String>[];
        var validChain = true;
        for (int k = index + 6; k < closeParen; k += 2) {
          if (tokens[k].kind != _GradleTokenKind.ident) {
            validChain = false;
            break;
          }
          segments.add(tokens[k].text);
          if (k + 1 < closeParen && tokens[k + 1].kind != _GradleTokenKind.dot) {
            validChain = false;
            break;
          }
        }
        if (validChain && _kotlinAndroidCatalogPattern.hasMatch(segments.join('.'))) {
          return closeParen + 1;
        }
      }
    }
    return null;
  }

  static bool _hasApplyFalseModifier(List<_GradleToken> tokens, int start, int blockEnd) {
    var parenDepth = 0;
    for (var k = start; k < blockEnd; k++) {
      final _GradleToken token = tokens[k];
      if (parenDepth == 0) {
        if (token.kind == _GradleTokenKind.semicolon ||
            token.kind == _GradleTokenKind.lBrace ||
            token.kind == _GradleTokenKind.rBrace) {
          return false;
        }
        if (k > 0 && token.line > tokens[k - 1].line) {
          final _GradleToken prev = tokens[k - 1];
          final bool continuesPluginModifier =
              prev.kind == _GradleTokenKind.dot ||
              token.kind == _GradleTokenKind.dot ||
              (token.kind == _GradleTokenKind.ident &&
                  (token.text == 'version' || token.text == 'apply')) ||
              (prev.kind == _GradleTokenKind.ident &&
                  (prev.text == 'version' || prev.text == 'apply'));
          if (!continuesPluginModifier) {
            return false;
          }
        }
        final bool startsNextPluginSpec =
            token.kind == _GradleTokenKind.ident &&
            (k == 0 || tokens[k - 1].kind != _GradleTokenKind.dot) &&
            (_isKotlinAndroidPluginId(token.text) ||
                ((token.text == 'id' || token.text == 'kotlin' || token.text == 'alias') &&
                    k + 1 < blockEnd &&
                    (tokens[k + 1].kind == _GradleTokenKind.lParen ||
                        tokens[k + 1].kind == _GradleTokenKind.string)));
        if (startsNextPluginSpec) {
          return false;
        }
        if (token.kind == _GradleTokenKind.ident && token.text == 'apply') {
          if (k + 1 < blockEnd &&
              tokens[k + 1].kind == _GradleTokenKind.ident &&
              tokens[k + 1].text == 'false') {
            return true;
          }
          if (k + 3 < blockEnd &&
              tokens[k + 1].kind == _GradleTokenKind.lParen &&
              tokens[k + 2].kind == _GradleTokenKind.ident &&
              tokens[k + 2].text == 'false' &&
              tokens[k + 3].kind == _GradleTokenKind.rParen) {
            return true;
          }
        }
      }
      if (token.kind == _GradleTokenKind.lParen) {
        parenDepth++;
      } else if (token.kind == _GradleTokenKind.rParen && parenDepth > 0) {
        parenDepth--;
      }
    }
    return false;
  }

  static bool _hasBlockingLegacyApiReference(List<_GradleToken> tokens) {
    final explicitNewDslImports = <String>{};
    var importsNewDslWildcard = false;
    var importsLegacyGradleWildcard = false;

    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.ident || tokens[i].text != 'import') {
        continue;
      }
      final int? targetEnd = _consumeImportPath(tokens, i + 1);
      if (targetEnd == null) {
        continue;
      }
      final _GradleToken lastSegment = tokens[targetEnd - 1];
      if (lastSegment.kind == _GradleTokenKind.star) {
        if (_hasDottedPrefix(tokens, targetEnd - 1, _legacyGradlePackage)) {
          importsLegacyGradleWildcard = true;
        } else if (_hasDottedPrefix(tokens, targetEnd - 1, _newApiDslPackage)) {
          importsNewDslWildcard = true;
        }
      } else if (lastSegment.kind == _GradleTokenKind.ident &&
          _dualPackageExtensionIdentifiers.contains(lastSegment.text)) {
        if (_hasDottedPrefix(tokens, targetEnd - 1, _legacyGradlePackage)) {
          return true;
        }
        final bool hasDifferentAlias =
            targetEnd + 1 < tokens.length &&
            tokens[targetEnd].kind == _GradleTokenKind.ident &&
            tokens[targetEnd].text == 'as' &&
            tokens[targetEnd + 1].kind == _GradleTokenKind.ident &&
            tokens[targetEnd + 1].text != lastSegment.text;
        if (!hasDifferentAlias && _hasDottedPrefix(tokens, targetEnd - 1, _newApiDslPackage)) {
          explicitNewDslImports.add(lastSegment.text);
        }
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      final _GradleToken token = tokens[i];
      if (token.kind != _GradleTokenKind.ident) {
        continue;
      }
      if (_unconditionalLegacyIdentifiers.contains(token.text)) {
        return true;
      }
      if (_dualPackageExtensionIdentifiers.contains(token.text)) {
        if (_hasDottedPrefix(tokens, i, _legacyGradlePackage)) {
          return true;
        }
        if (_hasDottedPrefix(tokens, i, _newApiDslPackage)) {
          continue;
        }
        if (i > 0 && tokens[i - 1].kind == _GradleTokenKind.dot) {
          return true;
        }
        final bool resolvedFromNewDsl =
            explicitNewDslImports.contains(token.text) ||
            (importsNewDslWildcard && !importsLegacyGradleWildcard);
        if (!resolvedFromNewDsl) {
          return true;
        }
      }
    }
    return false;
  }

  static int? _consumeImportPath(List<_GradleToken> tokens, int start) {
    var index = start;
    if (index < tokens.length &&
        tokens[index].kind == _GradleTokenKind.ident &&
        tokens[index].text == 'static') {
      index++;
    }
    if (index >= tokens.length || tokens[index].kind != _GradleTokenKind.ident) {
      return null;
    }
    index++;
    while (index + 1 < tokens.length && tokens[index].kind == _GradleTokenKind.dot) {
      final _GradleToken next = tokens[index + 1];
      if (next.kind == _GradleTokenKind.star) {
        return index + 2;
      }
      if (next.kind != _GradleTokenKind.ident) {
        break;
      }
      index += 2;
    }
    return index;
  }

  static bool _hasDottedPrefix(List<_GradleToken> tokens, int targetIndex, List<String> prefix) {
    final int requiredTokens = prefix.length * 2;
    if (targetIndex < requiredTokens) {
      return false;
    }
    final int start = targetIndex - requiredTokens;
    if (start > 0 && tokens[start - 1].kind == _GradleTokenKind.dot) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      final _GradleToken segment = tokens[start + i * 2];
      final _GradleToken separator = tokens[start + i * 2 + 1];
      if (segment.kind != _GradleTokenKind.ident ||
          segment.text != prefix[i] ||
          separator.kind != _GradleTokenKind.dot) {
        return false;
      }
    }
    return true;
  }

  static bool _hasUnguardedImperativeKotlinAndroidApply(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    List<bool> inPluginsBlock,
  ) {
    final List<bool> inGuardedBody = _computeGuardedConditionalBodies(tokens, matchingClose);

    final kotlinPluginVariables = <String>{};
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.equals) {
        continue;
      }
      if (tokens[i + 1].kind == _GradleTokenKind.string &&
          _isKotlinAndroidPluginId(tokens[i + 1].text)) {
        final String? variableName = _extractAssignedVariableName(tokens, i);
        if (variableName != null) {
          kotlinPluginVariables.add(variableName);
        }
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      if (inPluginsBlock[i] ||
          tokens[i].kind != _GradleTokenKind.ident ||
          tokens[i].text != 'apply') {
        continue;
      }
      if (i + 1 >= tokens.length) {
        continue;
      }
      final _GradleToken next = tokens[i + 1];
      if (next.kind == _GradleTokenKind.lParen) {
        final int closeParen = matchingClose[i + 1] ?? tokens.length;
        final bool appliesViaNamedArg = _rangeHasPluginKeyTarget(
          tokens,
          i + 2,
          closeParen,
          kotlinPluginVariables,
          allowEquals: true,
        );
        final bool appliesViaContainer =
            _hasPluginContainerReceiver(tokens, i) &&
            i + 2 < closeParen &&
            _isKotlinAndroidTarget(tokens[i + 2], kotlinPluginVariables);
        if ((appliesViaNamedArg || appliesViaContainer) && !inGuardedBody[i]) {
          return true;
        }
      } else if (next.kind == _GradleTokenKind.lBrace) {
        final int closeBrace = matchingClose[i + 1] ?? tokens.length;
        for (int k = i + 2; k < closeBrace; k++) {
          if (tokens[k].kind != _GradleTokenKind.ident || tokens[k].text != 'plugin') {
            continue;
          }
          final bool parenCall =
              k + 2 < closeBrace &&
              tokens[k + 1].kind == _GradleTokenKind.lParen &&
              _isKotlinAndroidTarget(tokens[k + 2], kotlinPluginVariables);
          final bool bareCall =
              k + 1 < closeBrace &&
              tokens[k + 1].line == tokens[k].line &&
              _isKotlinAndroidTarget(tokens[k + 1], kotlinPluginVariables);
          if ((parenCall || bareCall) && !inGuardedBody[k]) {
            return true;
          }
        }
      } else {
        final int stmtEnd = _findSingleStatementEnd(tokens, matchingClose, i);
        final bool appliesViaMap = _rangeHasPluginKeyTarget(
          tokens,
          i + 1,
          stmtEnd,
          kotlinPluginVariables,
          allowEquals: false,
        );
        final bool appliesViaContainer =
            _hasPluginContainerReceiver(tokens, i) &&
            i + 1 < stmtEnd &&
            tokens[i + 1].line == tokens[i].line &&
            _isKotlinAndroidTarget(tokens[i + 1], kotlinPluginVariables);
        if ((appliesViaMap || appliesViaContainer) && !inGuardedBody[i]) {
          return true;
        }
      }
    }
    return false;
  }

  static List<bool> _computeGuardedConditionalBodies(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
  ) {
    final List<_GuardDeclaration> declarations = _collectGuardDeclarations(tokens, matchingClose);
    final guardIdentifiers = <String>{};
    var inGuardedBody = List<bool>.filled(tokens.length, false);

    for (var pass = 0; pass < 8; pass++) {
      var changed = false;
      for (final decl in declarations) {
        if (guardIdentifiers.contains(decl.name)) {
          continue;
        }
        final bool rhsHasGuard = _rangeHasGuardSignal(
          tokens,
          decl.bodyStart,
          decl.bodyEnd,
          guardIdentifiers,
        );
        final bool mutatedBooleanInGuardedBranch =
            inGuardedBody[decl.declarationIndex] &&
            _isBooleanLiteralAssignment(tokens, decl.bodyStart, decl.bodyEnd);
        if (rhsHasGuard || mutatedBooleanInGuardedBranch) {
          guardIdentifiers.add(decl.name);
          changed = true;
        }
      }

      final nextGuardedBody = List<bool>.filled(tokens.length, false);
      _markGuardedConditionals(tokens, matchingClose, guardIdentifiers, nextGuardedBody);
      for (var i = 0; i < tokens.length; i++) {
        if (nextGuardedBody[i] != inGuardedBody[i]) {
          changed = true;
          break;
        }
      }
      inGuardedBody = nextGuardedBody;
      if (!changed) {
        break;
      }
    }

    return inGuardedBody;
  }

  static List<_GuardDeclaration> _collectGuardDeclarations(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
  ) {
    final declarations = <_GuardDeclaration>[];

    // Helper functions: `(def|fun|<Type>) <name>(...) [: <Type>] ({ ... } | = <expr>)`
    for (var i = 0; i + 2 < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.ident ||
          !_declarationKeywords.contains(tokens[i].text) ||
          tokens[i + 1].kind != _GradleTokenKind.ident ||
          tokens[i + 2].kind != _GradleTokenKind.lParen) {
        continue;
      }
      final int? closeParen = matchingClose[i + 2];
      if (closeParen == null) {
        continue;
      }
      final String fnName = tokens[i + 1].text;
      int cursor = closeParen + 1;
      if (cursor < tokens.length && tokens[cursor].kind == _GradleTokenKind.colon) {
        cursor = _skipTypeAnnotation(tokens, cursor + 1);
      }
      if (cursor < tokens.length && tokens[cursor].kind == _GradleTokenKind.lBrace) {
        final int? closeBrace = matchingClose[cursor];
        if (closeBrace != null) {
          declarations.add(
            _GuardDeclaration(
              name: fnName,
              declarationIndex: i,
              bodyStart: cursor + 1,
              bodyEnd: closeBrace,
            ),
          );
        }
      } else if (cursor < tokens.length && tokens[cursor].kind == _GradleTokenKind.equals) {
        final int rhsEnd = _findSingleStatementEnd(tokens, matchingClose, cursor + 1);
        declarations.add(
          _GuardDeclaration(
            name: fnName,
            declarationIndex: i,
            bodyStart: cursor + 1,
            bodyEnd: rhsEnd,
          ),
        );
      }
    }

    // Variable and closure assignments: `<name> [: <Type>] = <rhs>`
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.equals) {
        continue;
      }
      final String? name = _extractAssignedVariableName(tokens, i);
      if (name == null) {
        continue;
      }
      if (tokens[i + 1].kind == _GradleTokenKind.lBrace) {
        final int? closeBrace = matchingClose[i + 1];
        if (closeBrace != null) {
          declarations.add(
            _GuardDeclaration(
              name: name,
              declarationIndex: i,
              bodyStart: i + 2,
              bodyEnd: closeBrace,
            ),
          );
        }
      } else {
        final int rhsEnd = _findSingleStatementEnd(tokens, matchingClose, i + 1);
        declarations.add(
          _GuardDeclaration(name: name, declarationIndex: i, bodyStart: i + 1, bodyEnd: rhsEnd),
        );
      }
    }

    return declarations;
  }

  static int _skipTypeAnnotation(List<_GradleToken> tokens, int start) {
    var cursor = start;
    var angleDepth = 0;
    while (cursor < tokens.length) {
      final _GradleToken token = tokens[cursor];
      if (angleDepth == 0 &&
          (token.kind == _GradleTokenKind.lBrace ||
              token.kind == _GradleTokenKind.equals ||
              token.kind == _GradleTokenKind.semicolon)) {
        break;
      }
      if (token.kind == _GradleTokenKind.other && token.text == '<') {
        angleDepth++;
      } else if (token.kind == _GradleTokenKind.other && token.text == '>' && angleDepth > 0) {
        angleDepth--;
      } else if (angleDepth == 0 &&
          token.kind != _GradleTokenKind.ident &&
          token.kind != _GradleTokenKind.dot &&
          !(token.kind == _GradleTokenKind.other && token.text == '?')) {
        break;
      }
      cursor++;
    }
    return cursor;
  }

  static String? _extractAssignedVariableName(List<_GradleToken> tokens, int equalsIndex) {
    if (equalsIndex < 1) {
      return null;
    }
    if (tokens[equalsIndex - 1].kind == _GradleTokenKind.ident &&
        (equalsIndex < 2 || tokens[equalsIndex - 2].kind != _GradleTokenKind.colon)) {
      final String candidate = tokens[equalsIndex - 1].text;
      if (candidate == 'plugin') {
        return null;
      }
      return candidate;
    }

    int cursor = equalsIndex - 1;
    var angleDepth = 0;
    while (cursor >= 0) {
      final _GradleToken token = tokens[cursor];
      if (angleDepth == 0 && token.kind == _GradleTokenKind.colon) {
        if (cursor >= 1 && tokens[cursor - 1].kind == _GradleTokenKind.ident) {
          final String candidate = tokens[cursor - 1].text;
          return candidate == 'plugin' ? null : candidate;
        }
        return null;
      }
      if (token.kind == _GradleTokenKind.other && token.text == '>') {
        angleDepth++;
      } else if (token.kind == _GradleTokenKind.other && token.text == '<' && angleDepth > 0) {
        angleDepth--;
      } else if (angleDepth == 0 &&
          token.kind != _GradleTokenKind.ident &&
          token.kind != _GradleTokenKind.dot &&
          !(token.kind == _GradleTokenKind.other && token.text == '?')) {
        return null;
      }
      cursor--;
    }
    return null;
  }

  static bool _isBooleanLiteralAssignment(List<_GradleToken> tokens, int start, int end) {
    if (start >= end || start >= tokens.length) {
      return false;
    }
    final _GradleToken first = tokens[start];
    return first.kind == _GradleTokenKind.ident && (first.text == 'true' || first.text == 'false');
  }

  static bool _rangeHasGuardSignal(
    List<_GradleToken> tokens,
    int start,
    int end,
    Set<String> guardIdentifiers,
  ) {
    final int clampedEnd = end < tokens.length ? end : tokens.length;
    for (var k = start; k < clampedEnd; k++) {
      final _GradleToken token = tokens[k];
      if (token.kind == _GradleTokenKind.ident &&
          (_directGuardIdentifiers.contains(token.text) || guardIdentifiers.contains(token.text))) {
        return true;
      }
      if (token.kind == _GradleTokenKind.string &&
          (token.text.contains('android.builtInKotlin') || token.text.contains('android.newDsl'))) {
        return true;
      }
    }
    return false;
  }

  static void _markGuardedConditionals(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    Set<String> guardIdentifiers,
    List<bool> inGuardedBody,
  ) {
    for (var i = 0; i + 1 < tokens.length; i++) {
      final _GradleToken token = tokens[i];
      if (token.kind != _GradleTokenKind.ident ||
          (i > 0 && tokens[i - 1].kind == _GradleTokenKind.dot)) {
        continue;
      }
      if (token.text == 'if' && tokens[i + 1].kind == _GradleTokenKind.lParen) {
        // Skip `else if` here because the enclosing `if` handles the chain.
        if (i > 0 && tokens[i - 1].kind == _GradleTokenKind.ident && tokens[i - 1].text == 'else') {
          continue;
        }
        _markIfChain(
          tokens,
          matchingClose,
          guardIdentifiers,
          inGuardedBody,
          i,
          inheritedGuard: false,
        );
      } else if (token.text == 'when') {
        _markWhenBlock(tokens, matchingClose, guardIdentifiers, inGuardedBody, i);
      }
    }
  }

  static int? _markIfChain(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    Set<String> guardIdentifiers,
    List<bool> inGuardedBody,
    int ifIndex, {
    required bool inheritedGuard,
  }) {
    if (ifIndex + 1 >= tokens.length || tokens[ifIndex + 1].kind != _GradleTokenKind.lParen) {
      return null;
    }
    final int? condClose = matchingClose[ifIndex + 1];
    if (condClose == null || condClose + 1 >= tokens.length) {
      return null;
    }
    final bool condGuarded =
        inheritedGuard ||
        inGuardedBody[ifIndex] ||
        _rangeHasGuardSignal(tokens, ifIndex + 2, condClose, guardIdentifiers);

    final int? rawThenEnd = _markBranchBody(
      tokens,
      matchingClose,
      guardIdentifiers,
      inGuardedBody,
      condClose + 1,
      markGuarded: condGuarded,
    );
    if (rawThenEnd == null) {
      return null;
    }
    int afterThen = rawThenEnd;
    while (afterThen < tokens.length && tokens[afterThen].kind == _GradleTokenKind.semicolon) {
      afterThen++;
    }
    if (afterThen + 1 < tokens.length &&
        tokens[afterThen].kind == _GradleTokenKind.ident &&
        tokens[afterThen].text == 'else') {
      final int elseBodyStart = afterThen + 1;
      if (tokens[elseBodyStart].kind == _GradleTokenKind.ident &&
          tokens[elseBodyStart].text == 'if') {
        return _markIfChain(
          tokens,
          matchingClose,
          guardIdentifiers,
          inGuardedBody,
          elseBodyStart,
          inheritedGuard: condGuarded,
        );
      }
      return _markBranchBody(
        tokens,
        matchingClose,
        guardIdentifiers,
        inGuardedBody,
        elseBodyStart,
        markGuarded: condGuarded,
      );
    }
    return afterThen;
  }

  static int? _markBranchBody(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    Set<String> guardIdentifiers,
    List<bool> inGuardedBody,
    int start, {
    required bool markGuarded,
  }) {
    if (start >= tokens.length) {
      return null;
    }
    if (tokens[start].kind == _GradleTokenKind.lBrace) {
      final int? closeBrace = matchingClose[start];
      if (closeBrace == null) {
        return null;
      }
      if (markGuarded) {
        for (int k = start + 1; k < closeBrace; k++) {
          inGuardedBody[k] = true;
        }
      }
      return closeBrace + 1;
    }
    if (tokens[start].kind == _GradleTokenKind.ident && tokens[start].text == 'if') {
      return _markIfChain(
        tokens,
        matchingClose,
        guardIdentifiers,
        inGuardedBody,
        start,
        inheritedGuard: markGuarded,
      );
    }
    final int stmtEnd = _findSingleStatementEnd(tokens, matchingClose, start);
    if (stmtEnd <= start) {
      return null;
    }
    if (markGuarded) {
      for (var k = start; k < stmtEnd; k++) {
        inGuardedBody[k] = true;
      }
    }
    return stmtEnd;
  }

  static void _markWhenBlock(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    Set<String> guardIdentifiers,
    List<bool> inGuardedBody,
    int whenIndex,
  ) {
    int braceOpen = whenIndex + 1;
    bool subjectGuarded = inGuardedBody[whenIndex];
    if (braceOpen < tokens.length && tokens[braceOpen].kind == _GradleTokenKind.lParen) {
      final int? subjClose = matchingClose[braceOpen];
      if (subjClose == null) {
        return;
      }
      if (_rangeHasGuardSignal(tokens, braceOpen + 1, subjClose, guardIdentifiers)) {
        subjectGuarded = true;
      }
      braceOpen = subjClose + 1;
    }
    if (braceOpen >= tokens.length || tokens[braceOpen].kind != _GradleTokenKind.lBrace) {
      return;
    }
    final int? braceClose = matchingClose[braceOpen];
    if (braceClose == null) {
      return;
    }

    int branchCondStart = braceOpen + 1;
    var anyPreviousBranchGuarded = false;
    int cursor = braceOpen + 1;
    while (cursor < braceClose) {
      final _GradleToken token = tokens[cursor];
      if (token.kind == _GradleTokenKind.lBrace ||
          token.kind == _GradleTokenKind.lParen ||
          token.kind == _GradleTokenKind.lBracket) {
        final int? close = matchingClose[cursor];
        if (close == null || close >= braceClose) {
          return;
        }
        cursor = close + 1;
        continue;
      }
      if (token.kind == _GradleTokenKind.arrow) {
        final bool branchGuarded =
            subjectGuarded ||
            anyPreviousBranchGuarded ||
            _rangeHasGuardSignal(tokens, branchCondStart, cursor, guardIdentifiers);
        if (branchGuarded) {
          anyPreviousBranchGuarded = true;
        }
        final int bodyStart = cursor + 1;
        if (bodyStart >= braceClose) {
          return;
        }
        int bodyEnd;
        if (tokens[bodyStart].kind == _GradleTokenKind.lBrace) {
          final int? closeBodyBrace = matchingClose[bodyStart];
          if (closeBodyBrace == null || closeBodyBrace > braceClose) {
            return;
          }
          if (branchGuarded) {
            for (int k = bodyStart + 1; k < closeBodyBrace; k++) {
              inGuardedBody[k] = true;
            }
          }
          bodyEnd = closeBodyBrace + 1;
        } else {
          final int rawEnd = _findSingleStatementEnd(tokens, matchingClose, bodyStart);
          bodyEnd = rawEnd < braceClose ? rawEnd : braceClose;
          if (branchGuarded) {
            for (var k = bodyStart; k < bodyEnd; k++) {
              inGuardedBody[k] = true;
            }
          }
        }
        while (bodyEnd < braceClose && tokens[bodyEnd].kind == _GradleTokenKind.semicolon) {
          bodyEnd++;
        }
        branchCondStart = bodyEnd;
        cursor = bodyEnd;
        continue;
      }
      cursor++;
    }
  }

  static bool _rangeHasPluginKeyTarget(
    List<_GradleToken> tokens,
    int start,
    int end,
    Set<String> kotlinPluginVariables, {
    required bool allowEquals,
  }) {
    for (var k = start; k + 2 < end; k++) {
      final _GradleToken key = tokens[k];
      final bool isPluginKey =
          (key.kind == _GradleTokenKind.ident || key.kind == _GradleTokenKind.string) &&
          key.text == 'plugin';
      final _GradleToken sep = tokens[k + 1];
      final bool validSep =
          sep.kind == _GradleTokenKind.colon ||
          (allowEquals && sep.kind == _GradleTokenKind.equals) ||
          (sep.kind == _GradleTokenKind.ident && sep.text == 'to');
      if (isPluginKey && validSep && _isKotlinAndroidTarget(tokens[k + 2], kotlinPluginVariables)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasPluginContainerReceiver(List<_GradleToken> tokens, int applyIndex) {
    if (applyIndex < 2 || tokens[applyIndex - 1].kind != _GradleTokenKind.dot) {
      return false;
    }
    final _GradleToken receiver = tokens[applyIndex - 2];
    if (receiver.kind == _GradleTokenKind.ident &&
        (receiver.text == 'pluginManager' || receiver.text == 'plugins')) {
      return true;
    }
    if (applyIndex >= 4 &&
        receiver.kind == _GradleTokenKind.rParen &&
        tokens[applyIndex - 3].kind == _GradleTokenKind.lParen &&
        tokens[applyIndex - 4].kind == _GradleTokenKind.ident &&
        (tokens[applyIndex - 4].text == 'getPluginManager' ||
            tokens[applyIndex - 4].text == 'getPlugins')) {
      return true;
    }
    return false;
  }

  static int _findSingleStatementEnd(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    int start,
  ) {
    var j = start;
    while (j < tokens.length) {
      final _GradleToken token = tokens[j];
      if (token.kind == _GradleTokenKind.semicolon ||
          token.kind == _GradleTokenKind.rBrace ||
          token.kind == _GradleTokenKind.rParen ||
          token.kind == _GradleTokenKind.rBracket ||
          (token.kind == _GradleTokenKind.ident && token.text == 'else')) {
        return j;
      }
      if (token.kind == _GradleTokenKind.lParen ||
          token.kind == _GradleTokenKind.lBrace ||
          token.kind == _GradleTokenKind.lBracket) {
        final int? close = matchingClose[j];
        if (close == null) {
          return start;
        }
        final wasBrace = token.kind == _GradleTokenKind.lBrace;
        j = close + 1;
        if (j >= tokens.length) {
          return j;
        }
        if (wasBrace && !_continuesAcrossLineBreakAfterGroup(tokens[j])) {
          return j;
        }
        if (tokens[j].line > tokens[close].line &&
            !_continuesAcrossLineBreakAfterGroup(tokens[j]) &&
            tokens[j].kind != _GradleTokenKind.lBrace) {
          return j;
        }
        continue;
      }
      if (j + 1 >= tokens.length) {
        return j + 1;
      }
      final _GradleToken next = tokens[j + 1];
      if (next.line > token.line && !_continuesStatementAcrossNewline(token, next)) {
        return j + 1;
      }
      j++;
    }
    return j;
  }

  static bool _continuesAcrossLineBreakAfterGroup(_GradleToken next) {
    return next.kind == _GradleTokenKind.dot ||
        (next.kind == _GradleTokenKind.other &&
            _lineContinuationLeadingOperators.contains(next.text));
  }

  static bool _continuesStatementAcrossNewline(_GradleToken current, _GradleToken next) {
    if (current.kind == _GradleTokenKind.dot ||
        current.kind == _GradleTokenKind.colon ||
        current.kind == _GradleTokenKind.comma ||
        current.kind == _GradleTokenKind.equals ||
        next.kind == _GradleTokenKind.dot) {
      return true;
    }
    if (current.kind == _GradleTokenKind.other &&
        _lineContinuationTrailingOperators.contains(current.text)) {
      return true;
    }
    if (next.kind == _GradleTokenKind.other &&
        _lineContinuationLeadingOperators.contains(next.text)) {
      return true;
    }
    return false;
  }

  static bool _isKotlinAndroidTarget(_GradleToken token, Set<String> kotlinPluginVariables) =>
      (token.kind == _GradleTokenKind.string && _isKotlinAndroidPluginId(token.text)) ||
      (token.kind == _GradleTokenKind.ident && kotlinPluginVariables.contains(token.text));

  static bool _isKotlinAndroidPluginId(String value) =>
      value == 'kotlin-android' || value == 'org.jetbrains.kotlin.android';
}
