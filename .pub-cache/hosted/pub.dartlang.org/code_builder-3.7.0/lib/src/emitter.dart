// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'allocator.dart';
import 'base.dart';
import 'specs/class.dart';
import 'specs/code.dart';
import 'specs/constructor.dart';
import 'specs/directive.dart';
import 'specs/enum.dart';
import 'specs/expression.dart';
import 'specs/extension.dart';
import 'specs/field.dart';
import 'specs/library.dart';
import 'specs/method.dart';
import 'specs/reference.dart';
import 'specs/type_function.dart';
import 'specs/type_reference.dart';
import 'visitors.dart';

/// Helper method improving on [StringSink.writeAll].
///
/// For every `Spec` in [elements], executing [visit].
///
/// If [elements] is at least 2 elements, inserts [separator] delimiting them.
StringSink visitAll<T>(
  Iterable<T> elements,
  StringSink output,
  void Function(T) visit, [
  String separator = ', ',
]) {
  // Basically, this whole method is an improvement on
  //   output.writeAll(specs.map((s) => s.accept(visitor));
  //
  // ... which would allocate more StringBuffer(s) for a one-time use.
  if (elements.isEmpty) {
    return output;
  }
  final iterator = elements.iterator..moveNext();
  visit(iterator.current);
  while (iterator.moveNext()) {
    output.write(separator);
    visit(iterator.current);
  }
  return output;
}

