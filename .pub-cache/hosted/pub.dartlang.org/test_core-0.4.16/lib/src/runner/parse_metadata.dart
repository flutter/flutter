// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:test_api/scaffolding.dart' // ignore: deprecated_member_use
    show
        Timeout;
import 'package:test_api/src/backend/metadata.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/platform_selector.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/util/identifier_regex.dart'; // ignore: implementation_imports

import '../util/dart.dart';
import '../util/pair.dart';

/// Parse the test metadata for the test file at [path] with [contents].
///
/// The [platformVariables] are the set of variables that are valid for platform
/// selectors in suite metadata, in addition to the built-in variables that are
/// allowed everywhere.
///
/// Throws an [AnalysisError] if parsing fails or a [FormatException] if the
/// test annotations are incorrect.
Metadata parseMetadata(
        String path, String contents, Set<String> platformVariables) =>
    _Parser(path, contents, platformVariables).parse();

/// A parser for test suite metadata.
class _Parser {
  /// The path to the test suite.
  final String _path;

  /// The set of variables that are valid for platform selectors, in addition to
  /// the built-in variables that are allowed everywhere.
  final Set<String> _platformVariables;

  /// All annotations at the top of the file.
  late final List<Annotation> _annotations;

  /// All prefixes defined by imports in this file.
  late final Set<String> _prefixes;

  /// The actual contents of the file.
  final String _contents;

  /// The language version override comment if one was present, otherwise null.
  String? _languageVersionComment;

  _Parser(this._path, this._contents, this._platformVariables) {
    var result =
        parseString(content: _contents, path: _path, throwIfDiagnostics: false);
    var directives = result.unit.directives;
    _annotations = directives.isEmpty ? [] : directives.first.metadata;
    _languageVersionComment = result.unit.languageVersionToken?.value();

    // We explicitly *don't* just look for "package:test" imports here,
    // because it could be re-exported from another library.
    _prefixes = directives
        .map((directive) {
          if (directive is ImportDirective) {
            return directive.prefix?.name;
          } else {
            return null;
          }
        })
        .whereType<String>()
        .toSet();
  }

  /// Parses the metadata.
  Metadata parse() {
    Timeout? timeout;
    PlatformSelector? testOn;
    Object? /*String|bool*/ skip;
    Map<PlatformSelector, Metadata>? onPlatform;
    Set<String>? tags;
    int? retry;

    for (var annotation in _annotations) {
      var pair =
          _resolveConstructor(annotation.name, annotation.constructorName);
      var name = pair.first;
      var constructorName = pair.last;

      if (name == 'TestOn') {
        _assertSingle(testOn, 'TestOn', annotation);
        testOn = _parseTestOn(annotation);
      } else if (name == 'Timeout') {
        _assertSingle(timeout, 'Timeout', annotation);
        timeout = _parseTimeout(annotation, constructorName);
      } else if (name == 'Skip') {
        _assertSingle(skip, 'Skip', annotation);
        skip = _parseSkip(annotation);
      } else if (name == 'OnPlatform') {
        _assertSingle(onPlatform, 'OnPlatform', annotation);
        onPlatform = _parseOnPlatform(annotation);
      } else if (name == 'Tags') {
        _assertSingle(tags, 'Tags', annotation);
        tags = _parseTags(annotation);
      } else if (name == 'Retry') {
        retry = _parseRetry(annotation);
      }
    }

    return Metadata(
        testOn: testOn,
        timeout: timeout,
        skip: skip == null ? null : true,
        skipReason: skip is String ? skip : null,
        onPlatform: onPlatform,
        tags: tags,
        retry: retry,
        languageVersionComment: _languageVersionComment);
  }

  /// Parses a `@TestOn` annotation.
  ///
  /// [annotation] is the annotation.
  PlatformSelector _parseTestOn(Annotation annotation) =>
      _parsePlatformSelector(annotation.arguments!.arguments.first);

  /// Parses an [expression] that should contain a string representing a
  /// [PlatformSelector].
  PlatformSelector _parsePlatformSelector(Expression expression) {
    var literal = _parseString(expression);
    return _contextualize(
        literal,
        () => PlatformSelector.parse(literal.stringValue!)
          ..validate(_platformVariables));
  }

  /// Parses a `@Retry` annotation.
  ///
  /// [annotation] is the annotation.
  int _parseRetry(Annotation annotation) =>
      _parseInt(annotation.arguments!.arguments.first);

