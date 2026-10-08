// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Names that gclient injects into the `vars` dictionary at sync time.
///
/// Their values depend on the host running gclient, so this library does not
/// substitute them: references stay as `{name}` placeholders in the evaluated
/// strings and consumers decide how to resolve them.
///
/// See `_get_builtin_vars` in `gclient.py`.
const Set<String> gclientBuiltinVars = <String>{
  'host_os',
  'host_cpu',
  'checkout_android',
  'checkout_chromeos',
  'checkout_fuchsia',
  'checkout_ios',
  'checkout_linux',
  'checkout_mac',
  'checkout_win',
  'checkout_arm',
  'checkout_arm64',
  'checkout_mips',
  'checkout_mips64',
  'checkout_ppc',
  'checkout_s390',
  'checkout_x64',
  'checkout_x86',
};

/// An error found while parsing or evaluating a `DEPS` file.
final class DepsFormatException implements FormatException {
  /// Creates an exception for a problem at [line] (1-based) of [fileName].
  DepsFormatException(this.message, {required this.fileName, required this.line});

  @override
  final String message;

  /// The name of the file being parsed, used in [toString].
  final String fileName;

  /// The 1-based line the problem was found on.
  final int line;

  @override
  int? get offset => null;

  @override
  Object? get source => null;

  @override
  String toString() => '$fileName:$line: $message';
}

/// A single entry of the `deps` dictionary.
@immutable
sealed class Dep {
  const Dep({required this.path, required this.condition});

  /// Where the dependency is checked out, relative to the gclient root.
  ///
  /// For this repository the gclient root is the repository root.
  final String path;

  /// The gclient condition expression guarding the dependency, if any.
  ///
  /// Conditions are kept verbatim (for example `host_os == "linux"`); this
  /// library does not evaluate them.
  final String? condition;
}

/// A git dependency (`dep_type: git`, the default).
final class GitDep extends Dep {
  /// Creates a git dependency.
  const GitDep({
    required super.path,
    required super.condition,
    required this.url,
    required this.revision,
  });

  /// The repository URL, without the `@revision` suffix.
  final String url;

  /// The pinned revision (commit hash, tag or branch), or `null` if the
  /// dependency is not pinned.
  final String? revision;

  @override
  String toString() => 'GitDep($path -> $url@$revision)';
}

/// A CIPD package installed as part of a [CipdDep].
@immutable
final class CipdPackage {
  /// Creates a package reference.
  const CipdPackage({required this.package, required this.version});

  /// The CIPD package name, which may contain `${platform}`-style templates.
  final String package;

  /// The CIPD version, tag or ref to install.
  final String version;

  @override
  bool operator ==(Object other) =>
      other is CipdPackage && other.package == package && other.version == version;

  @override
  int get hashCode => Object.hash(package, version);

  @override
  String toString() => '$package@$version';
}

/// A CIPD dependency (`dep_type: cipd`).
final class CipdDep extends Dep {
  /// Creates a CIPD dependency.
  const CipdDep({required super.path, required super.condition, required this.packages});

  /// The packages installed into [path].
  final List<CipdPackage> packages;

  @override
  String toString() => 'CipdDep($path -> $packages)';
}

/// The evaluated contents of a gclient `DEPS` file.
///
/// gclient never executes a `DEPS` file. It walks the Python AST and accepts
/// only assignments of literals (strings, booleans, numbers, lists and
/// dictionaries), the `Var()` and `Str()` helpers and the `+` and `%`
/// operators on those (see `gclient_eval.py` in depot_tools). This class
/// implements the same subset so that build tooling written in Dart can read
/// the file without a Python interpreter.
///
/// String literals are formatted against the `vars` dictionary exactly like
/// gclient does (`'{name}'.format(**vars)`), except that references to
/// [gclientBuiltinVars] are preserved as `{name}` placeholders because their
/// values are host specific.
final class DepsFile {
  DepsFile._({
    required this.vars,
    required this.deps,
    required this.hooks,
    required this.gclientGnArgsFile,
    required this.gclientGnArgs,
    required this.allowedHosts,
    required this.recursedeps,
  });

