// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to generate Java source code. See [JavaGenerator].
library src_gen_java;

import 'dart:io';

import 'package:path/path.dart';

import '../common/src_gen_common.dart';

/// The maximum length for javadoc comments.
int colBoundary = 100;

/// The header for every generated file.
String? fileHeader;

String classNameFor(String typeName) {
  // Convert ElementList<Foo> param declarations to List<Foo> declarations.
  if (typeName.startsWith('ElementList<')) {
    return typeName.substring('Element'.length);
  }

  var index = typeName.lastIndexOf('.');
  typeName = index > 0 ? typeName.substring(index + 1) : typeName;
  if (typeName.startsWith('_')) typeName = typeName.substring(1);
  return typeName;
}

String pkgNameFor(String typeName) {
  var index = typeName.lastIndexOf('.');
  return index > 0 ? typeName.substring(0, index) : '';
}

typedef WriteStatements = void Function(StatementWriter writer);
typedef WriteType = void Function(TypeWriter writer);

/// [JavaGenerator] generates java source files, one per Java type.
/// Typical usage:
///
///    var generator = new JavaGenerator('/path/to/java/src');
///    generator.writeType('some.package.Foo', (TypeWriter) writer) {
///      ...
///    });
///    ...
///
class JavaGenerator {
  /// The java source directory into which files are generated.
  final String srcDirPath;

  Set<String> _generatedPaths = Set();

  JavaGenerator(this.srcDirPath);

  Iterable<String> get allWrittenFiles => _generatedPaths;

  /// Generate a Java class/interface in the given package
  void writeType(String typeName, scriptLocation, WriteType write) {
    var classWriter = TypeWriter(typeName, scriptLocation);
    write(classWriter);
    var pkgDirPath = join(srcDirPath, joinAll(pkgNameFor(typeName).split('.')));
    var pkgDir = Directory(pkgDirPath);
    if (!pkgDir.existsSync()) pkgDir.createSync(recursive: true);
    var classFilePath = join(pkgDirPath, '${classNameFor(typeName)}.java');
    var classFile = File(classFilePath);
    _generatedPaths.add(classFilePath);
    classFile.writeAsStringSync(classWriter.toSource());
  }
}

class JavaMethodArg {
  final String? name;
  final String? typeName;

  JavaMethodArg(this.name, this.typeName);
}

class StatementWriter {
  final TypeWriter typeWriter;
  final StringBuffer _content = StringBuffer();

  StatementWriter(this.typeWriter);

  void addImport(String typeName) {
    typeWriter.addImport(typeName);
  }

  void addLine(String line) {
    _content.writeln('    $line');
  }

  String toSource() => _content.toString();
}

/// [TypeWriter] describes a Java type to be generated.
/// Typical usage:
///
///     writer.addImport('package.one.Bar');
///     writer.addImport('package.two.*');
///     writer.superclassName = 'package.three.Blat';
///     writer.addMethod('foo', [
///       new JavaMethodArg('arg1', 'LocalType'),
///       new JavaMethodArg('arg2', 'java.util.List'),
///     ], (StatementWriter writer) {
///       ...
///     });
///
/// The [toSource()] method generates the source,
/// but need not be called if used in conjunction with
/// [JavaGenerator].
class TypeWriter {
  final String pkgName;
  final String className;
  bool isInterface = false;
  bool isEnum = false;
  String? javadoc;
  String modifiers = 'public';
  final Set<String> _imports = Set<String>();
  String? superclassName;
  List<String> interfaceNames = <String>[];
  final StringBuffer _content = StringBuffer();
  final List<String> _fields = <String>[];
  final Map<String, String> _methods = Map<String, String>();
  final String scriptLocation;

  TypeWriter(String typeName, scriptLocation)
      : this.pkgName = pkgNameFor(typeName),
        this.className = classNameFor(typeName),
        this.scriptLocation = scriptLocation;

  String get kind {
    if (isInterface) return 'interface';
    if (isEnum) return 'enum';
    return 'class';
  }

  void addConstructor(Iterable<JavaMethodArg> args, WriteStatements write,
      {String? javadoc, String modifiers = 'public'}) {
    _content.writeln();
    if (javadoc != null && javadoc.isNotEmpty) {
      _content.writeln('  /**');
      wrap(javadoc.trim(), colBoundary - 6)
          .split('\n')
          .forEach((line) => _content.writeln('   * $line'));
      _content.writeln('   */');
    }
    _content.write('  $modifiers $className(');
    _content.write(
        args.map((a) => '${classNameFor(a.typeName!)} ${a.name}').join(', '));
    _content.write(')');
    _content.writeln(' {');
    StatementWriter writer = StatementWriter(this);
    write(writer);
    _content.write(writer.toSource());
    _content.writeln('  }');
  }