  /// Parses a `@Timeout` annotation.
  ///
  /// [annotation] is the annotation. [constructorName] is the name of the named
  /// constructor for the annotation, if any.
  Timeout _parseTimeout(Annotation annotation, String? constructorName) {
    if (constructorName == 'none') {
      return Timeout.none;
    }

    var args = annotation.arguments!.arguments;
    if (constructorName == null) return Timeout(_parseDuration(args.first));
    return Timeout.factor(_parseNum(args.first));
  }

  /// Parses a `Timeout` constructor.
  Timeout _parseTimeoutConstructor(Expression constructor) {
    var name = _findConstructorName(constructor, 'Timeout');
    var arguments = _parseArguments(constructor);
    if (name == null) return Timeout(_parseDuration(arguments.first));
    if (name == 'factor') return Timeout.factor(_parseNum(arguments.first));
    throw SourceSpanFormatException('Invalid timeout', _spanFor(constructor));
  }

  /// Parses a `@Skip` annotation.
  ///
  /// [annotation] is the annotation.
  ///
  /// Returns either `true` or a reason string.
  dynamic _parseSkip(Annotation annotation) {
    var args = annotation.arguments!.arguments;
    return args.isEmpty ? true : _parseString(args.first).stringValue;
  }

  /// Parses a `Skip` constructor.
  ///
  /// Returns either `true` or a reason string.
  dynamic _parseSkipConstructor(Expression constructor) {
    _findConstructorName(constructor, 'Skip');
    var arguments = _parseArguments(constructor);
    return arguments.isEmpty ? true : _parseString(arguments.first).stringValue;
  }

  /// Parses a `@Tags` annotation.
  ///
  /// [annotation] is the annotation.
  Set<String> _parseTags(Annotation annotation) {
    return _parseList(annotation.arguments!.arguments.first)
        .map((tagExpression) {
      var name = _parseString(tagExpression).stringValue!;
      if (name.contains(anchoredHyphenatedIdentifier)) return name;

      throw SourceSpanFormatException(
          'Invalid tag name. Tags must be (optionally hyphenated) Dart '
          'identifiers.',
          _spanFor(tagExpression));
    }).toSet();
  }

  /// Parses an `@OnPlatform` annotation.
  ///
  /// [annotation] is the annotation.
  Map<PlatformSelector, Metadata> _parseOnPlatform(Annotation annotation) {
    return _parseMap(annotation.arguments!.arguments.first, key: (key) {
      return _parsePlatformSelector(key);
    }, value: (value) {
      var expressions = <AstNode>[];
      if (value is ListLiteral) {
        expressions = _parseList(value);
      } else if (value is InstanceCreationExpression ||
          value is PrefixedIdentifier ||
          value is MethodInvocation) {
        expressions = [value];
      } else {
        throw SourceSpanFormatException(
            'Expected a Timeout, Skip, or List of those.', _spanFor(value));
      }

      Timeout? timeout;
      Object? skip;
      for (var expression in expressions) {
        if (expression is InstanceCreationExpression) {
          var className = _resolveConstructor(
                  expression.constructorName.type.name,
                  expression.constructorName.name)
              .first;

          if (className == 'Timeout') {
            _assertSingle(timeout, 'Timeout', expression);
            timeout = _parseTimeoutConstructor(expression);
            continue;
          } else if (className == 'Skip') {
            _assertSingle(skip, 'Skip', expression);
            skip = _parseSkipConstructor(expression);
            continue;
          }
        } else if (expression is PrefixedIdentifier &&
            expression.prefix.name == 'Timeout') {
          if (expression.identifier.name != 'none') {
            throw SourceSpanFormatException(
                'Undefined value.', _spanFor(expression));
          }

          _assertSingle(timeout, 'Timeout', expression);
          timeout = Timeout.none;
          continue;
        } else if (expression is MethodInvocation) {
          var className =
              _typeNameFromMethodInvocation(expression, ['Timeout', 'Skip']);
          if (className == 'Timeout') {
            _assertSingle(timeout, 'Timeout', expression);
            timeout = _parseTimeoutConstructor(expression);
            continue;
          } else if (className == 'Skip') {
            _assertSingle(skip, 'Skip', expression);
            skip = _parseSkipConstructor(expression);
            continue;
          }
        }

        throw SourceSpanFormatException(
            'Expected a Timeout or Skip.', _spanFor(expression));
      }

      return Metadata.parse(timeout: timeout, skip: skip);
    });
  }