  /// Parses and evaluates [contents].
  ///
  /// Throws a [DepsFormatException] if the file uses constructs outside the
  /// subset gclient accepts, references an undeclared variable, or declares
  /// a dependency that does not match gclient's schema.
  factory DepsFile.parse(String contents, {String fileName = 'DEPS'}) {
    final Map<String, _Expression> statements = _Parser(contents, fileName).parseModule();

    // `vars` is evaluated first and without substitution; everything else is
    // evaluated with the resulting dictionary, mirroring `gclient_eval.Exec`.
    var vars = const <String, Object?>{};
    final _Expression? varsExpression = statements['vars'];
    if (varsExpression != null) {
      final Object? value = _Evaluator(fileName: fileName, vars: null).evaluate(varsExpression);
      if (value is! Map<String, Object?>) {
        throw DepsFormatException(
          'vars must be a dictionary',
          fileName: fileName,
          line: varsExpression.line,
        );
      }
      vars = value;
    }

    final evaluator = _Evaluator(fileName: fileName, vars: vars);
    final values = <String, Object?>{};
    for (final MapEntry<String, _Expression> entry in statements.entries) {
      if (entry.key == 'vars') {
        values[entry.key] = vars;
      } else {
        values[entry.key] = evaluator.evaluate(entry.value);
      }
    }

    return DepsFile._(
      vars: Map<String, Object?>.unmodifiable(vars),
      deps: List<Dep>.unmodifiable(_standardizeDeps(values['deps'], statements['deps'], fileName)),
      hooks: List<Map<String, Object?>>.unmodifiable(
        _expectListOfMaps(values['hooks'], 'hooks', statements['hooks'], fileName),
      ),
      gclientGnArgsFile: _expectOptionalString(
        values['gclient_gn_args_file'],
        'gclient_gn_args_file',
        statements['gclient_gn_args_file'],
        fileName,
      ),
      gclientGnArgs: List<String>.unmodifiable(
        _expectListOfStrings(
          values['gclient_gn_args'],
          'gclient_gn_args',
          statements['gclient_gn_args'],
          fileName,
        ),
      ),
      allowedHosts: List<String>.unmodifiable(
        _expectListOfStrings(
          values['allowed_hosts'],
          'allowed_hosts',
          statements['allowed_hosts'],
          fileName,
        ),
      ),
      recursedeps: List<String>.unmodifiable(
        _expectListOfStrings(
          values['recursedeps'],
          'recursedeps',
          statements['recursedeps'],
          fileName,
        ),
      ),
    );
  }

  /// The `vars` dictionary, as declared (without substitution).
  final Map<String, Object?> vars;

  /// The `deps` entries, in file order.
  final List<Dep> deps;

  /// The `hooks` entries, in file order, as evaluated dictionaries.
  final List<Map<String, Object?>> hooks;

  /// The `gclient_gn_args_file` path, relative to the gclient root.
  final String? gclientGnArgsFile;

  /// The names of the variables gclient writes to [gclientGnArgsFile].
  final List<String> gclientGnArgs;

  /// The `allowed_hosts` list.
  final List<String> allowedHosts;

  /// The `recursedeps` list.
  final List<String> recursedeps;

  /// The git dependencies, in file order.
  Iterable<GitDep> get gitDeps => deps.whereType<GitDep>();

  /// The CIPD dependencies, in file order.
  Iterable<CipdDep> get cipdDeps => deps.whereType<CipdDep>();