class DartEmitter extends Object
    with CodeEmitter, ExpressionEmitter
    implements SpecVisitor<StringSink> {
  @override
  final Allocator allocator;

  /// If directives should be ordered while emitting.
  ///
  /// Ordering rules follow the guidance in
  /// [Effective Dart](https://dart.dev/guides/language/effective-dart/style#ordering)
  /// and the
  /// [directives_ordering](https://dart-lang.github.io/linter/lints/directives_ordering.html)
  /// lint.
  final bool orderDirectives;

  /// If nullable types should be emitted with the nullable suffix ("?").
  ///
  /// Null safety syntax should only be enabled if the output will be used with
  /// a Dart language version which supports it.
  final bool _useNullSafetySyntax;

  /// Creates a new instance of [DartEmitter].
  ///
  /// May specify an [Allocator] to use for symbols, otherwise uses a no-op.
  DartEmitter(
      [this.allocator = Allocator.none,
      bool orderDirectives = false,
      bool useNullSafetySyntax = false])
      : orderDirectives = orderDirectives ?? false,
        _useNullSafetySyntax = useNullSafetySyntax ?? false;

  /// Creates a new instance of [DartEmitter] with simple automatic imports.
  factory DartEmitter.scoped(
          {bool orderDirectives = false, bool useNullSafetySyntax = false}) =>
      DartEmitter(
          Allocator.simplePrefixing(), orderDirectives, useNullSafetySyntax);

  static bool _isLambdaBody(Code code) =>
      code is ToCodeExpression && !code.isStatement;

  /// Whether the provided [method] is considered a lambda method.
  static bool _isLambdaMethod(Method method) =>
      method.lambda ?? _isLambdaBody(method.body);

  /// Whether the provided [constructor] is considered a lambda method.
  static bool _isLambdaConstructor(Constructor constructor) =>
      constructor.lambda ??
      constructor.factory && _isLambdaBody(constructor.body);

  @override
  StringSink visitAnnotation(Expression spec, [StringSink output]) {
    (output ??= StringBuffer()).write('@');
    spec.accept(this, output);
    output.write(' ');
    return output;
  }

  @override
  StringSink visitClass(Class spec, [StringSink output]) {
    output ??= StringBuffer();
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));
    if (spec.abstract) {
      output.write('abstract ');
    }
    output.write('class ${spec.name}');
    visitTypeParameters(spec.types.map((r) => r.type), output);
    if (spec.extend != null) {
      output.write(' extends ');
      spec.extend.type.accept(this, output);
    }
    if (spec.mixins.isNotEmpty) {
      output
        ..write(' with ')
        ..writeAll(
            spec.mixins.map<StringSink>((m) => m.type.accept(this)), ',');
    }
    if (spec.implements.isNotEmpty) {
      output
        ..write(' implements ')
        ..writeAll(
            spec.implements.map<StringSink>((m) => m.type.accept(this)), ',');
    }
    output.write(' {');
    spec.constructors.forEach((c) {
      visitConstructor(c, spec.name, output);
      output.writeln();
    });
    spec.fields.forEach((f) {
      visitField(f, output);
      output.writeln();
    });
    spec.methods.forEach((m) {
      visitMethod(m, output);
      if (_isLambdaMethod(m)) {
        output.write(';');
      }
      output.writeln();
    });
    output.writeln(' }');
    return output;
  }

  @override
  StringSink visitConstructor(Constructor spec, String clazz,
      [StringSink output]) {
    output ??= StringBuffer();
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));
    if (spec.external) {
      output.write('external ');
    }
    if (spec.constant) {
      output.write('const ');
    }
    if (spec.factory) {
      output.write('factory ');
    }
    output.write(clazz);
    if (spec.name != null) {
      output..write('.')..write(spec.name);
    }
    output.write('(');
    if (spec.requiredParameters.isNotEmpty) {
      var count = 0;
      for (final p in spec.requiredParameters) {
        count++;
        _visitParameter(p, output);
        if (spec.requiredParameters.length != count ||
            spec.optionalParameters.isNotEmpty) {
          output.write(', ');
        }
      }
    }
    if (spec.optionalParameters.isNotEmpty) {
      final named = spec.optionalParameters.any((p) => p.named);
      if (named) {
        output.write('{');
      } else {
        output.write('[');
      }
      var count = 0;
      for (final p in spec.optionalParameters) {
        count++;
        _visitParameter(p, output, optional: true, named: named);
        if (spec.optionalParameters.length != count) {
          output.write(', ');
        }
      }
      if (named) {
        output.write('}');
      } else {
        output.write(']');
      }
    }
    output.write(')');
    if (spec.initializers.isNotEmpty) {
      output.write(' : ');
      var count = 0;
      for (final initializer in spec.initializers) {
        count++;
        initializer.accept(this, output);
        if (count != spec.initializers.length) {
          output.write(', ');
        }
      }
    }
    if (spec.redirect != null) {
      output.write(' = ');
      spec.redirect.type.accept(this, output);
      output.write(';');
    } else if (spec.body != null) {
      if (_isLambdaConstructor(spec)) {
        output.write(' => ');
        spec.body.accept(this, output);
        output.write(';');
      } else {
        output.write(' { ');
        spec.body.accept(this, output);
        output.write(' }');
      }
    } else {
      output.write(';');
    }
    output.writeln();
    return output;
  }

  @override
  StringSink visitExtension(Extension spec, [StringSink output]) {
    output ??= StringBuffer();
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));

    output.write('extension');
    if (spec.name != null) {
      output.write(' ${spec.name}');
    }
    visitTypeParameters(spec.types.map((r) => r.type), output);
    if (spec.on != null) {
      output.write(' on ');
      spec.on.type.accept(this, output);
    }
    output.write(' {');
    spec.fields.forEach((f) {
      visitField(f, output);
      output.writeln();
    });
    spec.methods.forEach((m) {
      visitMethod(m, output);
      if (_isLambdaMethod(m)) {
        output.write(';');
      }
      output.writeln();
    });
    output.writeln(' }');
    return output;
  }

  @override
  StringSink visitDirective(Directive spec, [StringSink output]) {
    output ??= StringBuffer();
    switch (spec.type) {
      case DirectiveType.import:
        output.write('import ');
        break;
      case DirectiveType.export:
        output.write('export ');
        break;
      case DirectiveType.part:
        output.write('part ');
        break;
      case DirectiveType.partOf:
        output.write('part of ');
        break;
    }
    output.write("'${spec.url}'");
    if (spec.as != null) {
      if (spec.deferred) {
        output.write(' deferred ');
      }
      output.write(' as ${spec.as}');
    }
    if (spec.show.isNotEmpty) {
      output
        ..write(' show ')
        ..writeAll(spec.show, ', ');
    } else if (spec.hide.isNotEmpty) {
      output
        ..write(' hide ')
        ..writeAll(spec.hide, ', ');
    }
    output.write(';');
    return output;
  }

  @override
  StringSink visitField(Field spec, [StringSink output]) {
    output ??= StringBuffer();
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));
    if (spec.static) {
      output.write('static ');
    }
    switch (spec.modifier) {
      case FieldModifier.var$:
        if (spec.type == null) {
          output.write('var ');
        }
        break;
      case FieldModifier.final$:
        output.write('final ');
        break;
      case FieldModifier.constant:
        output.write('const ');
        break;
    }
    if (spec.type != null) {
      spec.type.type.accept(this, output);
      output.write(' ');
    }
    output.write(spec.name);
    if (spec.assignment != null) {
      output.write(' = ');
      startConstCode(spec.modifier == FieldModifier.constant, () {
        spec.assignment.accept(this, output);
      });
    }
    output.writeln(';');
    return output;
  }

  @override
  StringSink visitLibrary(Library spec, [StringSink output]) {
    output ??= StringBuffer();
    // Process the body first in order to prime the allocators.
    final body = StringBuffer();
    for (final spec in spec.body) {
      spec.accept(this, body);
      if (spec is Method && _isLambdaMethod(spec)) {
        body.write(';');
      }
    }

    final directives = <Directive>[...allocator.imports, ...spec.directives];

    if (orderDirectives) {
      directives.sort();
    }

    Directive previous;
    for (final directive in directives) {
      if (_newLineBetween(orderDirectives, previous, directive)) {
        // Note: dartfmt handles creating new lines between directives.
        // 2 lines are written here. The first one comes after the previous
        // directive `;`, the second is the empty line.
        output..writeln()..writeln();
      }
      directive.accept(this, output);
      previous = directive;
    }
    output.write(body);
    return output;
  }

  @override
  StringSink visitFunctionType(FunctionType spec, [StringSink output]) {
    output ??= StringBuffer();
    if (spec.returnType != null) {
      spec.returnType.accept(this, output);
      output.write(' ');
    }
    output.write('Function');
    if (spec.types.isNotEmpty) {
      output.write('<');
      visitAll<Reference>(spec.types, output, (spec) {
        spec.accept(this, output);
      });
      output.write('>');
    }
    output.write('(');
    visitAll<Reference>(spec.requiredParameters, output, (spec) {
      spec.accept(this, output);
    });
    if (spec.requiredParameters.isNotEmpty &&
        (spec.optionalParameters.isNotEmpty ||
            spec.namedParameters.isNotEmpty)) {
      output.write(', ');
    }
    if (spec.optionalParameters.isNotEmpty) {
      output.write('[');
      visitAll<Reference>(spec.optionalParameters, output, (spec) {
        spec.accept(this, output);
      });
      output.write(']');
    } else if (spec.namedParameters.isNotEmpty) {
      output.write('{');
      visitAll<String>(spec.namedParameters.keys, output, (name) {
        spec.namedParameters[name].accept(this, output);
        output..write(' ')..write(name);
      });
      output.write('}');
    }
    output.write(')');
    if (_useNullSafetySyntax && (spec.isNullable ?? false)) {
      output.write('?');
    }
    return output;
  }

  @override
  StringSink visitMethod(Method spec, [StringSink output]) {
    output ??= StringBuffer();
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));
    if (spec.external) {
      output.write('external ');
    }
    if (spec.static) {
      output.write('static ');
    }
    if (spec.returns != null) {
      spec.returns.accept(this, output);
      output.write(' ');
    }
    if (spec.type == MethodType.getter) {
      output..write('get ')..write(spec.name);
    } else {
      if (spec.type == MethodType.setter) {
        output.write('set ');
      }
      if (spec.name != null) {
        output.write(spec.name);
      }
      visitTypeParameters(spec.types.map((r) => r.type), output);
      output.write('(');
      if (spec.requiredParameters.isNotEmpty) {
        var count = 0;
        for (final p in spec.requiredParameters) {
          count++;
          _visitParameter(p, output);
          if (spec.requiredParameters.length != count ||
              spec.optionalParameters.isNotEmpty) {
            output.write(', ');
          }
        }
      }
      if (spec.optionalParameters.isNotEmpty) {
        final named = spec.optionalParameters.any((p) => p.named);
        if (named) {
          output.write('{');
        } else {
          output.write('[');
        }
        var count = 0;
        for (final p in spec.optionalParameters) {
          count++;
          _visitParameter(p, output, optional: true, named: named);
          if (spec.optionalParameters.length != count) {
            output.write(', ');
          }
        }
        if (named) {
          output.write('}');
        } else {
          output.write(']');
        }
      }
      output.write(')');
    }
    if (spec.body != null) {
      if (spec.modifier != null) {
        switch (spec.modifier) {
          case MethodModifier.async:
            output.write(' async ');
            break;
          case MethodModifier.asyncStar:
            output.write(' async* ');
            break;
          case MethodModifier.syncStar:
            output.write(' sync* ');
            break;
        }
      }
      if (_isLambdaMethod(spec)) {
        output.write(' => ');
      } else {
        output.write(' { ');
      }
      spec.body.accept(this, output);
      if (!_isLambdaMethod(spec)) {
        output.write(' } ');
      }
    } else {
      output.write(';');
    }
    return output;
  }

  // Expose as a first-class visit function only if needed.
  void _visitParameter(
    Parameter spec,
    StringSink output, {
    bool optional = false,
    bool named = false,
  }) {
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));
    // The `required` keyword must precede the `covariant` keyword.
    if (spec.required) {
      output.write('required ');
    }
    if (spec.covariant) {
      output.write('covariant ');
    }
    if (spec.type != null) {
      spec.type.type.accept(this, output);
      output.write(' ');
    }
    if (spec.toThis) {
      output.write('this.');
    }
    output.write(spec.name);
    if (optional && spec.defaultTo != null) {
      output.write(' = ');
      spec.defaultTo.accept(this, output);
    }
  }

  @override
  StringSink visitReference(Reference spec, [StringSink output]) =>
      (output ??= StringBuffer())..write(allocator.allocate(spec));

  @override
  StringSink visitSpec(Spec spec, [StringSink output]) =>
      spec.accept(this, output);

  @override
  StringSink visitType(TypeReference spec, [StringSink output]) {
    output ??= StringBuffer();
    // Intentionally not .accept to avoid stack overflow.
    visitReference(spec, output);
    if (spec.bound != null) {
      output.write(' extends ');
      spec.bound.type.accept(this, output);
    }
    visitTypeParameters(spec.types.map((r) => r.type), output);
    if (_useNullSafetySyntax && (spec.isNullable ?? false)) {
      output.write('?');
    }
    return output;
  }

  @override
  StringSink visitTypeParameters(Iterable<Reference> specs,
      [StringSink output]) {
    output ??= StringBuffer();
    if (specs.isNotEmpty) {
      output
        ..write('<')
        ..writeAll(specs.map<StringSink>((s) => s.accept(this)), ',')
        ..write('>');
    }
    return output;
  }

  @override
  StringSink visitEnum(Enum spec, [StringSink output]) {
    output ??= StringBuffer();
    spec.docs.forEach(output.writeln);
    spec.annotations.forEach((a) => visitAnnotation(a, output));
    output.writeln('enum ${spec.name} {');
    spec.values.forEach((v) {
      v.docs.forEach(output.writeln);
      v.annotations.forEach((a) => visitAnnotation(a, output));
      output.write(v.name);
      if (v != spec.values.last) {
        output.writeln(',');
      }
    });
    output.writeln('}');
    return output;
  }
}

/// Returns `true` if:
///
/// * [ordered] is `true`
/// * [a] is non-`null`
/// * If there should be an empty line before [b] if it's emitted after [a].
bool _newLineBetween(bool ordered, Directive a, Directive b) {
  if (!ordered) return false;
  if (a == null) return false;

  assert(b != null);

  // Put a line between imports and exports
  if (a.type != b.type) return true;

  // Within exports, don't put in extra blank lines
  if (a.type == DirectiveType.export) {
    assert(b.type == DirectiveType.export);
    return false;
  }

  // Return `true` if the schemes for [a] and [b] are different
  return !Uri.parse(a.url).isScheme(Uri.parse(b.url).scheme);
}