  /// Parses a `const Duration` expression.
  Duration _parseDuration(Expression expression) {
    _findConstructorName(expression, 'Duration');

    var arguments = _parseArguments(expression);
    var values = _parseNamedArguments(arguments)
        .map((key, value) => MapEntry(key, _parseInt(value)));

    return Duration(
        days: values['days'] ?? 0,
        hours: values['hours'] ?? 0,
        minutes: values['minutes'] ?? 0,
        seconds: values['seconds'] ?? 0,
        milliseconds: values['milliseconds'] ?? 0,
        microseconds: values['microseconds'] ?? 0);
  }

  Map<String, Expression> _parseNamedArguments(
          NodeList<Expression> arguments) =>
      {
        for (var a in arguments.whereType<NamedExpression>())
          a.name.label.name: a.expression
      };

  /// Asserts that [existing] is null.
  ///
  /// [name] is the name of the annotation and [node] is its location, used for
  /// error reporting.
  void _assertSingle(Object? existing, String name, AstNode node) {
    if (existing == null) return;
    throw SourceSpanFormatException(
        'Only a single $name may be used.', _spanFor(node));
  }

  NodeList<Expression> _parseArguments(Expression expression) {
    if (expression is InstanceCreationExpression) {
      return expression.argumentList.arguments;
    }
    if (expression is MethodInvocation) {
      return expression.argumentList.arguments;
    }
    throw SourceSpanFormatException(
        'Expected an instantiation', _spanFor(expression));
  }

  /// Resolves a constructor name from its type [identifier] and its
  /// [constructorName].
  ///
  /// Since the parsed file isn't fully resolved, this is necessary to
  /// disambiguate between prefixed names and named constructors.
  Pair<String, String?> _resolveConstructor(
      Identifier identifier, SimpleIdentifier? constructorName) {
    // The syntax is ambiguous between named constructors and prefixed
    // annotations, so we need to resolve that ambiguity using the known
    // prefixes. The analyzer parses "new x.y()" as prefix "x", annotation "y",
    // and named constructor null. It parses "new x.y.z()" as prefix "x",
    // annotation "y", and named constructor "z".
    String className;
    String? namedConstructor;
    if (identifier is PrefixedIdentifier &&
        !_prefixes.contains(identifier.prefix.name) &&
        constructorName == null) {
      className = identifier.prefix.name;
      namedConstructor = identifier.identifier.name;
    } else {
      className = identifier is PrefixedIdentifier
          ? identifier.identifier.name
          : identifier.name;
      if (constructorName != null) namedConstructor = constructorName.name;
    }
    return Pair(className, namedConstructor);
  }

  /// Parses a constructor invocation for [className].
  ///
  /// Returns the name of the named constructor used, or null if the default
  /// constructor is used.
  /// If [expression] is not an instantiation of a [className] throws.
  String? _findConstructorName(Expression expression, String className) {
    if (expression is InstanceCreationExpression) {
      return _findConstructornameFromInstantiation(expression, className);
    }
    if (expression is MethodInvocation) {
      return _findConstructorNameFromMethod(expression, className);
    }
    throw SourceSpanFormatException(
        'Expected a $className.', _spanFor(expression));
  }

  String? _findConstructornameFromInstantiation(
      InstanceCreationExpression constructor, String className) {
    var pair = _resolveConstructor(constructor.constructorName.type.name,
        constructor.constructorName.name);
    var actualClassName = pair.first;
    var constructorName = pair.last;

    if (actualClassName != className) {
      throw SourceSpanFormatException(
          'Expected a $className.', _spanFor(constructor));
    }

    return constructorName;
  }

  String? _findConstructorNameFromMethod(
      MethodInvocation constructor, String className) {
    var target = constructor.target;
    if (target != null) {
      // target could be an import prefix or a different class. Assume that
      // named constructor on a different class won't match the class name we
      // are looking for.
      // Example: `test.Timeout()`
      if (constructor.methodName.name == className) return null;
      // target is an optionally prefixed class, method is named constructor
      // Examples: `Timeout.factor(2)`, `test.Timeout.factor(2)`
      String? parsedName;
      if (target is SimpleIdentifier) parsedName = target.name;
      if (target is PrefixedIdentifier) parsedName = target.identifier.name;
      if (parsedName != className) {
        throw SourceSpanFormatException(
            'Expected a $className.', _spanFor(constructor));
      }
      return constructor.methodName.name;
    }
    // No target, must be an unnamed constructor
    // Example `Timeout()`
    if (constructor.methodName.name != className) {
      throw SourceSpanFormatException(
          'Expected a $className.', _spanFor(constructor));
    }
    return null;
  }