  static List<Dep> _standardizeDeps(Object? value, _Expression? expression, String fileName) {
    if (value == null) {
      return const <Dep>[];
    }
    final int line = expression?.line ?? 0;
    if (value is! Map<String, Object?>) {
      throw DepsFormatException('deps must be a dictionary', fileName: fileName, line: line);
    }
    final result = <Dep>[];
    for (final MapEntry<String, Object?> entry in value.entries) {
      final String path = entry.key;
      final Object? spec = entry.value;
      // A bare string is shorthand for a git dependency.
      final Map<String, Object?> info = switch (spec) {
        final String url => <String, Object?>{'url': url},
        final Map<String, Object?> map => map,
        _ => throw DepsFormatException(
          'deps["$path"] must be a string or a dictionary',
          fileName: fileName,
          line: line,
        ),
      };
      final Object? condition = info['condition'];
      if (condition != null && condition is! String) {
        throw DepsFormatException(
          'deps["$path"]: condition must be a string',
          fileName: fileName,
          line: line,
        );
      }
      final depType = (info['dep_type'] ?? 'git') as String;
      switch (depType) {
        case 'git':
          final Object? url = info['url'];
          if (url is! String) {
            throw DepsFormatException(
              'deps["$path"]: git dependencies require a url',
              fileName: fileName,
              line: line,
            );
          }
          // gclient splits the revision off at the last '@'.
          final int at = url.lastIndexOf('@');
          result.add(
            GitDep(
              path: path,
              condition: condition as String?,
              url: at < 0 ? url : url.substring(0, at),
              revision: at < 0 ? null : url.substring(at + 1),
            ),
          );
        case 'cipd':
          final Object? packages = info['packages'];
          if (packages is! List<Object?>) {
            throw DepsFormatException(
              'deps["$path"]: cipd dependencies require a packages list',
              fileName: fileName,
              line: line,
            );
          }
          result.add(
            CipdDep(
              path: path,
              condition: condition as String?,
              packages: List<CipdPackage>.unmodifiable(
                packages.map((Object? package) {
                  if (package is! Map<String, Object?> ||
                      package['package'] is! String ||
                      package['version'] is! String) {
                    throw DepsFormatException(
                      'deps["$path"]: every package needs a package and a version string',
                      fileName: fileName,
                      line: line,
                    );
                  }
                  return CipdPackage(
                    package: package['package']! as String,
                    version: package['version']! as String,
                  );
                }),
              ),
            ),
          );
        default:
          throw DepsFormatException(
            'deps["$path"]: unsupported dep_type "$depType"',
            fileName: fileName,
            line: line,
          );
      }
    }
    return result;
  }

  static List<Map<String, Object?>> _expectListOfMaps(
    Object? value,
    String name,
    _Expression? expression,
    String fileName,
  ) {
    if (value == null) {
      return const <Map<String, Object?>>[];
    }
    if (value is List<Object?> && value.every((Object? e) => e is Map<String, Object?>)) {
      return value.cast<Map<String, Object?>>();
    }
    throw DepsFormatException(
      '$name must be a list of dictionaries',
      fileName: fileName,
      line: expression?.line ?? 0,
    );
  }

  static List<String> _expectListOfStrings(
    Object? value,
    String name,
    _Expression? expression,
    String fileName,
  ) {
    if (value == null) {
      return const <String>[];
    }
    if (value is List<Object?> && value.every((Object? e) => e is String)) {
      return value.cast<String>();
    }
    throw DepsFormatException(
      '$name must be a list of strings',
      fileName: fileName,
      line: expression?.line ?? 0,
    );
  }

  static String? _expectOptionalString(
    Object? value,
    String name,
    _Expression? expression,
    String fileName,
  ) {
    if (value == null || value is String) {
      return value as String?;
    }
    throw DepsFormatException(
      '$name must be a string',
      fileName: fileName,
      line: expression?.line ?? 0,
    );
  }
}

// -----------------------------------------------------------------------------
// Tokenizer
// -----------------------------------------------------------------------------

enum _TokenType { identifier, string, number, punctuation, endOfFile }

final class _Token {
  const _Token(this.type, this.text, this.line);

  final _TokenType type;

  /// For strings this is the decoded value; otherwise the source text.
  final String text;
  final int line;

  @override
  String toString() => switch (type) {
    _TokenType.endOfFile => 'end of file',
    _TokenType.string => 'string ${_quote(text)}',
    _ => '"$text"',
  };