  void addEnumValue(
    String? name, {
    String? javadoc,
    bool isLast = false,
  }) {
    _content.writeln();
    if (javadoc != null && javadoc.isNotEmpty) {
      _content.writeln('  /**');
      wrap(javadoc.trim(), colBoundary - 6)
          .split('\n')
          .forEach((line) => _content.writeln('   * $line'));
      _content.writeln('   */');
    }
    _content.write('  $name');
    if (!isLast) {
      _content.writeln(',');
    } else {
      _content.writeln();
    }
  }

  void addField(String name, String typeName,
      {String modifiers = 'public', String? value, String? javadoc}) {
    var fieldDecl = StringBuffer();
    if (javadoc != null && javadoc.isNotEmpty) {
      fieldDecl.writeln('  /**');
      wrap(javadoc.trim(), colBoundary - 6)
          .split('\n')
          .forEach((line) => fieldDecl.writeln('   * $line'));
      fieldDecl.writeln('   */');
    }
    fieldDecl.write('  ');
    if (modifiers.isNotEmpty) {
      fieldDecl.write('$modifiers ');
    }
    fieldDecl.write('$typeName $name');
    if (value != null && value.isNotEmpty) {
      fieldDecl.write(' = $value');
    }
    fieldDecl.writeln(';');
    _fields.add(fieldDecl.toString());
  }

  void addImport(String? typeName) {
    if (typeName == null || typeName.isEmpty) return;
    var pkgName = pkgNameFor(typeName);
    if (pkgName.isNotEmpty && pkgName != this.pkgName) {
      _imports.add(typeName);
    }
  }

  void addMethod(
    String name,
    Iterable<JavaMethodArg> args,
    WriteStatements? write, {
    String? javadoc,
    String? modifiers = 'public',
    String? returnType = 'void',
    bool isOverride = false,
    bool isDeprecated = false,
  }) {
    var methodDecl = StringBuffer();
    if (javadoc != null && javadoc.isNotEmpty) {
      methodDecl.writeln('  /**');
      wrap(javadoc.trim(), colBoundary - 6)
          .split('\n')
          .forEach((line) => methodDecl.writeln('   * $line'.trimRight()));
      methodDecl.writeln('   */');
    }
    if (isDeprecated) {
      methodDecl.writeln('  @Deprecated');
    }
    if (isOverride) {
      methodDecl.writeln('  @Override');
    }
    methodDecl.write('  ');
    if (modifiers != null && modifiers.isNotEmpty) {
      if (!isInterface || modifiers != 'public') {
        methodDecl.write('$modifiers ');
      }
    }
    methodDecl.write('$returnType $name(');
    methodDecl.write(args
        .map(
            (JavaMethodArg arg) => '${classNameFor(arg.typeName!)} ${arg.name}')
        .join(', '));
    methodDecl.write(')');
    if (write != null) {
      methodDecl.writeln(' {');
      StatementWriter writer = StatementWriter(this);
      write(writer);
      methodDecl.write(writer.toSource());
      methodDecl.writeln('  }');
    } else {
      methodDecl.writeln(';');
    }
    String key = (modifiers != null && modifiers.contains('public'))
        ? '1 $name('
        : '2 $name(';
    key = args.fold(key, (String k, JavaMethodArg a) => '$k${a.typeName},');
    _methods[key] = methodDecl.toString();
  }

  String toSource() {
    var buffer = StringBuffer();
    if (fileHeader != null) buffer.write(fileHeader);
    buffer.writeln('package $pkgName;');
    buffer.writeln();
    buffer.writeln(
        '// This file is generated by the script: ${scriptLocation} in dart-lang/sdk.');
    buffer.writeln();
    addImport(superclassName);
    interfaceNames.forEach((t) => addImport(t));
    if (_imports.isNotEmpty) {
      var sorted = _imports.toList()..sort();
      for (String typeName in sorted) {
        buffer.writeln('import $typeName;');
      }
      buffer.writeln();
    }
    if (javadoc != null && javadoc!.isNotEmpty) {
      buffer.writeln('/**');
      wrap(javadoc!.trim(), colBoundary - 4)
          .split('\n')
          .forEach((line) => buffer.writeln(' * $line'));
      buffer.writeln(' */');
    }

    buffer.writeln('@SuppressWarnings({"WeakerAccess", "unused"})');

    buffer.write('$modifiers $kind $className');
    if (superclassName != null) {
      buffer.write(' extends ${classNameFor(superclassName!)}');
    }
    if (interfaceNames.isNotEmpty) {
      var classNames = interfaceNames.map((t) => classNameFor(t));
      buffer.write(
          ' ${isInterface ? 'extends' : 'implements'} ${classNames.join(', ')}');
    }
    buffer.writeln(' {');
    buffer.write(_content.toString());
    _fields.forEach((f) {
      buffer.writeln();
      buffer.write(f);
    });
    _methods.keys.toList()
      ..sort()
      ..forEach((String methodName) {
        buffer.writeln();
        buffer.write(_methods[methodName]);
      });
    buffer.writeln('}');
    return buffer.toString();
  }
}