  /// Returns a type from [candidates] that _may_ be a type instantiated by
  /// [constructor].
  ///
  /// This can be fooled - for instance the invocation `foo.Bar()` may look like
  /// a prefixed instantiation of a `Bar` even though it is a named constructor
  /// instantiation of a `foo`, or a method invocation on a variable `foo`, or
  /// ...
  ///
  /// Similarly `Baz.another` may look like the named constructor invocation of
  /// a `Baz`even though it is a prefixed instantiation of an `another`, or a
  /// method invocation on a variable `Baz`, or ...
  String? _typeNameFromMethodInvocation(
      MethodInvocation constructor, List<String> candidates) {
    var methodName = constructor.methodName.name;
    // Examples: `Timeout()`, `test.Timeout()`
    if (candidates.contains(methodName)) return methodName;
    var target = constructor.target;
    // Example: `SomeOtherClass()`
    if (target == null) return null;
    if (target is SimpleIdentifier) {
      // Example: `Timeout.factor()`
      if (candidates.contains(target.name)) return target.name;
    }
    if (target is PrefixedIdentifier) {
      // Looks  like `some_prefix.SomeTarget.someMethod` - "SomeTarget" is the
      // only potential type name.
      // Example: `test.Timeout.factor()`
      if (candidates.contains(target.identifier.name)) {
        return target.identifier.name;
      }
    }
    return null;
  }

  /// Parses a Map literal.
  ///
  /// By default, returns [Expression] keys and values. These can be overridden
  /// with the [key] and [value] parameters.
  Map<K, V> _parseMap<K, V>(Expression expression,
      {K Function(Expression)? key, V Function(Expression)? value}) {
    key ??= (expression) => expression as K;
    value ??= (expression) => expression as V;

    if (expression is! SetOrMapLiteral) {
      throw SourceSpanFormatException('Expected a Map.', _spanFor(expression));
    }

    var map = <K, V>{};
    for (var element in expression.elements) {
      if (element is MapLiteralEntry) {
        map[key(element.key)] = value(element.value);
      } else {
        throw SourceSpanFormatException(
            'Expected a map entry.', _spanFor(element));
      }
    }
    return map;
  }

  /// Parses a List literal.
  List<Expression> _parseList(Expression expression) {
    if (expression is! ListLiteral) {
      throw SourceSpanFormatException('Expected a List.', _spanFor(expression));
    }

    var list = expression;

    return list.elements.map((e) {
      if (e is! Expression) {
        throw SourceSpanFormatException(
            'Expected only literal elements.', _spanFor(e));
      }
      return e;
    }).toList();
  }

  /// Parses a constant number literal.
  num _parseNum(Expression expression) {
    if (expression is IntegerLiteral && expression.value != null) {
      return expression.value!;
    }
    if (expression is DoubleLiteral) return expression.value;
    throw SourceSpanFormatException('Expected a number.', _spanFor(expression));
  }

  /// Parses a constant int literal.
  int _parseInt(Expression expression) {
    if (expression is IntegerLiteral && expression.value != null) {
      return expression.value!;
    }
    throw SourceSpanFormatException(
        'Expected an integer.', _spanFor(expression));
  }

  /// Parses a constant String literal.
  StringLiteral _parseString(Expression expression) {
    if (expression is StringLiteral && expression.stringValue != null) {
      return expression;
    }
    throw SourceSpanFormatException(
        'Expected a String literal.', _spanFor(expression));
  }

  /// Creates a [SourceSpan] for [node].
  SourceSpan _spanFor(AstNode node) {
    // Load a SourceFile from scratch here since we're only ever going to emit
    // one error per file anyway.
    return SourceFile.fromString(_contents, url: p.toUri(_path))
        .span(node.offset, node.end);
  }

  /// Runs [fn] and contextualizes any [SourceSpanFormatException]s that occur
  /// in it relative to [literal].
  T _contextualize<T>(StringLiteral literal, T Function() fn) {
    try {
      return fn();
    } on SourceSpanFormatException catch (error) {
      var file = SourceFile.fromString(_contents, url: p.toUri(_path));
      var span = contextualizeSpan(error.span!, literal, file);
      if (span == null) rethrow;
      throw SourceSpanFormatException(error.message, span);
    }
  }
}
