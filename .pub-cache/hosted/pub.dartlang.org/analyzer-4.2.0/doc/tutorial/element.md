# The Element Model

The element model, together with the [type][type] model, describes the semantic
(as opposed to syntactic) structure of Dart code. The syntactic structure of the
code is modeled by the [AST][ast].

Generally speaking, an element represents something that is declared in the
code, such as a class, method, or variable. Elements can be explicitly declared,
such as the class defined by a class declaration, or implicitly declared, such
as the default constructor defined for classes that do not have any explicit
constructor declarations. Elements that are implicitly declared are referred to
as _synthetic_ elements.

There are a few elements that represent entities that are not declared. For
example, there is an element representing a compilation unit (`.dart` file) and
another representing a library.

## The Structure of the Element Model

Elements are organized in a tree structure in which the children of an element
are the elements that are logically (and often syntactically) part of the
declaration of the parent. For example, the elements representing the methods
and fields in a class are children of the element representing the class.

Every complete element structure is rooted by an instance of the class
`LibraryElement`. A library element represents a single Dart library. Every
library is defined by one or more compilation units (the library and all of its
parts). The compilation units are represented by the class
`CompilationUnitElement` and are children of the library that is defined by
them. Each compilation unit can contain zero or more top-level declarations,
such as classes, functions, and variables. Each of these is in turn
represented as an element that is a child of the compilation unit. Classes
contain methods and fields, methods can contain local variables, etc.

The element model does not contain everything in the code, only those things
that are declared by the code. For example, it does not include any
representation of the statements in a method body, but if one of those
statements declares a local variable then the local variable will be represented
by an element.

## Getting a Compilation Unit Element

If you have followed the steps in [Performing Analysis][analysis], and you want
to get the compilation unit element for a file at a known `path`, then you can
ask the analysis session for the compilation unit representing that file.

```dart
void analyzeSingleFile(AnalysisSession session, String path) async {
  var result = await session.getUnitElement(path);
  if (result is UnitElementResult) {
    CompilationUnitElement element = result.element;
  }
}
```

(If you also need the resolved AST for the file, you can ask the session to
`getResolvedAst`, and the returned result will have the library element for the
library containing the compilation unit.)

## Traversing the Structure

There are two ways to traverse the structure of an AST: getters and visitors.

### Getters

Every element defines getters for accessing the parent and the children of that
element. Those getters can be used to traverse the structure, and are often the
most efficient way of doing so. For example, if you wanted to write a utility to
print the names of all of the members of each class in a given compilation unit,
it might look something like this:

```dart
void printMembers(CompilationUnitElement unitElement) {
  for (ClassElement classElement in unitElement.classes) {
    print(classElement.name);
    for (ConstructorElement constructorElement in classElement.constructors) {
      if (!constructorElement.isSynthetic) {
        if (constructorElement.name == null) {
          print('  ${constructorElement.name}');
        } else {
          print('  ${classElement.name}.${constructorElement.name}');
        }
      }
    }
    for (FieldElement fieldElement in classElement.fields) {
      if (!fieldElement.isSynthetic) {
        print('  ${fieldElement.name}');
      }
    }
    for (PropertyAccessorElement accessorElement in classElement.accessors) {
      if (!accessorElement.isSynthetic) {
        print('  ${accessorElement.name}');
      }
    }
    for (MethodElement methodElement in classElement.methods) {
      if (!methodElement.isSynthetic) {
        print('  ${methodElement.name}');
      }
    }
  }
}
```

### Visitors

Getters work well for most uses, but there might be times when it is easier to
use a visitor pattern.

Getters work well for cases like the above because compilation units cannot be
nested inside other compilation units, classes cannot be nested inside other
classes, etc. But when you're dealing with a structure that can be nested inside
similar structures (such as functions), then nested loops don't work as well.
For those cases, the analyzer package provides a visitor pattern.

There is a single visitor API, defined by the abstract class `ElementVisitor`.
It defines a separate visit method for each class of element. For example, the
method `visitClassElement` is used to visit a `ClassElement`. If you ask an
element to accept a visitor, it will invoke the corresponding method on the
visitor interface.

If you want to define a visitor, you'll probably want to subclass one of the
concrete implementations of `ElementVisitor`. The concrete subclasses are
defined in `package:analyzer/dart/element/visitor.dart`. A couple of the most
useful include
- `SimpleElementVisitor` which implements every visit method by doing nothing,
- `RecursiveElementVisitor` which will cause every element in a structure to be
  visited, and
- `GeneralizingElementVisitor` which makes it easy to visit kinds of nodes, such
  as visiting any executable element (method, function, accessor, or
  constructor).

As an example, let's assume you want to write some code to compute the largest
number of parameters defined for any function or method in a given structure.
You need to visit every element because functions can be nested inside
functions. But because methods and functions are represented by different
classes of elements, it would be useful to use a visitor that will generalize
both to allow you to just visit executable elements (those that have
parameters). Hence, you'd want to create a subclass of
`GeneralizingElementVisitor`.

```dart
class ParameterCounter extends GeneralizingElementVisitor<void> {
  int maxParameterCount = 0;

  @override
  void visitExecutableElement(ExecutableElement element) {
    maxParameterCount = math.max(maxParameterCount, element.parameters.length);
    super.visitExecutableElement(element);
  }
}
```

[analysis]: analysis.md
[ast]: ast.md
[type]: type.md
