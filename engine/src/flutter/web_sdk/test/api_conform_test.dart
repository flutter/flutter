// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analyzer.dart';

// Ignore members defined on Object.
const Set<String> _kObjectMembers = <String>{
  '==',
  'toString',
  'hashCode',
};

void main() {
  // These files just contain imports to the part files;
  final CompilationUnit uiUnit = parseDartFile('lib/ui/ui.dart',
      parseFunctionBodies: false, suppressErrors: false);
  final CompilationUnit webUnit = parseDartFile('lib/web_ui/lib/ui.dart',
      parseFunctionBodies: false, suppressErrors: false);
  final Map<String, ClassDeclaration> uiClasses = <String, ClassDeclaration>{};
  final Map<String, ClassDeclaration> webClasses = <String, ClassDeclaration>{};

  // Gather all public classes from each library. For now we are skiping
  // other top level members.
  _collectPublicClasses(uiUnit, uiClasses, 'lib/ui/');
  _collectPublicClasses(webUnit, webClasses, 'lib/web_ui/lib/');

  if (uiClasses.isEmpty || webClasses.isEmpty) {
    print('Warning: did not resolve any classes.');
  }

  bool failed = false;
  print('Checking ${uiClasses.length} public classes.');
  for (String className in uiClasses.keys) {
    final ClassDeclaration uiClass = uiClasses[className];
    final ClassDeclaration webClass = webClasses[className];
    // If the web class is missing there isn't much left to do here. Print a
    // warning and move along.
    if (webClass == null) {
      failed = true;
      print('Warning: lib/ui/ui.dart contained public class $className, but '
          'this was missing from lib/web_ui/ui.dart.');
      continue;
    }
    // Next will check that the public methods exposed in each library are
    // identical.
    final Map<String, MethodDeclaration> uiMethods =
        <String, MethodDeclaration>{};
    final Map<String, MethodDeclaration> webMethods =
        <String, MethodDeclaration>{};
    final Map<String, ConstructorDeclaration> uiConstructors =
        <String, ConstructorDeclaration>{};
    final Map<String, ConstructorDeclaration> webConstructors =
        <String, ConstructorDeclaration>{};
    _collectPublicMethods(uiClass, uiMethods);
    _collectPublicMethods(webClass, webMethods);
    _collectPublicConstructors(uiClass, uiConstructors);
    _collectPublicConstructors(webClass, webConstructors);

    for (String name in uiConstructors.keys) {
      final ConstructorDeclaration uiConstructor = uiConstructors[name];
      final ConstructorDeclaration webConstructor = webConstructors[name];
      if (webConstructor == null) {
        failed = true;
        print(
          'Warning: lib/ui/ui.dart $className.$name is missing from lib/web_ui/ui.dart.',
        );
        continue;
      }

      if (uiConstructor.parameters.parameters.length !=
          webConstructor.parameters.parameters.length) {
        failed = true;
        print(
            'Warning: lib/ui/ui.dart $className.$name has a different parameter '
            'length than in lib/web_ui/ui.dart.');
      }

      for (int i = 0;
          i < uiConstructor.parameters.parameters.length &&
              i < uiConstructor.parameters.parameters.length;
          i++) {
        // Technically you could re-order named parameters and still be valid,
        // but we enforce that they are identical.
        for (int i = 0;
            i < uiConstructor.parameters.parameters.length &&
                i < webConstructor.parameters.parameters.length;
            i++) {
          final FormalParameter uiParam =
              uiConstructor.parameters.parameters[i];
          final FormalParameter webParam =
              webConstructor.parameters.parameters[i];
          if (webParam.identifier.name != uiParam.identifier.name) {
            failed = true;
            print('Warning: lib/ui/ui.dart $className.$name parameter $i'
                ' ${uiParam.identifier.name} has a different name in lib/web_ui/ui.dart.');
          }
          if (uiParam.isPositional != webParam.isPositional) {
            failed = true;
            print('Warning: lib/ui/ui.dart $className.$name parameter $i'
                '${uiParam.identifier.name} is positional, but not in lib/web_ui/ui.dart.');
          }
          if (uiParam.isNamed != webParam.isNamed) {
            failed = true;
            print('Warning: lib/ui/ui.dart $className.$name parameter $i'
                '${uiParam.identifier.name} is named, but not in lib/web_ui/ui.dart.');
          }
        }
      }
    }

    for (String methodName in uiMethods.keys) {
      if (_kObjectMembers.contains(methodName)) {
        continue;
      }
      final MethodDeclaration uiMethod = uiMethods[methodName];
      final MethodDeclaration webMethod = webMethods[methodName];
      if (webMethod == null) {
        failed = true;
        print(
          'Warning: lib/ui/ui.dart $className.$methodName is missing from lib/web_ui/ui.dart.',
        );
        continue;
      }
      if (uiMethod.parameters == null || webMethod.parameters == null) {
        continue;
      }
      if (uiMethod.parameters.parameters.length !=
          webMethod.parameters.parameters.length) {
        failed = true;
        print(
            'Warning: lib/ui/ui.dart $className.$methodName has a different parameter '
            'length than in lib/web_ui/ui.dart.');
      }
      // Technically you could re-order named parameters and still be valid,
      // but we enforce that they are identical.
      for (int i = 0;
          i < uiMethod.parameters.parameters.length &&
              i < webMethod.parameters.parameters.length;
          i++) {
        final FormalParameter uiParam = uiMethod.parameters.parameters[i];
        final FormalParameter webParam = webMethod.parameters.parameters[i];
        if (webParam.identifier.name != uiParam.identifier.name) {
          failed = true;
          print('Warning: lib/ui/ui.dart $className.$methodName parameter $i'
              ' ${uiParam.identifier.name} has a different name in lib/web_ui/ui.dart.');
        }
        if (uiParam.isPositional != webParam.isPositional) {
          failed = true;
          print('Warning: lib/ui/ui.dart $className.$methodName parameter $i'
              '${uiParam.identifier.name} is positional, but not in lib/web_ui/ui.dart.');
        }
        if (uiParam.isNamed != webParam.isNamed) {
          failed = true;
          print('Warning: lib/ui/ui.dart $className.$methodName parameter $i'
              '${uiParam.identifier.name} is named, but not in lib/web_ui/ui.dart.');
        }
      }
      // check return type.
      if (uiMethod.returnType?.toString() != webMethod.returnType?.toString()) {
        // allow dynamic in web implementation.
        if (webMethod.returnType?.toString() != 'dynamic') {
          failed = true;
          print('Warning: lib/ui/ui.dart $className.$methodName return type'
              '${uiMethod.returnType?.toString()} is not the same as in lib/web_ui/ui.dart.');
        }
      }
    }
  }
  if (failed) {
    print('Failure!');
    exit(1);
  }
  print('Success!');
  exit(0);
}

