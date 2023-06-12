// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parser;

class Token {
  static final RegExp _alpha = RegExp(r'^[0-9a-zA-Z_\-@]+$');

  final String? text;
  Token? next;

  Token(this.text);

  bool get eof => text == null;

  bool get isName {
    if (text == null || text!.isEmpty) return false;
    return _alpha.hasMatch(text!);
  }

  bool get isComment => text != null && text!.startsWith('//');

  String toString() => text == null ? 'EOF' : text!;
}

class Tokenizer {
  static final alphaNum =
      '@abcdefghijklmnopqrstuvwxyz-_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final whitespace = ' \n\t\r';

  String text;
  Token? _head;
  Token? _last;

  Tokenizer(this.text);

  Token? tokenize() {
    _emit(null);

    for (int i = 0; i < text.length; i++) {
      String c = text[i];

      if (whitespace.contains(c)) {
        // skip
      } else if (c == '/' && _peek(i) == '/') {
        int index = text.indexOf('\n', i);
        if (index == -1) index = text.length;
        _emit(text.substring(i, index));
        i = index;
      } else if (alphaNum.contains(c)) {
        int start = i;

        while (alphaNum.contains(_peek(i))) {
          i++;
        }

        _emit(text.substring(start, i + 1));
      } else {
        _emit(c);
      }
    }

    _emit(null);

    _head = _head!.next;

    return _head;
  }

  void _emit(String? value) {
    Token token = Token(value);
    if (_head == null) _head = token;
    if (_last != null) _last!.next = token;
    _last = token;
  }

  String _peek(int i) {
    i += 1;
    return i < text.length ? text[i] : String.fromCharCodes([0]);
  }

  String toString() {
    StringBuffer buf = StringBuffer();

    Token t = _head!;

    buf.write('[${t}]\n');

    while (!t.eof) {
      t = t.next!;
      buf.write('[${t}]\n');
    }

    return buf.toString().trim();
  }
}

abstract class Parser {
  final Token? startToken;

  Token? current;

  Parser(this.startToken);

  Token expect(String text) {
    Token t = advance()!;
    if (text != t.text) fail('expected ${text}, got ${t}');
    return t;
  }

  bool consume(String text) {
    if (peek()!.text == text) {
      advance();
      return true;
    } else {
      return false;
    }
  }

  Token? peek() => current == null
      ? startToken
      : current!.eof
          ? current
          : current!.next;

  Token expectName() {
    Token t = advance()!;
    if (!t.isName) fail('expected name token, got ${t}');
    return t;
  }

  Token? advance() {
    if (current == null) {
      current = startToken;
    } else if (!current!.eof) {
      current = current!.next;
    }

    return current;
  }

  String? collectComments() {
    StringBuffer buf = StringBuffer();

    while (peek()!.isComment) {
      Token t = advance()!;
      String str = t.text!.substring(2);

      if (str.startsWith(' ')) str = str.substring(1);

      if (str.startsWith('  ')) {
        buf.write('\n - ${str.substring(2)}');
      } else if (str.isEmpty) {
        buf.write('\n\n');
      } else {
        buf.write('${str} ');
      }
    }

    if (buf.isEmpty) return null;
    return buf
        .toString()
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        .trim();
  }

  String? consumeString() {
    StringBuffer buf = StringBuffer();
    String startQuotation = advance()!.text!;
    if (startQuotation != '"' && startQuotation != "'") {
      return null;
    }
    while (peek()!.text != startQuotation) {
      Token t = advance()!;
      if (t.text == null) {
        throw FormatException('Reached EOF');
      }
      buf.write('${t.text} ');
    }
    advance();
    return buf.toString().trim();
  }

  void validate(bool result, String message) {
    if (!result) throw 'expected ${message}';
  }

  void fail(String message) => throw message;
}