  static String _quote(String s) => "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
}

final class _Tokenizer {
  _Tokenizer(this._source, this._fileName);

  final String _source;
  final String _fileName;
  int _offset = 0;
  int _line = 1;

  static final RegExp _identifierStart = RegExp(r'[A-Za-z_]');
  static final RegExp _identifierPart = RegExp(r'[A-Za-z0-9_]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static const String _punctuation = '{}[](),:=+%';

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (true) {
      _skipWhitespaceAndComments();
      if (_offset >= _source.length) {
        tokens.add(_Token(_TokenType.endOfFile, '', _line));
        return tokens;
      }
      final String c = _source[_offset];
      if (c == "'" || c == '"') {
        tokens.add(_readString(prefix: ''));
      } else if (_identifierStart.hasMatch(c)) {
        final int start = _offset;
        while (_offset < _source.length && _identifierPart.hasMatch(_source[_offset])) {
          _offset++;
        }
        final String text = _source.substring(start, _offset);
        // String prefixes (r'...', u'...', b'...').
        if (_offset < _source.length &&
            (_source[_offset] == "'" || _source[_offset] == '"') &&
            RegExp(r'^(r|u|b|br|rb)$', caseSensitive: false).hasMatch(text)) {
          tokens.add(_readString(prefix: text.toLowerCase()));
        } else {
          tokens.add(_Token(_TokenType.identifier, text, _line));
        }
      } else if (_digit.hasMatch(c)) {
        final int start = _offset;
        while (_offset < _source.length && _digit.hasMatch(_source[_offset])) {
          _offset++;
        }
        tokens.add(_Token(_TokenType.number, _source.substring(start, _offset), _line));
      } else if (_punctuation.contains(c)) {
        tokens.add(_Token(_TokenType.punctuation, c, _line));
        _offset++;
      } else if (c == r'\' && _offset + 1 < _source.length && _source[_offset + 1] == '\n') {
        // Explicit line continuation.
        _offset += 2;
        _line++;
      } else {
        throw DepsFormatException('unexpected character "$c"', fileName: _fileName, line: _line);
      }
    }
  }

  void _skipWhitespaceAndComments() {
    while (_offset < _source.length) {
      final String c = _source[_offset];
      if (c == '\n') {
        _line++;
        _offset++;
      } else if (c == ' ' || c == '\t' || c == '\r') {
        _offset++;
      } else if (c == '#') {
        while (_offset < _source.length && _source[_offset] != '\n') {
          _offset++;
        }
      } else {
        return;
      }
    }
  }

