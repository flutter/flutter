# The Type Model

The type model represents the type information defined by the language
specification.

## Kinds of Types

There are four classes of types, all of which are a subtype of the abstract
class `DartType`.

### Interface Types

### Function Types

### The Void Type

### The Type Dynamic

## Accessing Types

There are two ways to get an instance of `DartType`: from the [AST][ast] and
from the [element][element] model.

In a resolved AST, every expression has a non-`null` `staticType`.

Every element also has type information associated with it. Elements that define
a type, such as a `ClassElement`, can return the type that they define. Elements
that represent a function can return the `returnType` of the function as well as
the `functionType` of the function. Elements that represent a variable (which
includes fields and parameters) can return the explicitly or implicitly declared
type of the variable.

## Operations on Types

[ast]: ast.md
[element]: element.md