// Collects all public classes defined by the part files of [unit].
void _collectPublicClasses(CompilationUnit unit,
    Map<String, ClassDeclaration> destination, String root) {
  for (Directive directive in unit.directives) {
    if (directive is! PartDirective) {
      continue;
    }
    final PartDirective partDirective = directive;
    final String literalUri = partDirective.uri.toString();
    final CompilationUnit subUnit = parseDartFile(
      '$root${literalUri.substring(1, literalUri.length - 1)}',
      parseFunctionBodies: false,
      suppressErrors: false,
    );
    for (CompilationUnitMember member in subUnit.declarations) {
      if (member is! ClassDeclaration) {
        continue;
      }
      final ClassDeclaration classDeclaration = member;
      if (classDeclaration.name.name.startsWith('_')) {
        continue;
      }
      destination[classDeclaration.name.name] = classDeclaration;
    }
  }
}

void _collectPublicConstructors(ClassDeclaration classDeclaration,
    Map<String, ConstructorDeclaration> destination) {
  for (ClassMember member in classDeclaration.members) {
    if (member is! ConstructorDeclaration) {
      continue;
    }
    final ConstructorDeclaration method = member;
    if (method?.name?.name == null) {
      destination['Unnamed Constructor'] = method;
      continue;
    }
    if (method.name.name.startsWith('_')) {
      continue;
    }
    destination[method.name.name] = method;
  }
}

void _collectPublicMethods(ClassDeclaration classDeclaration,
    Map<String, MethodDeclaration> destination) {
  for (ClassMember member in classDeclaration.members) {
    if (member is! MethodDeclaration) {
      continue;
    }
    final MethodDeclaration method = member;
    if (method.name.name.startsWith('_')) {
      continue;
    }
    destination[method.name.name] = method;
  }
}
