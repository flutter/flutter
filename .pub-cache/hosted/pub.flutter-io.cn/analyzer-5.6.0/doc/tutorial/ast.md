# The AST

An AST (abstract syntax tree) is a representation of the syntactic (or lexical)
structure of Dart code. The semantic structure of the code is modeled by the
[element][element] and [type][type] models.

## The Structure of an AST

An AST is composed of nodes (instances of `AstNode`) arranged as a tree. That
is, each node can have zero or more children, each of which is also a node, and
every node other than the root node has exactly one parent.

The root of the tree is typically a `CompilationUnit`. Compilation units have
children representing language constructs such as import directives and class
declarations. Class declarations have children representing, among other things,
each of the members of the class. The structure of the nodes is similar to, but
not identical to, the Dart language grammar.

As implied above, there are subclasses of `AstNode` for each production in the
grammar. The subclasses are defined in `package:analyzer/dart/ast/ast.dart`.

Every class of node provides access to its parent and children through getters.
For example, the class `BinaryExpression` defines the getters `parent`,
`leftOperand`, and `rightOperand`. It also provides getters for the tokens that
are a part of the construct (but not part of a child construct). In a binary
expression, for example, there is a getter to access the `operator`.

Every class of node and every token carries position information. You can ask
for the character `offset` of the beginning of the entity from the start of the
containing file, as well as the character `length`. For AST nodes, the offset
is the offset of this first token in the structure and the length includes the
end of the last token in the structure. Any whitespace before the first token or
after the last token is considered to be part of a parent node.

## The States of an AST

An AST can be in either of two states: unresolved or resolved. An unresolved
AST is one in which none of the nodes has any resolution information associated
with it. In an unresolved AST, the getters that access resolution information
will return `null`. A resolved AST is one in which all of the nodes have
resolution information associated with them.

So what do we mean by "resolution information"? Resolution is the process of
associating [element][element] and [type][type] information with an AST. These
topics are discussed in separate sections.

## Getting a Compilation Unit

If you have followed the steps in [Performing Analysis][analysis], and you want
to get the compilation unit for a file at a known `path`, then you can ask the
analysis session for an AST.

If you need an unresolved AST, then you can use the following method to access
the AST:

```dart
Future<void> processFile(AnalysisSession session, String path) async {
  var result = session.getParsedUnit(path);
  if (result is ParsedUnitResult) {
    CompilationUnit unit = result.unit;
  }
}
```

If you need a resolved AST, then you need to use the following asynchronous
method to access it:

```dart
Future<void> processFile(AnalysisSession session, String path) async {
  var result = await session.getResolvedUnit(path);
  if (result is ResolvedUnitResult) {
    CompilationUnit unit = result.unit;
  }
}
```

## Traversing the Structure

There are two ways to traverse the structure of an AST: getters and visitors.

### Getters

Every node defines getters for accessing the parent and the children of that
node. Those getters can be used to traverse the structure, and are often the
most efficient way of doing so. For example, if you wanted to write a utility to
print the names of all of the members of each class in a given compilation unit,
it might look something like this:

```dart
void printMembers(CompilationUnit unit) {
  for (CompilationUnitMember unitMember in unit.declarations) {
    if (unitMember is ClassDeclaration) {
      print(unitMember.name.lexeme);
      for (ClassMember classMember in unitMember.members) {
        if (classMember is MethodDeclaration) {
          print('  ${classMember.name.lexeme}');
        } else if (classMember is FieldDeclaration) {
          for (VariableDeclaration field in classMember.fields.variables) {
            print('  ${field.name.lexeme}');
          }
        } else if (classMember is ConstructorDeclaration) {
          if (classMember.name == null) {
            print('  ${unitMember.name.lexeme}');
          } else {
            print('  ${unitMember.name.lexeme}.${classMember.name!.lexeme}');
          }
        }
      }
    }
  }
}
```

### Visitors

Getters work well for cases like the above because compilation units cannot be
nested inside other compilation units, classes cannot be nested inside other
classes, etc. But when you're dealing with a structure that can be nested inside
similar structures (such as expressions, statements, and even functions), then
nested loops don't work very well. For those cases, the analyzer package
provides a visitor pattern.

There is a single visitor API, defined by the abstract class `AstVisitor`. It
defines a separate visit method for each class of AST node. For example, the
method `visitClassDeclaration` is used to visit a `ClassDeclaration`. If you
ask an AST node to accept a visitor, it will invoke the corresponding method on
the visitor interface.

If you want to define a visitor, you would create a subclass of one of the
concrete implementations of `AstVisitor`. The concrete subclasses are defined in
`package:analyzer/dart/ast/visitor.dart`. A couple of the most useful include
- `SimpleAstVisitor` which implements every visit method by doing nothing,
- `RecursiveAstVisitor` which will cause every node in a structure to be
  visited, and
- `GeneralizingAstVisitor` which makes it easy to visit general kinds of nodes,
  such as visiting any statement, or any expression.

As an example, let's assume you want to write some code to count the number of
`if` statements in a given structure. You need to visit every node, because you
can't know ahead of time where the `if` statements will be located, but there is
one specific class of node that you need to visit, so you don't need to handle
the general "groups" of nodes. The best approach for this example is to create a
subclass of `RecursiveAstVisitor`.

```dart
class IfCounter extends RecursiveAstVisitor<void> {
  int ifCount = 0;

  @override
  void visitIfStatement(IfStatement node) {
    ifCount++;
    super.visitIfStatement(node);
  }
}
```

## Differences From the Specification

Earlier we said that the structure of the tree is similar but not identical to
the grammar of the language. In addition to some minor differences, there is
one significant difference you should be aware of: the AST can express invalid
code. This is intentional. It allows the analyzer to recover better in the
presence of invalid code.

As an example, every function has a (possibly empty) list of parameters
associated with it. In Dart, parameters can either be positional or named, and
all of the positional parameters must be listed before the named parameters. But
in the AST, the parameters are allowed to occur in any order. The consequence of
this is that any code that traverses function parameters needs to be prepared
for them to occur in any order.

[analysis]: analysis.md
[element]: element.md
[type]: type.md