  _Token _readString({required String prefix}) {
    final int line = _line;
    final String quote = _source[_offset];
    final bool triple = _source.startsWith(quote * 3, _offset);
    final String delimiter = triple ? quote * 3 : quote;
    _offset += delimiter.length;
    final bool raw = prefix.contains('r');
    final value = StringBuffer();
    while (true) {
      if (_offset >= _source.length) {
        throw DepsFormatException('unterminated string literal', fileName: _fileName, line: line);
      }
      if (_source.startsWith(delimiter, _offset)) {
        _offset += delimiter.length;
        return _Token(_TokenType.string, value.toString(), line);
      }
      final String c = _source[_offset];
      if (c == '\n') {
        if (!triple) {
          throw DepsFormatException(
            'newline in single-quoted string literal',
            fileName: _fileName,
            line: line,
          );
        }
        _line++;
        value.write(c);
        _offset++;
      } else if (c == r'\' && _offset + 1 < _source.length) {
        final String next = _source[_offset + 1];
        if (raw) {
          value.write(c);
          value.write(next);
          _offset += 2;
          continue;
        }
        switch (next) {
          case '\n':
            _line++;
          case r'\':
            value.write(r'\');
          case "'":
            value.write("'");
          case '"':
            value.write('"');
          case 'n':
            value.write('\n');
          case 't':
            value.write('\t');
          case 'r':
            value.write('\r');
          case '0':
            value.write('\x00');
          default:
            // Python keeps unknown escapes verbatim.
            value.write(c);
            value.write(next);
        }
        _offset += 2;
      } else {
        value.write(c);
        _offset++;
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Parser
// -----------------------------------------------------------------------------

sealed class _Expression {
  const _Expression(this.line);

  final int line;
}

final class _StringLiteral extends _Expression {
  const _StringLiteral(this.value, super.line);

  final String value;
}

final class _NumberLiteral extends _Expression {
  const _NumberLiteral(this.value, super.line);

  final int value;
}

final class _NameLiteral extends _Expression {
  const _NameLiteral(this.name, super.line);

  final String name;
}

final class _ListLiteral extends _Expression {
  const _ListLiteral(this.elements, super.line);

  final List<_Expression> elements;
}

final class _DictLiteral extends _Expression {
  const _DictLiteral(this.entries, super.line);

  final List<(_Expression, _Expression)> entries;
}

final class _Call extends _Expression {
  const _Call(this.function, this.arguments, super.line);

  final String function;
  final List<_Expression> arguments;
}

final class _BinaryOperation extends _Expression {
  const _BinaryOperation(this.operator, this.left, this.right, super.line);

  final String operator;
  final _Expression left;
  final _Expression right;
}

final class _Parser {
  _Parser(String source, this._fileName) : _tokens = _Tokenizer(source, _fileName).tokenize();

  final String _fileName;
  final List<_Token> _tokens;
  int _index = 0;

  _Token get _current => _tokens[_index];

  /// Parses `name = expression` statements until the end of the file.
  Map<String, _Expression> parseModule() {
    final statements = <String, _Expression>{};
    while (_current.type != _TokenType.endOfFile) {
      final _Token name = _expect(_TokenType.identifier, 'a variable name');
      _expectPunctuation('=');
      if (statements.containsKey(name.text)) {
        throw DepsFormatException(
          'invalid assignment: overrides var "${name.text}"',
          fileName: _fileName,
          line: name.line,
        );
      }
      statements[name.text] = _parseExpression();
    }
    return statements;
  }

  _Expression _parseExpression() {
    _Expression left = _parsePrimary();
    while (_current.type == _TokenType.punctuation &&
        (_current.text == '+' || _current.text == '%')) {
      final _Token operator = _advance();
      final _Expression right = _parsePrimary();
      left = _BinaryOperation(operator.text, left, right, operator.line);
    }
    return left;
  }

  _Expression _parsePrimary() {
    final _Token token = _current;
    switch (token.type) {
      case _TokenType.string:
        _advance();
        // Adjacent string literals are concatenated, as in Python.
        final value = StringBuffer(token.text);
        while (_current.type == _TokenType.string) {
          value.write(_advance().text);
        }
        return _StringLiteral(value.toString(), token.line);
      case _TokenType.number:
        _advance();
        return _NumberLiteral(int.parse(token.text), token.line);
      case _TokenType.identifier:
        _advance();
        if (_current.type == _TokenType.punctuation && _current.text == '(') {
          _advance();
          final arguments = <_Expression>[];
          while (!_isPunctuation(')')) {
            arguments.add(_parseExpression());
            if (!_isPunctuation(')')) {
              _expectPunctuation(',');
            }
          }
          _advance();
          return _Call(token.text, arguments, token.line);
        }
        return _NameLiteral(token.text, token.line);
      case _TokenType.punctuation:
        switch (token.text) {
          case '[':
            _advance();
            final elements = <_Expression>[];
            while (!_isPunctuation(']')) {
              elements.add(_parseExpression());
              if (!_isPunctuation(']')) {
                _expectPunctuation(',');
              }
            }
            _advance();
            return _ListLiteral(elements, token.line);
          case '{':
            _advance();
            final entries = <(_Expression, _Expression)>[];
            while (!_isPunctuation('}')) {
              final _Expression key = _parseExpression();
              _expectPunctuation(':');
              final _Expression value = _parseExpression();
              entries.add((key, value));
              if (!_isPunctuation('}')) {
                _expectPunctuation(',');
              }
            }
            _advance();
            return _DictLiteral(entries, token.line);
          case '(':
            _advance();
            final _Expression inner = _parseExpression();
            _expectPunctuation(')');
            return inner;
        }
      case _TokenType.endOfFile:
        break;
    }
    throw DepsFormatException(
      'expected an expression but found $token',
      fileName: _fileName,
      line: token.line,
    );
  }

  bool _isPunctuation(String text) =>
      _current.type == _TokenType.punctuation && _current.text == text;

  _Token _advance() => _tokens[_index++];

  _Token _expect(_TokenType type, String description) {
    if (_current.type != type) {
      throw DepsFormatException(
        'expected $description but found $_current',
        fileName: _fileName,
        line: _current.line,
      );
    }
    return _advance();
  }

  void _expectPunctuation(String text) {
    if (!_isPunctuation(text)) {
      throw DepsFormatException(
        'expected "$text" but found $_current',
        fileName: _fileName,
        line: _current.line,
      );
    }
    _advance();
  }
}

// -----------------------------------------------------------------------------
// Evaluator
// -----------------------------------------------------------------------------

/// A string produced by `Str()`, which gclient exempts from formatting.
final class _ConstantString {
  const _ConstantString(this.value);

  final String value;
}

final class _Evaluator {
  _Evaluator({required this.fileName, required this.vars});

  final String fileName;

  /// The substitution dictionary, or `null` while evaluating `vars` itself.
  final Map<String, Object?>? vars;

  static final RegExp _fieldName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  Object? evaluate(_Expression expression) {
    final Object? value = _evaluate(expression);
    return value is _ConstantString ? value.value : value;
  }

  Object? _evaluate(_Expression expression) {
    switch (expression) {
      case _StringLiteral(:final String value, :final int line):
        return vars == null ? value : _format(value, line);
      case _NumberLiteral(:final int value):
        return value;
      case _NameLiteral(:final String name, :final int line):
        return switch (name) {
          'True' => true,
          'False' => false,
          'None' => null,
          _ => throw DepsFormatException('invalid name "$name"', fileName: fileName, line: line),
        };
      case _ListLiteral(:final List<_Expression> elements):
        return List<Object?>.unmodifiable(elements.map(evaluate));
      case _DictLiteral(:final List<(_Expression, _Expression)> entries, :final int line):
        final map = <String, Object?>{};
        for (final (_Expression keyExpression, _Expression valueExpression) in entries) {
          final Object? key = evaluate(keyExpression);
          if (key is! String) {
            throw DepsFormatException(
              'dictionary keys must be strings',
              fileName: fileName,
              line: keyExpression.line,
            );
          }
          if (map.containsKey(key)) {
            throw DepsFormatException(
              'duplicate key in dictionary: $key',
              fileName: fileName,
              line: line,
            );
          }
          map[key] = evaluate(valueExpression);
        }
        return Map<String, Object?>.unmodifiable(map);
      case _Call(:final String function, :final List<_Expression> arguments, :final int line):
        return _call(function, arguments, line);
      case _BinaryOperation(
        :final String operator,
        :final _Expression left,
        :final _Expression right,
        :final int line,
      ):
        final Object? l = evaluate(left);
        final Object? r = evaluate(right);
        if (operator == '+') {
          if (l is String && r is String) {
            return l + r;
          }
          if (l is List<Object?> && r is List<Object?>) {
            return List<Object?>.unmodifiable(<Object?>[...l, ...r]);
          }
          if (l is int && r is int) {
            return l + r;
          }
        } else if (operator == '%' && l is String) {
          return _percentFormat(l, r, line);
        }
        throw DepsFormatException(
          'unsupported operand types for $operator: '
          '${l.runtimeType} and ${r.runtimeType}',
          fileName: fileName,
          line: line,
        );
    }
  }

  Object? _call(String function, List<_Expression> arguments, int line) {
    if (function != 'Str' && function != 'Var') {
      throw DepsFormatException(
        'Str and Var are the only allowed functions',
        fileName: fileName,
        line: line,
      );
    }
    if (arguments.length != 1) {
      throw DepsFormatException(
        '$function takes exactly one argument',
        fileName: fileName,
        line: line,
      );
    }
    final _Expression argument = arguments.single;
    switch (function) {
      case 'Str':
        if (argument is! _StringLiteral) {
          throw DepsFormatException('Passed a non-string to Str()', fileName: fileName, line: line);
        }
        return _ConstantString(argument.value);
      default:
        final Object? name = evaluate(argument);
        if (name is! String) {
          throw DepsFormatException(
            "Var's argument must be a variable name",
            fileName: fileName,
            line: line,
          );
        }
        final Map<String, Object?>? vars = this.vars;
        if (vars == null) {
          return '{$name}';
        }
        if (vars.containsKey(name)) {
          final Object? value = vars[name];
          return value is _ConstantString ? value.value : value;
        }
        if (gclientBuiltinVars.contains(name)) {
          return '{$name}';
        }
        throw DepsFormatException(
          '$name was used as a variable, but was not declared in the vars dict',
          fileName: fileName,
          line: line,
        );
    }
  }

  /// Emulates `value.format(**vars)` for the `{name}` subset gclient uses.
  String _format(String value, int line) {
    final Map<String, Object?> vars = this.vars!;
    final result = StringBuffer();
    var i = 0;
    while (i < value.length) {
      final String c = value[i];
      if (c == '{') {
        if (i + 1 < value.length && value[i + 1] == '{') {
          result.write('{');
          i += 2;
          continue;
        }
        final int end = value.indexOf('}', i);
        if (end < 0) {
          throw DepsFormatException(
            "Single '{' encountered in format string",
            fileName: fileName,
            line: line,
          );
        }
        final String name = value.substring(i + 1, end);
        if (!_fieldName.hasMatch(name)) {
          throw DepsFormatException(
            'unsupported format field "{$name}"',
            fileName: fileName,
            line: line,
          );
        }
        if (vars.containsKey(name)) {
          result.write(_pythonString(vars[name]));
        } else if (gclientBuiltinVars.contains(name)) {
          result.write('{$name}');
        } else {
          throw DepsFormatException(
            '$name was used as a variable, but was not declared in the vars dict',
            fileName: fileName,
            line: line,
          );
        }
        i = end + 1;
      } else if (c == '}') {
        if (i + 1 < value.length && value[i + 1] == '}') {
          result.write('}');
          i += 2;
          continue;
        }
        throw DepsFormatException(
          "Single '}' encountered in format string",
          fileName: fileName,
          line: line,
        );
      } else {
        result.write(c);
        i++;
      }
    }
    return result.toString();
  }

  /// Emulates the `%s`-only subset of Python's `%` operator.
  String _percentFormat(String format, Object? arguments, int line) {
    final List<Object?> values = arguments is List<Object?> ? arguments : <Object?>[arguments];
    var next = 0;
    final result = StringBuffer();
    var i = 0;
    while (i < format.length) {
      final String c = format[i];
      if (c != '%') {
        result.write(c);
        i++;
        continue;
      }
      if (i + 1 >= format.length) {
        throw DepsFormatException('incomplete format', fileName: fileName, line: line);
      }
      final String spec = format[i + 1];
      if (spec == '%') {
        result.write('%');
      } else if (spec == 's') {
        if (next >= values.length) {
          throw DepsFormatException(
            'not enough arguments for format string',
            fileName: fileName,
            line: line,
          );
        }
        result.write(_pythonString(values[next++]));
      } else {
        throw DepsFormatException(
          'unsupported format specifier "%$spec"',
          fileName: fileName,
          line: line,
        );
      }
      i += 2;
    }
    return result.toString();
  }

  static String _pythonString(Object? value) => switch (value) {
    true => 'True',
    false => 'False',
    null => 'None',
    final _ConstantString s => s.value,
    _ => value.toString(),
  };
}
